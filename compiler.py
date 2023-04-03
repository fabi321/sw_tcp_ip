import os
from subprocess import Popen, PIPE
from dotenv import load_dotenv
from os import getenv
import re
from typing import Optional
import sys
import shutil
from pathlib import Path
from datetime import datetime, timedelta
from itertools import chain


REQUIRE_REGEX: re.Pattern = re.compile(r'''require\(["']([a-zA-Z0-9_/]+)["']\)''')
TEMPLATE_REGEX: re.Pattern = re.compile(r'\{\{([a-zA-Z0-9_/]+)\}\}')
SCRIPT_REGEX: re.Pattern = re.compile(r'script="([^"]*)"')
MC_REGEX: re.Pattern = re.compile(r'<microprocessor_definition name="(.*?)".*?</microprocessor_definition>')


class Snippet:
	def __init__(self, content: str):
		self.content: str = content
		self.dependencies: set = set(REQUIRE_REGEX.findall(self.content))


def minify(text: str) -> str:
	process: Popen = Popen(['lua5.4', 'minify.lua', 'minify', '-'], stdin=PIPE, stderr=PIPE, stdout=PIPE)
	result = process.communicate(text.encode())
	if result[1]:
		print(result[1].decode())
		raise ValueError('Broken code')
	return result[0].decode()


def escape(text: str) -> str:
	return text\
		.replace('&', '&amp;')\
		.replace('"', '&quot;')\
		.replace("'", '&apos;')


def get_mro(snippets: dict[str, Snippet], name: str) -> list[str]:
	visited = set()
	mro = []

	def dfs(current_name):
		visited.add(current_name)
		snippet = snippets[current_name]

		for dep_name in snippet.dependencies:
			if dep_name not in visited:
				dfs(dep_name)

		mro.append(current_name)

	dfs(name)
	return mro


def merge_snippets(snippets: dict[str, Snippet], name: str) -> str:
	# compute MRO
	mro = get_mro(snippets, name)

	# merge snippets in MRO order
	merged_content = ""
	merged_deps = set()
	for current_name in mro:
		snippet = snippets[current_name]
		for dep_name in snippet.dependencies:
			replace_with: str = ''
			if dep_name not in merged_deps:
				replace_with = snippets[dep_name].content
				merged_deps.add(dep_name)
			merged_content = re.sub(f'require\\(["\']{dep_name}["\']\\)', replace_with, merged_content)
		merged_content += snippet.content

	# replace remaining dependencies with empty string
	for dep_name in merged_deps:
		merged_content = re.sub(f'require\\(["\']{dep_name}["\']\\)', '', merged_content)

	return merged_content


def compile_file(snippets: dict[str, Snippet], name: str) -> str:
	text: str = merge_snippets(snippets, name)
	text = minify(text)
	assert len(text) <= 4096, f'script {name} is too long'
	text = escape(text)
	return text


def compile() -> dict[str, str]:
	snippets: dict[str, Snippet] = {}
	for file in Path('src').glob("**/*.lua"):
		if not file.is_file():
			# Ignores directories for now
			continue
		with file.open() as f:
			snippets['/'.join(chain(file.parts[1:-1], (file.stem,)))] = Snippet(f.read())
	return {name: compile_file(snippets, name) for name in snippets.keys()}


def process_microcontroller(mc_hull: Path, compiled: dict[str, str]):
	with mc_hull.open() as f:
		hull: str = f.read()
	while match := TEMPLATE_REGEX.search(hull):
		required_snippet: Optional[str] = compiled.get(match.group(1))
		if not required_snippet:
			raise ModuleNotFoundError(f'Could not find snippet {match.group(1)}')
		hull = hull[:match.start()] + required_snippet + hull[match.end():]
	with (Path('generated_microcontrollers') / f'{mc_hull.stem}.xml').open('w') as f:
		f.write(hull)


def install():
	copy_dir: Path
	if sys.platform == 'win32':
		copy_dir = Path(os.path.expandvars('%APPDATA%'))
	elif sys.platform == 'linux':
		copy_dir = Path('~/.steam/steam/steamapps/compatdata/573090/pfx/drive_c/users/steamuser/AppData/Roaming').expanduser()
	else:
		raise NotImplementedError('Apple is not supported atm')
	copy_dir = copy_dir / 'Stormworks' / 'data' / 'microprocessors'
	newest = datetime.now()
	for mc in sorted(Path('generated_microcontrollers').glob('*.xml')):
		shutil.copy(mc, copy_dir)
		dest_file: Path = copy_dir / mc.name
		assert dest_file.is_file()
		os.utime(dest_file, (newest.timestamp(), newest.timestamp()))
		newest -= timedelta(minutes=1)
	for thumb in Path('microcontroller_thumbnails').glob('*.png'):
		shutil.copy(thumb, copy_dir)


def install_in_file(file: Path):
	mcs: dict[str, str] = {}
	for mc in Path('generated_microcontrollers').glob('*.xml'):
		with mc.open() as f:
			file_content = f.read()
		name = re.search(r'<microprocessor name="([^"]*)"', file_content).group(1)
		file_content = re.sub(r'<(/?)microprocessor([^>]*)>', r'<\1microprocessor_definition\2>', file_content)
		file_content = file_content.replace('<?xml version="1.0" encoding="UTF-8"?>', '')
		file_content = file_content.replace('\n', '').replace('\t', '')
		mcs[name] = file_content
	with file.open() as f:
		vehicle = f.read()
	start: int = 0
	while match := MC_REGEX.search(vehicle, start):
		start = match.start() + 1
		name = match.group(1)
		if name in mcs:
			vehicle = vehicle[:match.start()] + mcs[name] + vehicle[match.end():]
	with file.open('w') as f:
		f.write(vehicle)



def main():
	load_dotenv()
	do_install: bool = len(sys.argv) >= 2 and sys.argv[1] == 'install'
	compiled: dict[str, str] = compile()
	compiled['trusted_mode'] = (getenv('TRUSTED_MODE') or 'true').lower()
	assert compiled['trusted_mode'] in ('true', 'false'), 'Only true or false are possible settings for TRUSTED_MODE'
	generated_microcontrollers_dir: Path = Path('generated_microcontrollers')
	if not generated_microcontrollers_dir.is_dir():
		generated_microcontrollers_dir.mkdir()
	for mc_hull in Path('microcontroller_hulls').iterdir():
		if not mc_hull.is_file():
			continue
		process_microcontroller(mc_hull, compiled)
	if do_install:
		install()
		if len(sys.argv) >= 3:
			install_in_file(Path(sys.argv[2]).expanduser().resolve())


if __name__ == "__main__":
	main()

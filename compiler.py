#!/usr/bin/env python

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
import argparse
import logging
from sw_mc_lib import parse, format, XMLParserElement


REQUIRE_REGEX: re.Pattern = re.compile(r'''require\(["']([a-zA-Z0-9_/-]+)["']\)''')
TEMPLATE_REGEX: re.Pattern = re.compile(r'\{\{([a-zA-Z0-9_/-]+)\}\}')
NAME_REGEX: re.Pattern = re.compile(r'([a-zA-Z0-9_-]+)')

FIELD_REPLACEMENTS: dict[str, str] = {
	'src_addr': 'a',
	'dest_addr': 'b',
	'src_port': 'c',
	'dest_port': 'd',
	'seq_nmb': 'e',
	'ack_nmb': 'f',
	'proto': 'g',
	'ttl': 'h',
	'data': 'i',
	'retry_time': 'j',
	'retry_count': 'k',
	'packet': 'l',
	'destination': 'm'
}


class Snippet:
	def __init__(self, content: str):
		self.content: str = content
		self.dependencies: set = set(REQUIRE_REGEX.findall(self.content))


def minify(text: str) -> str:
	def replace(match: re.Match) -> str:
		return FIELD_REPLACEMENTS.get(match.group(1), match.group(1))

	text = NAME_REGEX.sub(replace, text)
	
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

	logging.debug(f'mro for snippet {name}: {mro}')

	# replace remaining dependencies with empty string
	for dep_name in merged_deps:
		merged_content = re.sub(f'require\\(["\']{dep_name}["\']\\)', '', merged_content)

	return merged_content


def compile_file(snippets: dict[str, Snippet], name: str) -> str:
	logging.debug(f'merging snippets of {name}')
	text: str = merge_snippets(snippets, name)
	logging.debug(f'minifying {name}')
	text = minify(text)
	if len(text) > 4096:
		logging.warning(f'script {name} is too long')
	text = escape(text)
	return text


def path_to_short_name(path: Path) -> str:
	return '/'.join(chain(path.parts[1:-1], (path.stem,)))


def compile_lua_files() -> dict[str, str]:
	snippets: dict[str, Snippet] = {}
	for file in Path('src').glob("**/*.lua"):
		if not file.is_file():
			# Ignores directories for now
			continue
		with file.open() as f:
			logging.debug(f'reading snippet {file}')
			snippets[path_to_short_name(file)] = Snippet(f.read())
	return {name: compile_file(snippets, name) for name in snippets.keys()}


def process_microcontroller(mc_hull: Path, compiled: dict[str, str]):
	logging.debug(f'processing {mc_hull}')
	with mc_hull.open() as f:
		hull: str = f.read()
	while match := TEMPLATE_REGEX.search(hull):
		logging.debug(f'processing match {match.group()}')
		required_snippet: Optional[str] = compiled.get(match.group(1))
		if not required_snippet:
			raise ModuleNotFoundError(f'Could not find snippet {match.group(1)}')
		hull = hull[:match.start()] + required_snippet + hull[match.end():]
	logging.debug(f'writing {mc_hull}')
	with (Path('generated_microcontrollers') / f'{mc_hull.stem}.xml').open('w') as f:
		f.write(hull)


def proces_properties() -> dict[str, str]:
	properties: dict[str, str] = {}
	for file in Path('properties').glob('**/*.property'):
		with file.open() as f:
			logging.debug(f'reading property {file}')
			content: str = f.read()
			if len(content) > 4096:
				logging.warning(f'property {file.stem} is too long')
			if content.find('\n') != -1:
				logging.warning(f'removing newlines in property {file.stem}')
			if not file.stem.startswith('_'):
				logging.warning(f"property name {file.stem} doesn't start with a _. It might be ignored by the update function")
			properties[path_to_short_name(file)] = content.replace('\n', '')
	return properties


def install_globally():
	logging.info('installing microcontrollers to game directory')
	copy_dir: Path
	if sys.platform == 'win32':
		copy_dir = Path(os.path.expandvars('%APPDATA%'))
	elif sys.platform == 'linux':
		copy_dir = Path('~/.steam/steam/steamapps/compatdata/573090/pfx/drive_c/users/steamuser/AppData/Roaming').expanduser()
	else:
		raise NotImplementedError('Apple is not supported atm')
	logging.debug(f'using base_directory {copy_dir}')
	copy_dir = copy_dir / 'Stormworks' / 'data' / 'microprocessors'
	logging.debug(f'using microprocessor directory {copy_dir}')
	newest = datetime.now()
	for mc in sorted(Path('generated_microcontrollers').glob('*.xml')):
		logging.debug(f'copying {mc}')
		shutil.copy(mc, copy_dir)
		dest_file: Path = copy_dir / mc.name
		assert dest_file.is_file()
		os.utime(dest_file, (newest.timestamp(), newest.timestamp()))
		newest -= timedelta(minutes=1)
	for thumb in Path('microcontroller_thumbnails').glob('*.png'):
		logging.debug(f'copying {thumb}')
		shutil.copy(thumb, copy_dir)


def install_in_file(file: Path):
	logging.info(f'installing into file {file}')
	mcs: dict[str, XMLParserElement] = {}
	for mc in Path('generated_microcontrollers').glob('*.xml'):
		logging.debug(f'reading microcontroller {mc}')
		with mc.open() as f:
			file_content = f.read()
		file_xml: XMLParserElement = parse(file_content)
		file_xml.tag = 'microprocessor_definition'
		mcs[file_xml.attributes.get('name', '')] = file_xml
	logging.debug('reading vehicle file')
	with file.open() as f:
		vehicle = f.read()
	vehicle_xml: XMLParserElement = parse(vehicle)
	bodies: XMLParserElement = vehicle_xml.children[1]
	assert bodies.tag == 'bodies'
	for body in bodies.children:
		for component in body.children:
			if component.attributes.get('d') == 'microprocessor':
				mc_def = component.children[0].children[0]
				assert mc_def.tag == 'microprocessor_definition'
				name: str = mc_def.attributes.get('name', '')
				logging.debug(f'found microcontroller {name}')
				if name in mcs:
					logging.debug('replacing microcontroller with updated variant')
					mc_def.children[0].children[0] = mcs[name]
	logging.debug('writing vehicle file')
	with file.open('w') as f:
		f.write(format(vehicle_xml, None, True))


def compile_all() -> dict[str, str]:
	logging.info('compiling lua files')
	compiled: dict[str, str] = compile_lua_files()
	compiled['trusted_mode'] = (getenv('TRUSTED_MODE') or 'true').lower()
	assert compiled['trusted_mode'] in ('true', 'false'), 'Only true or false are possible settings for TRUSTED_MODE'
	logging.info('processing properties')
	compiled.update(proces_properties())
	return compiled


def install_locally(compiled: dict[str, str]):
	logging.info(f'writing generated microcontrollers')
	generated_microcontrollers_dir: Path = Path('generated_microcontrollers')
	if not generated_microcontrollers_dir.is_dir():
		logging.debug('creating generated_microcontrollers directory')
		generated_microcontrollers_dir.mkdir()
	for mc_hull in Path('microcontroller_hulls').iterdir():
		if not mc_hull.is_file():
			continue
		process_microcontroller(mc_hull, compiled)


def main():
	parser: argparse.ArgumentParser = argparse.ArgumentParser(
		description='Compiles many artifacts of different kinds into stormworks microcontrollers'
	)
	parser.add_argument(
		'-d', '--debug',
		help="Print lots of debugging statements",
		action="store_const", dest="loglevel", const=logging.DEBUG,
		default=logging.WARNING,
	)
	parser.add_argument(
		'-v', '--verbose',
		help="Be verbose",
		action="store_const", dest="loglevel", const=logging.INFO,
	)
	subparsers = parser.add_subparsers(dest='command', required=True)
	build_parser: argparse.ArgumentParser = subparsers.add_parser('build', help='build microcontrollers')
	install_parser: argparse.ArgumentParser = subparsers.add_parser('install', help='build and install microcontrollers')
	install_parser.add_argument('target', nargs='?', type=Path, help='update all microcontrollers in a saved vehicle')
	args = parser.parse_args()
	logging.basicConfig(
		format='%(asctime)s|%(levelname)s| %(message)s', datefmt='%Y-%m-%dT%H:%M:%S%z',
		level=args.loglevel
	)
	load_dotenv()
	if args.command in ('compile', 'install'):
		compiled: dict[str, str] = compile_all()
		install_locally(compiled)
	if args.command == 'install':
		install_globally()
		if args.target:
			install_in_file(args.target.expanduser().resolve())


if __name__ == "__main__":
	main()

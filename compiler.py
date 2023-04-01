import json
import os
from subprocess import Popen, PIPE
from dotenv import load_dotenv
from os import getenv
import re
from typing import Optional
import sys
import shutil
from pathlib import Path

REQUIRE_REGEX: re.Pattern = re.compile(r'''require\(["']([a-zA-Z0-9_/]+)["']\)''')
TEMPLATE_REGEX: re.Pattern = re.compile(r'\{\{([a-zA-Z0-9_/]+)\}\}')
LUA_FILES: list[str] = [
	'packeting.lua', 'router_arp.lua', 'packet_queue.lua', 'router.lua', 'xorshift.lua',
	'wifi_controller.lua', 'dhcp_client.lua', 'arp_server.lua', 'server.lua', 'packet_sniffer.lua'
]
COMPILED: list[str] = ['router', 'server', 'packet_sniffer']
MICROCONTROLLERS: list[str] = ['router', 'server', 'packet_sniffer']


class Lib:
	def __init__(self):
		self.snippets: dict[str, str] = {}

	def add_and_resolve_snippet(self, name: str, snippet: str):
		while match := REQUIRE_REGEX.search(snippet):
			required_snippet: Optional[str] = self.snippets.get(match.group(1))
			if not required_snippet:
				raise ModuleNotFoundError(f'Could not find snippet {match.group(1)}')
			snippet = snippet[:match.start()] + required_snippet + snippet[match.end() + 1:]
		self.snippets[name] = snippet

	def add_from_file(self, filename: str):
		with open(Path('src') / filename) as f:
			self.add_and_resolve_snippet(filename.split('.')[0], f.read())


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


def compile_file(text: str) -> str:
	text = minify(text)
	assert len(text) <= 4096, 'script is too long'
	text = escape(text)
	return text


def compile() -> dict[str, str]:
	lib: Lib = Lib()
	for file in LUA_FILES:
		lib.add_from_file(file)
	return {name: compile_file(lib.snippets[name]) for name in COMPILED}


def process_microcontroller(name: str, compiled: dict[str, str]):
	with (Path('microcontroller_hulls') / f'{name}.xml').open() as f:
		hull: str = f.read()
	while match := TEMPLATE_REGEX.search(hull):
		required_snippet: Optional[str] = compiled.get(match.group(1))
		if not required_snippet:
			raise ModuleNotFoundError(f'Could not find snippet {match.group(1)}')
		hull = hull[:match.start()] + required_snippet + hull[match.end():]
	with (Path('generated_microcontrollers') / f'{name}.xml').open('w') as f:
		f.write(hull)


def install(name: str):
	copy_dir: Path
	if sys.platform == 'win32':
		copy_dir = Path(os.path.expandvars('%APPDATA%'))
	elif sys.platform == 'linux':
		copy_dir = Path('~/.steam/steam/steamapps/compatdata/573090/pfx/drive_c/users/steamuser/AppData/Roaming').expanduser()
	else:
		raise NotImplementedError('Apple is not supported atm')
	copy_dir = copy_dir / 'Stormworks' / 'data' / 'microprocessors'
	shutil.copy(Path('generated_microcontrollers') / f'{name}.xml', copy_dir)
	shutil.copy(Path('microcontroller_thumbnails') / f'{name}.png', copy_dir)


def main():
	load_dotenv()
	do_install: bool = len(sys.argv) >= 2 and sys.argv[1] == 'install'
	compiled: dict[str, str] = compile()
	compiled['trusted_mode'] = (getenv('TRUSTED_MODE') or 'true').lower()
	assert compiled['trusted_mode'] in ('true', 'false'), 'Only true or false are possible settings for TRUSTED_MODE'
	generated_microcontrollers_dir: Path = Path('generated_microcontrollers')
	if not generated_microcontrollers_dir.is_dir():
		generated_microcontrollers_dir.mkdir()
	for mc_name in MICROCONTROLLERS:
		process_microcontroller(mc_name, compiled)
		if do_install:
			install(mc_name)


if __name__ == "__main__":
	main()

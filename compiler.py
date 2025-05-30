#!/usr/bin/env python

import os
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

from tumfl import resolve_recursive, minify, format as format_ast
from tumfl.formatter import MinifiedStyle
from tumfl.config import parse_config, Config


REQUIRE_REGEX: re.Pattern = re.compile(r"""require\(["']([a-zA-Z0-9_/-]+)["']\)""")
TEMPLATE_REGEX: re.Pattern = re.compile(r"\{\{([a-zA-Z0-9_/-]+)\}\}")
NAME_REGEX: re.Pattern = re.compile(r"([a-zA-Z][a-zA-Z0-9_]*)")

FIELD_REPLACEMENTS: dict[str, str] = {
    "src_addr": "a",
    "dest_addr": "b",
    "src_port": "c",
    "dest_port": "d",
    "seq_nmb": "e",
    "ack_nmb": "f",
    "proto": "g",
    "ttl": "h",
    "data": "i",
    "retry_time": "j",
    "retry_count": "k",
    "packet": "l",
    "destination": "m",
}


def escape(text: str) -> str:
    return text.replace("&", "&amp;").replace('"', "&quot;").replace("'", "&apos;")


def write_ast(ast, dir: str, name: Path):
    target: Path = Path(dir) / name
    target.parent.mkdir(exist_ok=True, parents=True)
    with target.open("w") as f:
        f.write(format_ast(ast))


def compile_file(name: Path, config: Config) -> str:
    logging.debug(f"merging snippets of {name}")
    ast = resolve_recursive(name, [name.parent, Path("src")], config=config)
    write_ast(ast, "generated_ast", name)

    logging.debug(f"minifying {name}")
    minify(ast)
    write_ast(ast, "minified_ast", name)
    MinifiedStyle.STATEMENT_SEPARATOR = "\n"
    text: str = format_ast(ast, MinifiedStyle)

    def replace(match: re.Match) -> str:
        return FIELD_REPLACEMENTS.get(match.group(1), match.group(1))

    text = NAME_REGEX.sub(replace, text)

    if len(text) > 4096:
        logging.warning(f"script {name} is too long")

    text = escape(text)
    return text


def path_to_short_name(path: Path) -> str:
    return "/".join(chain(path.parts[1:-1], (path.stem,)))


def compile_lua_files(config: Path) -> dict[str, str]:
    files: list[Path] = list(Path("src").glob("**/*.lua"))
    compiled_config = parse_config(config)
    return {
        path_to_short_name(name): compile_file(name, compiled_config) for name in files
    }


def process_microcontroller(mc_hull: Path, compiled: dict[str, str]):
    logging.debug(f"processing {mc_hull}")
    with mc_hull.open() as f:
        hull: str = f.read()
    while match := TEMPLATE_REGEX.search(hull):
        logging.debug(f"processing match {match.group()}")
        required_snippet: Optional[str] = compiled.get(match.group(1))
        if not required_snippet:
            raise ModuleNotFoundError(f"Could not find snippet {match.group(1)}")
        hull = hull[: match.start()] + required_snippet + hull[match.end() :]
    logging.debug(f"writing {mc_hull}")
    with (Path("generated_microcontrollers") / f"{mc_hull.stem}.xml").open("w") as f:
        f.write(hull)


def proces_properties() -> dict[str, str]:
    properties: dict[str, str] = {}
    for file in Path("properties").glob("**/*.property"):
        with file.open() as f:
            logging.debug(f"reading property {file}")
            content: str = f.read()
            if len(content) > 4096:
                logging.warning(f"property {file.stem} is too long")
            if content.find("\n") != -1:
                logging.warning(f"removing newlines in property {file.stem}")
            if not file.stem.startswith("_"):
                logging.warning(
                    f"property name {file.stem} doesn't start with a _. It might be ignored by the update function"
                )
            properties[path_to_short_name(file)] = content.replace("\n", "")
    return properties


def install_globally():
    logging.info("installing microcontrollers to game directory")
    copy_dir: Path
    if sys.platform == "win32":
        copy_dir = Path(os.path.expandvars("%APPDATA%"))
    elif sys.platform == "linux":
        copy_dir = Path(
            "~/.steam/steam/steamapps/compatdata/573090/pfx/drive_c/users/steamuser/AppData/Roaming"
        ).expanduser()
    else:
        raise NotImplementedError("Apple is not supported atm")
    logging.debug(f"using base_directory {copy_dir}")
    copy_dir = copy_dir / "Stormworks" / "data" / "microprocessors"
    logging.debug(f"using microprocessor directory {copy_dir}")
    newest = datetime.now()
    for mc in sorted(Path("generated_microcontrollers").glob("*.xml")):
        logging.debug(f"copying {mc}")
        shutil.copy(mc, copy_dir)
        dest_file: Path = copy_dir / mc.name
        assert dest_file.is_file()
        os.utime(dest_file, (newest.timestamp(), newest.timestamp()))
        newest -= timedelta(minutes=1)
    for thumb in Path("microcontroller_thumbnails").glob("*.png"):
        logging.debug(f"copying {thumb}")
        shutil.copy(thumb, copy_dir)


def install_in_file(file: Path):
    logging.info(f"installing into file {file}")
    mcs: dict[str, XMLParserElement] = {}
    for mc in Path("generated_microcontrollers").glob("*.xml"):
        logging.debug(f"reading microcontroller {mc}")
        with mc.open() as f:
            file_content = f.read()
        file_xml: XMLParserElement = parse(file_content)
        file_xml.tag = "microprocessor_definition"
        mcs[file_xml.attributes.get("name", "")] = file_xml
    logging.debug("reading vehicle file")
    with file.open() as f:
        vehicle = f.read()
    vehicle_xml: XMLParserElement = parse(vehicle)
    bodies: XMLParserElement = vehicle_xml.children[1]
    assert bodies.tag == "bodies"
    for body in bodies.children:
        assert body.tag == "body"
        for components in body.children:
            assert components.tag == "components"
            for component in components.children:
                if component.attributes.get("d") == "microprocessor":
                    mc_def = component.children[0].children[0]
                    assert mc_def.tag == "microprocessor_definition"
                    name: str = mc_def.attributes.get("name", "")
                    logging.debug(f"found microcontroller {name}")
                    if name in mcs:
                        logging.debug("replacing microcontroller with updated variant")
                        component.children[0].children[0] = mcs[name]
    logging.debug("writing vehicle file")
    with file.open("w") as f:
        f.write(format(vehicle_xml, None, True))


def compile_all(debug: bool) -> dict[str, str]:
    config_file: Path = (
        Path("configs/debug.lua") if debug else Path("configs/default.lua")
    )
    logging.info("compiling lua files")
    compiled: dict[str, str] = compile_lua_files(config_file)
    compiled["trusted_mode"] = (getenv("TRUSTED_MODE") or "true").lower()
    assert compiled["trusted_mode"] in (
        "true",
        "false",
    ), "Only true or false are possible settings for TRUSTED_MODE"
    logging.info("processing properties")
    compiled.update(proces_properties())
    return compiled


def install_locally(compiled: dict[str, str]):
    logging.info(f"writing generated microcontrollers")
    generated_microcontrollers_dir: Path = Path("generated_microcontrollers")
    if not generated_microcontrollers_dir.is_dir():
        logging.debug("creating generated_microcontrollers directory")
        generated_microcontrollers_dir.mkdir()
    for mc_hull in Path("microcontroller_hulls").iterdir():
        if not mc_hull.is_file():
            continue
        process_microcontroller(mc_hull, compiled)


def main():
    parser: argparse.ArgumentParser = argparse.ArgumentParser(
        description="Compiles many artifacts of different kinds into stormworks microcontrollers"
    )
    parser.add_argument("-d", "--debug", help="Do a debug build", action="store_true")
    parser.add_argument("-v", "--verbose", action="count", default=1)
    subparsers = parser.add_subparsers(dest="command", required=True)
    subparsers.add_parser("build", help="build microcontrollers")
    install_parser: argparse.ArgumentParser = subparsers.add_parser(
        "install", help="build and install microcontrollers"
    )
    install_parser.add_argument(
        "target",
        nargs="?",
        type=Path,
        help="update all microcontrollers in a saved vehicle",
    )
    args = parser.parse_args()
    args.verbose = 40 - (10 * args.verbose) if args.verbose > 0 else 0
    logging.basicConfig(
        format="%(asctime)s|%(levelname)s| %(message)s",
        datefmt="%Y-%m-%dT%H:%M:%S%z",
        level=args.verbose,
    )
    load_dotenv()
    if args.command in ("build", "install"):
        compiled: dict[str, str] = compile_all(args.debug)
        install_locally(compiled)
    if args.command == "install":
        install_globally()
        if args.target:
            install_in_file(args.target.expanduser().resolve())


if __name__ == "__main__":
    main()

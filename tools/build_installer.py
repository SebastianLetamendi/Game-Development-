#!/usr/bin/env python3
"""Generates dist/InstallIntoStudio.luau from default.project.json and src/.

The generated file lets you put the game's scripts into a Roblox place without
installing Rojo: paste it into Studio's Command Bar, or have Claude Code run it
through the Roblox Studio MCP connection. It reads the same project file Rojo
uses, so both routes always produce the same scripts in the same places.

Usage:
    python3 tools/build_installer.py          regenerate the installer
    python3 tools/build_installer.py --check  exit 1 if the installer is stale
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PROJECT_FILE = ROOT / "default.project.json"
OUTPUT_FILE = ROOT / "dist" / "InstallIntoStudio.luau"

# Rojo's file-name conventions, most specific first.
SCRIPT_SUFFIXES = (
    (".server.luau", "Script"),
    (".client.luau", "LocalScript"),
    (".luau", "ModuleScript"),
)


def script_class(filename: str) -> tuple[str, str] | None:
    """Returns (instance name, class name) for a script file, or None."""
    for suffix, class_name in SCRIPT_SUFFIXES:
        if filename.endswith(suffix):
            return filename[: -len(suffix)], class_name
    return None


def find_mounts(tree: dict, path: tuple[str, ...] = ()) -> list[tuple[tuple[str, ...], str]]:
    """Lists (instance path, source directory) for every "$path" in the tree."""
    mounts = []
    for key, node in tree.items():
        if key.startswith("$") or not isinstance(node, dict):
            continue
        here = path + (key,)
        if "$path" in node:
            mounts.append((here, node["$path"]))
        mounts.extend(find_mounts(node, here))
    return mounts


def collect_scripts(directory: Path) -> list[tuple[str, str, str]]:
    """Returns (name, class, source) for each script file, sorted by name.

    Only a flat folder of scripts is supported, which is all this project
    uses. Anything else stops the build rather than being silently skipped.
    """
    scripts = []
    for entry in sorted(directory.iterdir()):
        if entry.name.startswith("."):
            continue
        parsed = script_class(entry.name) if entry.is_file() else None
        if parsed is None:
            raise SystemExit(f"Unsupported entry for the installer: {entry.relative_to(ROOT)}")
        name, class_name = parsed
        if name == "init":
            raise SystemExit(f"init scripts are not supported by the installer: {entry.relative_to(ROOT)}")
        source = entry.read_text(encoding="utf-8")
        scripts.append((name, class_name, source))
    names = [name for name, _, _ in scripts]
    if len(names) != len(set(names)):
        raise SystemExit(f"Two scripts in {directory.relative_to(ROOT)} would get the same name")
    return scripts


def long_string(text: str) -> str:
    """Wraps text in a Luau long string that reproduces it exactly.

    The level (number of '=' signs) is the smallest one whose closing bracket
    does not appear in the text, including where the text's own last
    characters would join the closing bracket (text ending in "]" or "]=").
    A newline is placed straight after the opening bracket because Luau
    discards a newline in that position, which keeps a leading newline in the
    text intact.
    """
    level = 0
    while ("]" + "=" * level + "]") in text + "]":
        level += 1
    equals = "=" * level
    return f"[{equals}[\n{text}]{equals}]"


def luau_string(text: str) -> str:
    """A short double-quoted Luau string literal for names and paths.

    ensure_ascii=False keeps letters such as "u" with an accent as UTF-8:
    JSON's \\uXXXX escapes are not valid in Luau.
    """
    return json.dumps(text, ensure_ascii=False)


def render(project: dict) -> str:
    mounts = find_mounts(project["tree"])
    if not mounts:
        raise SystemExit("default.project.json has no $path entries")

    folder_lines = []
    group_blocks = []
    total_scripts = 0
    for instance_path, directory in mounts:
        *parent_path, folder_name = instance_path
        scripts = collect_scripts(ROOT / directory)
        total_scripts += len(scripts)
        folder_lines.append(f"--   {'.'.join(instance_path)}   (from {directory}/)")

        script_entries = []
        for name, class_name, source in scripts:
            script_entries.append(
                "\t\t\t{\n"
                f"\t\t\t\tname = {luau_string(name)},\n"
                f"\t\t\t\tclass = {luau_string(class_name)},\n"
                f"\t\t\t\tsource = {long_string(source)},\n"
                "\t\t\t},"
            )
        parent_list = ", ".join(luau_string(part) for part in parent_path)
        group_blocks.append(
            "\t{\n"
            f"\t\tparent = {{ {parent_list} }},\n"
            f"\t\tfolder = {luau_string(folder_name)},\n"
            "\t\tscripts = {\n" + "\n".join(script_entries) + "\n\t\t},\n"
            "\t},"
        )

    header = f"""-- Campus Delivery Dash: Roblox Studio installer
--
-- GENERATED by tools/build_installer.py from default.project.json and src/.
-- Do not edit this file. Edit the files in src/, then run tools/check.sh --fix
-- (or python3 tools/build_installer.py) to regenerate it.
--
-- How to use:
--   1. Open your place in Roblox Studio. Do not press Play.
--   2. Save a backup copy first (File > Save to File As...).
--   3. Open View > Command Bar, paste this whole file into it, press Enter.
--   4. Check the Output window for the "installed" message, then press Play.
--
-- It replaces these folders and nothing else ({total_scripts} scripts in total):
{chr(10).join(folder_lines)}
-- Any edits you made to scripts inside them in Studio are replaced too.
-- Edit > Undo reverses the whole install in one step.
"""

    body = """
local RunService = game:GetService("RunService")
if RunService:IsRunning() then
	error("Stop the play test first: the installer only works in Edit mode.")
end

local GROUPS = {
""" + "\n".join(group_blocks) + """
}

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local recording = ChangeHistoryService:TryBeginRecording("Install Campus Delivery Dash")

local installed = 0
for _, group in GROUPS do
	local parent = game:GetService(group.parent[1])
	for index = 2, #group.parent do
		local child = parent:FindFirstChild(group.parent[index])
		if child == nil then
			error("Could not find " .. table.concat(group.parent, ".", 1, index))
		end
		parent = child
	end

	local old = parent:FindFirstChild(group.folder)
	if old then
		-- Unparent rather than Destroy so Edit > Undo can bring it back.
		old.Parent = nil
	end

	local folder = Instance.new("Folder")
	folder.Name = group.folder
	for _, info in group.scripts do
		local instance = Instance.new(info.class)
		instance.Name = info.name
		instance.Source = info.source
		instance.Parent = folder
		installed += 1
	end
	folder.Parent = parent
end

if recording then
	ChangeHistoryService:FinishRecording(recording, Enum.FinishRecordingOperation.Commit)
end

print(("Campus Delivery Dash installed: %d scripts. Save the place, then press Play."):format(installed))
"""
    return header + body


def main(argv: list[str]) -> int:
    check_only = "--check" in argv[1:]
    project = json.loads(PROJECT_FILE.read_text(encoding="utf-8"))
    generated = render(project)

    if check_only:
        current = OUTPUT_FILE.read_text(encoding="utf-8") if OUTPUT_FILE.exists() else None
        if current != generated:
            print(
                f"{OUTPUT_FILE.relative_to(ROOT)} is out of date. "
                "Run: python3 tools/build_installer.py (or tools/check.sh --fix)"
            )
            return 1
        print(f"{OUTPUT_FILE.relative_to(ROOT)} is up to date.")
        return 0

    OUTPUT_FILE.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT_FILE.write_text(generated, encoding="utf-8")
    print(f"Wrote {OUTPUT_FILE.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))

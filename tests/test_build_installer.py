"""Tests for tools/build_installer.py.

The most important test runs the generated installer with the real Luau
interpreter against a small fake of Roblox's API, then checks that it created
exactly the scripts in src/, in the right places, with identical source text.

Run with: python3 -m unittest discover -s tests -p "test_*.py"
(tools/check.sh runs this for you.)
"""

from __future__ import annotations

import json
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

import build_installer  # noqa: E402  (needs the path set up above)

# A minimal stand-in for the parts of the Roblox API the installer touches.
# After the installer runs, it prints every created script between markers.
FAKE_ROBLOX_PRELUDE = r"""
local created = {}

local function newInstance(className)
	local instance = { ClassName = className, Name = className, children = {}, props = {} }
	local parent = nil
	local function setParent(newParent)
		if parent then
			for i, child in parent.children do
				if child == instance.proxy then
					table.remove(parent.children, i)
					break
				end
			end
		end
		parent = newParent and newParent.__data or nil
		if parent then
			table.insert(parent.children, instance.proxy)
		end
	end
	local proxy = setmetatable({}, {
		__index = function(_, key)
			if key == "__data" then
				return instance
			elseif key == "Parent" then
				return parent and parent.proxy or nil
			elseif key == "Name" then
				return instance.Name
			elseif key == "FindFirstChild" then
				return function(_, name)
					for _, child in instance.children do
						if child.Name == name then
							return child
						end
					end
					return nil
				end
			end
			return instance.props[key]
		end,
		__newindex = function(_, key, value)
			if key == "Parent" then
				setParent(value)
			elseif key == "Name" then
				instance.Name = value
			else
				instance.props[key] = value
			end
		end,
	})
	instance.proxy = proxy
	table.insert(created, proxy)
	return proxy
end

local services = {}
local function service(name)
	if services[name] == nil then
		local s = newInstance(name)
		s.Name = name
		services[name] = s
	end
	return services[name]
end

-- StarterPlayerScripts already exists inside StarterPlayer in a real place.
local starterPlayerScripts = newInstance("StarterPlayerScripts")
starterPlayerScripts.Name = "StarterPlayerScripts"
starterPlayerScripts.Parent = service("StarterPlayer")

-- An earlier install that must be replaced, not duplicated.
local stale = newInstance("Folder")
stale.Name = "CampusDeliveryDash"
stale.Parent = service("ReplicatedStorage")

service("RunService").IsRunning = function()
	return false
end
service("ChangeHistoryService").TryBeginRecording = function()
	return "recording-1"
end
service("ChangeHistoryService").FinishRecording = function() end

game = {
	GetService = function(_, name)
		return service(name)
	end,
}
Instance = { new = newInstance }
Enum = { FinishRecordingOperation = { Commit = "Commit" } }

local function fullName(instance)
	local parts = {}
	local current = instance
	while current do
		table.insert(parts, 1, current.Name)
		current = current.Parent
	end
	return table.concat(parts, ".")
end

local function report()
	for _, instance in created do
		local data = instance.__data
		if data.props.Source ~= nil then
			print("@@SCRIPT " .. fullName(instance) .. " " .. data.ClassName .. " " .. #data.props.Source)
			print(data.props.Source)
			print("@@END")
		end
	end
	local count = 0
	for _, child in service("ReplicatedStorage").__data.children do
		if child.Name == "CampusDeliveryDash" then
			count += 1
		end
	end
	print("@@SHARED_FOLDERS " .. count)
	print("@@STALE_PARENT " .. tostring(stale.Parent))
end
"""


def expected_scripts() -> dict[str, tuple[str, str]]:
    """Maps full instance path to (class, source) from the project and src/."""
    project = json.loads(build_installer.PROJECT_FILE.read_text(encoding="utf-8"))
    expected = {}
    for instance_path, directory in build_installer.find_mounts(project["tree"]):
        for name, class_name, source in build_installer.collect_scripts(ROOT / directory):
            expected[".".join(instance_path + (name,))] = (class_name, source)
    return expected


def find_luau() -> str | None:
    local = ROOT / ".tools" / "bin" / "luau"
    if local.exists():
        return str(local)
    return shutil.which("luau")


class LongStringTests(unittest.TestCase):
    def decode(self, literal: str) -> str:
        """Interprets a long string literal the way Luau does."""
        opening_end = literal.index("[", 1) + 1
        level = opening_end - 2
        body = literal[opening_end : len(literal) - (level + 2)]
        if body.startswith("\n"):
            body = body[1:]
        return body

    def test_plain_text_uses_level_zero(self):
        self.assertTrue(build_installer.long_string("print(1)").startswith("[[\n"))

    def test_text_containing_closing_brackets_uses_a_higher_level(self):
        text = "local t = a[b[1]] -- ]=] too"
        literal = build_installer.long_string(text)
        self.assertTrue(literal.startswith("[==[\n"))
        self.assertEqual(self.decode(literal), text)

    def test_leading_newline_and_trailing_bracket_survive(self):
        text = "\nfirst line\nlast]"
        self.assertEqual(self.decode(build_installer.long_string(text)), text)


class ScriptClassTests(unittest.TestCase):
    def test_rojo_suffixes(self):
        self.assertEqual(build_installer.script_class("Main.server.luau"), ("Main", "Script"))
        self.assertEqual(build_installer.script_class("Main.client.luau"), ("Main", "LocalScript"))
        self.assertEqual(build_installer.script_class("Config.luau"), ("Config", "ModuleScript"))
        self.assertIsNone(build_installer.script_class("notes.txt"))


class GeneratedInstallerTests(unittest.TestCase):
    def test_installer_recreates_every_script_exactly(self):
        luau = find_luau()
        if luau is None:
            self.skipTest("luau is not installed; run tools/install-dev-tools.sh")

        project = json.loads(build_installer.PROJECT_FILE.read_text(encoding="utf-8"))
        installer = build_installer.render(project)

        with tempfile.TemporaryDirectory() as directory:
            harness = Path(directory) / "harness.luau"
            harness.write_text(FAKE_ROBLOX_PRELUDE + "\ndo\n" + installer + "\nend\nreport()\n", encoding="utf-8")
            result = subprocess.run([luau, str(harness)], capture_output=True, text=True, timeout=60)

        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

        found: dict[str, tuple[str, str]] = {}
        lines = result.stdout.split("\n")
        index = 0
        shared_folders = None
        stale_parent = None
        while index < len(lines):
            line = lines[index]
            if line.startswith("@@SCRIPT "):
                _, path, class_name, length = line.split(" ")
                body_lines = []
                index += 1
                while lines[index] != "@@END":
                    body_lines.append(lines[index])
                    index += 1
                source = "\n".join(body_lines)
                # print() adds one newline; the source's own trailing newline
                # becomes the empty line before @@END.
                self.assertEqual(len(source.encode("utf-8")), int(length), path)
                found[path] = (class_name, source)
            elif line.startswith("@@SHARED_FOLDERS "):
                shared_folders = int(line.split(" ")[1])
            elif line.startswith("@@STALE_PARENT "):
                stale_parent = line.split(" ", 1)[1]
            index += 1

        expected = expected_scripts()
        self.assertEqual(sorted(found), sorted(expected))
        for path, (class_name, source) in expected.items():
            self.assertEqual(found[path][0], class_name, path)
            self.assertEqual(found[path][1], source, path)
        self.assertEqual(shared_folders, 1, "the old folder should be replaced, not duplicated")
        self.assertEqual(stale_parent, "nil", "the old folder should be unparented")


if __name__ == "__main__":
    unittest.main()

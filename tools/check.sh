#!/usr/bin/env bash
# Runs every automated check for this project. Use it before each commit,
# and have agents run it before they say a change is done.
#
#   tools/check.sh          check everything
#   tools/check.sh --fix    reformat Luau files and regenerate the Studio
#                           installer first, then check everything
#
# Exit code 0 means every check passed. These checks cannot replace a play
# test in Roblox Studio: they catch typos, type errors, broken rules and stale
# files, not whether the game is fun or works on a phone.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
export PATH="$ROOT/.tools/bin:$PATH"

for tool in luau luau-lsp rojo stylua python3; do
	if ! command -v "$tool" >/dev/null 2>&1; then
		echo "Missing tool: $tool"
		if [[ "$tool" == "python3" ]]; then
			echo "Install Python 3, then run this again."
		else
			echo "Run tools/install-dev-tools.sh first."
		fi
		exit 2
	fi
done

if [[ "${1:-}" == "--fix" ]]; then
	echo "== Formatting Luau files and regenerating the Studio installer"
	stylua src tests
	python3 tools/build_installer.py
fi

failures=0
run() {
	local name="$1"
	shift
	echo "== $name"
	if "$@"; then
		echo "   passed"
	else
		echo "   FAILED: $name"
		failures=$((failures + 1))
	fi
}

run "Formatting (StyLua)" stylua --check src tests

run "Unit tests (Luau)" luau tests/run.luau

# luau-lsp needs a map of where each file lives inside Roblox (a sourcemap)
# to follow require(...) calls, and Roblox's API definitions to type-check
# calls such as Instance.new("Part").
analyze() {
	rojo sourcemap default.project.json --output .tools/sourcemap.json &&
		luau-lsp analyze \
			--platform roblox \
			--sourcemap .tools/sourcemap.json \
			--definitions "@roblox=.tools/globalTypes.d.luau" \
			--base-luaurc .luaurc \
			src tests
}
run "Types and lint (luau-lsp with the Roblox API)" analyze

run "Rojo project builds" rojo build default.project.json --output .tools/CampusDeliveryDash.rbxlx

run "Studio installer is up to date" python3 tools/build_installer.py --check

run "Installer generator tests (Python)" python3 -m unittest discover --start-directory tests --pattern "test_*.py"

echo
if [[ $failures -eq 0 ]]; then
	echo "All checks passed."
else
	echo "$failures check(s) failed."
	exit 1
fi

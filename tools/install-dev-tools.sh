#!/usr/bin/env bash
# Downloads the pinned command-line tools used by tools/check.sh into .tools/
# (ignored by Git). Nothing is installed system-wide and no sudo is needed.
#
# Every download is checked against the SHA-256 recorded below, so a changed
# file is rejected instead of executed. To upgrade a tool, change its version
# and checksum together and run tools/check.sh afterwards.
#
# Supported: macOS on Apple Silicon (M1 or newer) and Linux x86_64 (CI).
#
# Usage: tools/install-dev-tools.sh

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOLS_DIR="$ROOT/.tools"
BIN_DIR="$TOOLS_DIR/bin"

LUAU_VERSION="0.740"
LUAU_LSP_VERSION="1.70.1"
ROJO_VERSION="7.6.1"
STYLUA_VERSION="2.5.2"

os="$(uname -s)"
arch="$(uname -m)"

if [[ "$os" == "Darwin" && "$arch" == "arm64" ]]; then
	luau_asset="luau-macos.zip"
	luau_sha="8414763743116cbc2533ee7c932d41ba66bd25ea7c2353bc7eed2934b60b6715"
	lsp_asset="luau-lsp-macos.zip"
	lsp_sha="7d3936e8dec6dc77547abd061d2e950da392562a5f94858b880f23dba50d84cd"
	rojo_asset="rojo-${ROJO_VERSION}-macos-aarch64.zip"
	rojo_sha="0755a2cb8a0d8a49d05f9253aba8dd3858fd3474896193bca5a2ffa96c570047"
	stylua_asset="stylua-macos-aarch64.zip"
	stylua_sha="92ff0889e16324801bc072692974bb67f8161e62010fc90f96c62a17f81f32c7"
elif [[ "$os" == "Linux" && "$arch" == "x86_64" ]]; then
	luau_asset="luau-ubuntu.zip"
	luau_sha="7d4035db01816f977f6e4c42e3d5e8ef4235d95e9afe63a3c38905b42dde60f2"
	lsp_asset="luau-lsp-linux-x86_64.zip"
	lsp_sha="1a2ea1ae4f98f8946cefd970a4b54853e11ab4775e6932faa7f60cf920346567"
	rojo_asset="rojo-${ROJO_VERSION}-linux-x86_64.zip"
	rojo_sha="a9542a713036897fdbd0173e7a105ea409658333133c949025fcb6f1a7ca909d"
	stylua_asset="stylua-linux-x86_64.zip"
	stylua_sha="bcb0d855e91f102f28a370e850f8566b3b44b79e6274d806ea5246837c0fd5ab"
else
	echo "Unsupported platform: $os $arch (supported: macOS arm64, Linux x86_64)." >&2
	exit 1
fi

# Roblox API type definitions used by luau-lsp, pinned to the same release.
defs_url="https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/${LUAU_LSP_VERSION}/scripts/globalTypes.d.luau"
defs_sha="2857efa8245485f8c25c19c018ee1ef9b46afab4efd2ea70fc3257cd3faf7080"

sha256_of() {
	if command -v sha256sum >/dev/null 2>&1; then
		sha256sum "$1" | cut -d' ' -f1
	else
		shasum -a 256 "$1" | cut -d' ' -f1
	fi
}

download() { # url destination expected_sha256
	local url="$1" dest="$2" expected="$3" actual
	echo "Downloading $(basename "$dest")"
	curl --fail --silent --show-error --location --retry 3 --output "$dest" "$url"
	actual="$(sha256_of "$dest")"
	if [[ "$actual" != "$expected" ]]; then
		rm -f "$dest"
		echo "Checksum mismatch for $url" >&2
		echo "  expected $expected" >&2
		echo "  actual   $actual" >&2
		exit 1
	fi
}

install_zip() { # url expected_sha256
	local url="$1" sha="$2" zip
	zip="$TOOLS_DIR/downloads/$(basename "$url")"
	download "$url" "$zip" "$sha"
	unzip -o -q "$zip" -d "$BIN_DIR"
}

mkdir -p "$BIN_DIR" "$TOOLS_DIR/downloads"

install_zip "https://github.com/luau-lang/luau/releases/download/${LUAU_VERSION}/${luau_asset}" "$luau_sha"
install_zip "https://github.com/JohnnyMorganz/luau-lsp/releases/download/${LUAU_LSP_VERSION}/${lsp_asset}" "$lsp_sha"
install_zip "https://github.com/rojo-rbx/rojo/releases/download/v${ROJO_VERSION}/${rojo_asset}" "$rojo_sha"
install_zip "https://github.com/JohnnyMorganz/StyLua/releases/download/v${STYLUA_VERSION}/${stylua_asset}" "$stylua_sha"
download "$defs_url" "$TOOLS_DIR/globalTypes.d.luau" "$defs_sha"

chmod +x "$BIN_DIR"/*
rm -rf "$TOOLS_DIR/downloads"

echo
echo "Installed into $BIN_DIR:"
"$BIN_DIR/rojo" --version
"$BIN_DIR/stylua" --version
"$BIN_DIR/luau-lsp" --version
echo "luau $LUAU_VERSION"
echo
echo "Next: tools/check.sh"

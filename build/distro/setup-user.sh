#!/bin/bash
# ビルド用 Ubuntu の既定のユーザで実行する。nvm・Node.js・AI エージェントをホームに入れる
# 引数: $1 = build/ フォルダ（Linux 側のパス）
set -euo pipefail
build_dir="$1"

read_list() {
	sed -e 's/\r$//' -e 's/#.*//' -e 's/[[:space:]]*$//' "$1" | grep -v '^$' || true
}

export NVM_DIR="$HOME/.nvm"
if [ ! -s "$NVM_DIR/nvm.sh" ]; then
	nvm_version="$(curl -fsSL https://api.github.com/repos/nvm-sh/nvm/releases/latest | grep -o '"tag_name": *"[^"]*"' | cut -d'"' -f4)"
	echo "[user] nvm $nvm_version を入れます"
	curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/$nvm_version/install.sh" | bash
fi

# nvm.sh は未定義の変数を参照するため、読み込みの間だけ -u を外す
set +u
. "$NVM_DIR/nvm.sh"
node_version="$(read_list "$build_dir/node-version.txt" | head -1)"
echo "[user] Node.js $node_version を入れます"
nvm install "$node_version"
nvm alias default "$node_version"
nvm use default
set -u

mapfile -t agents < <(read_list "$build_dir/npm-global.txt")
echo "[user] npm install -g: ${agents[*]}"
npm install -g "${agents[@]}"
npm cache clean --force

# Antigravity CLI は npm で配られていないため、提供元の導入スクリプトで ~/.local/bin に入れる
if [ ! -x "$HOME/.local/bin/agy" ]; then
	echo '[user] Antigravity CLI を入れます'
	curl -fsSL https://antigravity.google/cli/install.sh | bash
fi

echo '[user] 入った版'
echo "node $(node -v) / npm $(npm -v)"
npm ls -g --depth=0
"$HOME/.local/bin/agy" --version || echo '[user] agy の版を取得できませんでした' >&2

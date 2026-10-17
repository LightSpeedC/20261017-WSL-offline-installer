#!/bin/bash
# ビルド用 Ubuntu の root で実行する。apt のパッケージを入れ、既定のユーザを wsl.conf に書く
# 引数: $1 = build/ フォルダ（Linux 側のパス）
set -euo pipefail
build_dir="$1"

# 1 行に 1 つ。# 以降と空行、Windows の改行を読み飛ばす
read_list() {
	sed -e 's/\r$//' -e 's/#.*//' -e 's/[[:space:]]*$//' "$1" | grep -v '^$' || true
}

export DEBIAN_FRONTEND=noninteractive
echo '[root] apt update / full-upgrade'
apt-get update
apt-get -y full-upgrade

mapfile -t packages < <(read_list "$build_dir/packages.txt")
echo "[root] apt install: ${packages[*]}"
apt-get install -y "${packages[@]}"
apt-get -y autoremove
apt-get clean

# 書き出したあとも既定のユーザで起動するよう、wsl.conf に書く（名前は表示しない）
default_user="$(getent passwd 1000 | cut -d: -f1)"
if [ -z "$default_user" ]; then
	echo '[root] UID 1000 のユーザがいません。初回起動でユーザを作ってください' >&2
	exit 1
fi
touch /etc/wsl.conf
awk '/^\[/{skip=($0=="[user]")} !skip' /etc/wsl.conf > /etc/wsl.conf.new
printf '\n[user]\ndefault=%s\n' "$default_user" >> /etc/wsl.conf.new
mv /etc/wsl.conf.new /etc/wsl.conf
echo '[root] /etc/wsl.conf の [user] を UID 1000 のユーザにしました'

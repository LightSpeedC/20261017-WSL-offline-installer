# WSL オフラインインストーラ

ネットにつながらない Windows 11 PC へ、WSL2 と準備済みの Ubuntu を導入する

> 📅 作成: 2026-10-17 / 更新: 2026-10-17

[⌂](../)

ネットにつながる PC で、最新の WSL・Windows 用 GPU ドライバ・準備済みの Ubuntu 24.04 を集めて配布物にします。ネットにつながらない PC では、インストーラを実行するだけで導入できます。Ubuntu には開発ツール、nvm と Node.js、主な AI エージェント、llama-server（CPU・NVIDIA・Intel 向け）を入れておき、AI エージェントはオンプレの llama-server につないで使います。

```text
prepare/     ビルド側（ネットにつながる PC）のスクリプト
_bundle/     集めたもの（Git には入れない）
installer/   導入側（ネットにつながらない PC）のスクリプト
notes/       計画・状態・ルール
```

1. [計画](#1-計画)
2. [状態](#2-状態)
3. [ルール](#3-ルール)

## 1. 計画

- [WSL オフラインインストーラ 計画](notes/10_plan/p261017-01-WSLオフラインインストーラ.md)

## 2. 状態

- [WSL オフラインインストーラ 状態](notes/30_status/status.md)

## 3. ルール

- [WSL オフラインインストーラ ローカルルール](notes/90_rules/local-rules.md)

[⌂](../)

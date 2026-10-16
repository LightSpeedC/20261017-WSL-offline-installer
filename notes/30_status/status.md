# WSL オフラインインストーラ 状態

いまどこまで出来ているか

> 📅 作成: 2026-10-17 / 更新: 2026-10-17

[⌂](../../README.md)

1. [概要](#1-概要)
2. [実装の進み具合](#2-実装の進み具合)
3. [実測で確かめること](#3-実測で確かめること)

## 1. 概要

計画: [WSL オフラインインストーラ 計画](../10_plan/p261017-01-WSLオフラインインストーラ.md)（p261017-01）

初期化まで済み。次は `build/fetch-wsl.ps1`。

## 2. 実装の進み具合

| 順 | 作業 | 状態 |
|---|---|---|
| 1 | 初期化（git・.gitignore・文字コード定義） | ✅ **済** |
| 2 | `build/fetch-wsl.ps1`（最新の WSL msi を取得） | ⬜ **未** |
| 3 | `build/fetch-drivers.ps1`（NVIDIA・Intel の Windows 用ドライバ） | ⬜ **未** |
| 4 | `build/prepare-distro.ps1`（Ubuntu・apt・nvm・Node.js・AI エージェント） | ⬜ **未** |
| 5 | llama-server の 3 通りのビルド（CPU・CUDA・SYCL） | ⬜ **未** |
| 6 | AI エージェントを llama-server へつなぐ設定 | ⬜ **未** |
| 7 | `installer/install.ps1` ＋ `install.cmd` | ⬜ **未** |
| 8 | `build/package.ps1`（配布用 zip） | ⬜ **未** |
| 9 | オフラインの Windows 11 で検証（3 つの場面） | ⬜ **未** |

## 3. 実測で確かめること

| 項目 | 状態 |
|---|---|
| Node.js 26.11 が実在するか | ⬜ **未** |
| 初回起動で決めた既定ユーザが `wsl --export` に含まれるか | ⬜ **未** |
| `@moonshot-ai/kimi-code` が提供元の公式か | ⬜ **未** |
| Gemini CLI が終了しているか | ⬜ **未** |
| 各エージェントが llama-server へつなげるか | ⬜ **未** |
| ドライバの最新版を自動で取得できるか | ⬜ **未** |

[⌂](../../README.md)

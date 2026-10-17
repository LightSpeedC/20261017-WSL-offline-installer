# WSL オフラインインストーラ 状態

いまどこまで出来ているか

> 📅 作成: 2026-10-17 / 更新: 2026-10-17

[⌂](../../README.md)

1. [概要](#1-概要)
2. [実装の進み具合](#2-実装の進み具合)
3. [実測で確かめること](#3-実測で確かめること)

## 1. 概要

計画: [WSL オフラインインストーラ 計画](../10_plan/p261017-01-WSLオフラインインストーラ.md)（p261017-01）

リポジトリ: [LightSpeedC/20261017-WSL-offline-installer](https://github.com/LightSpeedC/20261017-WSL-offline-installer)（public、develop）

初期化・README・ローカルルール・`build/fetch-wsl.ps1`・`build/fetch-drivers.ps1` まで済み。次は `build/prepare-distro.ps1`。

## 2. 実装の進み具合

| 順 | 作業 | 状態 |
|---|---|---|
| 1 | 初期化（git・.gitignore・文字コード定義） | ✅ **済** |
| 2 | `build/fetch-wsl.ps1`（最新の WSL msi を取得）。2026-10-17 の実行で 3.0.3 を取得、SHA-256 は GitHub の digest と一致、署名は Microsoft で有効。この msi でビルド用の PC を 2.7.5 → 3.0.3 に更新でき、`wsl -v` で確認済み（カーネル 6.18.54.1-1） | ✅ **済** |
| 3 | `build/fetch-drivers.ps1`（NVIDIA・Intel の Windows 用ドライバ）。2026-10-17 の実行で NVIDIA 617.42・Intel 32.0.101.7092 を取得し、署名を確認。Intel のサイトはブラウザ以外を 403 で拒むため、Intel の URL は Chrome で調べて `build/intel-driver-url.txt` に置く。Iris Xe は「11th – 14th Gen Processor Graphics」の系統（Arc 用の 101.9xxx は Iris Xe を含まない）。ビルド用の PC に NVIDIA 617.42 を入れ、`nvidia-smi` で確認済み（CUDA 13.4） | ✅ **済** |
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
| ドライバの最新版を自動で取得できるか（NVIDIA は可。Intel はページが 403 のため URL を手で更新） | ✅ **済** |

[⌂](../../README.md)

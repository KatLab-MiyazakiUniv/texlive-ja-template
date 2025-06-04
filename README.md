# 日本語 LaTeX 執筆環境 (Docker)

このリポジトリは、Docker を使用した日本語 LaTeX 執筆環境を提供するリポジトリである。

## クイックスタート

### Makefile を使用した make コマンド

```bash
# 初回セットアップ（Docker イメージのビルドと起動）
make setup

# TeXファイルのコンパイル（src/*.tex のすべてのファイル）
make compile

# src/ 下のすべての .tex ファイルを監視し、変更があったら自動コンパイル、PDF 出力
make watch

# 生成されたPDFを確認 (Mac のみ)
make open-pdf
```

## 環境構築

### 1. Docker コンテナのビルドと起動

```bash
# 初回セットアップ (推奨)
make setup

# または個別に実行
make build  # Dockerイメージをビルド
make up     # コンテナを起動
```

### 2. コンテナへの接続 (必要な場合)

```bash
make exec
```

## LaTeX文書の作成とコンパイル

### 1. TeXファイルの配置
.tex ファイルは `src/` ディレクトリに配置すること：
```
src/
├── sample.tex
└── other.tex
```

### 2. コンパイル方法

```bash
# src/ 下のすべての .tex ファイルの変更分をコンパイル
make

# src/ 下のすべての .tex ファイルを強制的に再コンパイル
make compile

# src/ 下のすべての .tex ファイルを監視し、変更があったら自動コンパイル、PDF 出力
make watch
```

生成されたPDFファイルは `pdf/` ディレクトリに出力される。

## 利用可能なMakeコマンド

| コマンド (カッコ内は任意の引数) | 説明 |
|---------|------|
| `make help` | 利用可能なコマンド一覧を表示 |
| `make setup` | 初回セットアップ (ビルド + 起動) |
| `make build` | Dockerイメージをビルド |
| `make up` | コンテナを起動 |
| `make down` | コンテナを停止・削除 |
| `make exec` | コンテナに接続 |
| `make compile` | src/ 下の TeX ファイルを強制再コンパイル |
| `make watch` | src /下の TeX ファイルの変更を監視してコンパイル |
| `make clean` | LaTeX 中間ファイルを削除 |
| `make clean-all` | すべての LaTeX 生成ファイルを削除 |
| `make open-pdf` | 生成された PDF を開く (Mac用) |
| `make restart` | コンテナを再起動 |
| `make rebuild` | 完全に再ビルド |
| `make dev` | 開発モード (起動 + 監視コンパイル) |

## ディレクトリ構成

```
texlive-ja-template/
├── Dockerfile          # Docker 環境定義
├── compose.yaml        # Docker Compose 設定
├── Makefile           # ビルドタスク定義
├── .latexmkrc         # LaTeXmk 設定
├── build/             # コンパイル中間ファイル
│   └── *.aux, *.dvi など
└── pdf/               # 生成されたPDF
│   └── *.pdf
├── src/               # TeX ソースファイル
│   └── *.tex
```

## 使用できる TeXLive パッケージ

- latexmk: 自動コンパイルツール

## 不具合対処

1. ログファイルの確認
```bash
ls -l build/*.log
```

2. クリーンアップして再コンパイル
```bash
make clean-all  # すべての生成ファイルを削除
make compile    # 再コンパイル
```

3. Docker環境の再構築
```bash
make rebuild    # コンテナの完全な再構築
```

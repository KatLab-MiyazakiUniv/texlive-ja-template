# 日本語LaTeX執筆環境 (Docker)

このリポジトリは、Dockerを使用した日本語LaTeX執筆環境を提供します。

## クイックスタート

### Makefileを使用した簡単な操作

```bash
# ヘルプを表示
make help

# 初回セットアップ
make setup

# PDFをコンパイル
make compile

# ファイル変更を監視してコンパイル
make watch

# すべて実行（セットアップ→コンパイル→PDF表示）
make all
```

## 環境構築

### 1. Dockerコンテナのビルドと起動

```bash
# Makefileを使用
make build
make up

# または従来の方法
docker-compose up -d --build
```

### 2. コンテナへの接続

```bash
# Makefileを使用
make exec

# または従来の方法
docker-compose exec latex bash
```

## LaTeX文書のコンパイル

### 基本的なコンパイル

```bash
# Makefileを使用
make compile

# または従来の方法
latexmk sample.tex
```

### 自動コンパイル（ファイル変更を監視）

```bash
# Makefileを使用
make watch

# または従来の方法
latexmk -pvc sample.tex
```

### 手動コンパイル

```bash
uplatex sample.tex
dvipdfmx sample.dvi
```

## 利用可能なMakeコマンド

| コマンド | 説明 |
|---------|------|
| `make help` | 利用可能なコマンド一覧を表示 |
| `make setup` | 初回セットアップ（ビルド + 起動） |
| `make build` | Dockerイメージをビルド |
| `make up` | コンテナを起動 |
| `make down` | コンテナを停止・削除 |
| `make exec` | コンテナに接続 |
| `make compile` | sample.texをコンパイル |
| `make watch` | ファイル変更を監視してコンパイル |
| `make pdf` | コンテナ起動してPDF生成 |
| `make clean` | LaTeX中間ファイルを削除 |
| `make clean-all` | すべてのLaTeX生成ファイルを削除 |
| `make open-pdf` | 生成されたPDFを開く |
| `make restart` | コンテナを再起動 |
| `make rebuild` | 完全に再ビルド |
| `make all` | すべて実行 |

## ファイル構成

- `Dockerfile`: LaTeX環境のDockerイメージ定義
- `compose.yaml`: Docker Compose設定
- `Makefile`: ビルドタスクの定義
- `.latexmkrc`: LaTeXmk設定ファイル
- `sample.tex`: サンプルLaTeX文書
- `build/`: コンパイル結果の出力ディレクトリ

## 使用できるパッケージ

- texlive-full: 完全なTeX Live環境
- texlive-lang-japanese: 日本語サポート
- latexmk: 自動コンパイルツール

## コンテナの停止

```bash
# Makefileを使用
make down

# または従来の方法
docker-compose down
```

## トラブルシューティング

### 文字化けが発生する場合
- ファイルがUTF-8で保存されているか確認してください
- `\usepackage[utf8]{inputenc}` が記述されているか確認してください

### コンパイルエラーが発生する場合
- ログファイル（.log）を確認してください
- `make clean` でクリーンアップしてから再コンパイルしてみてください

### Dockerに関する問題
- `make status` でコンテナの状態を確認
- `make logs` でログを確認
- `make rebuild` で完全に再ビルド

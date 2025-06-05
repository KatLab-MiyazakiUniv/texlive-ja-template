# 日本語 LaTeX 執筆環境 (Docker)

このリポジトリは、Docker を使用した日本語 LaTeX 執筆環境を提供するリポジトリである。

## 環境構築

### 1. Makefile を使用した環境構築

`make` コマンドが利用可能な環境では、すぐに以下の手順で環境を構築できる：

```bash
# 初回セットアップ（Docker イメージのビルドと起動）
make setup

# src 下の .tex ファイルをコンパイルし、PDF に変換
make

# 最新の .tex ファイルの内容をコピーし、現在の日付で新規 .tex ファイルを作成
# 変更を自動監視し、変更後の内容で PDF を再生成
make copy
```

`make copy` 実行後は、新規作成した .tex ファイルの変更を監視する。

生成された PDF ファイルは `pdf/` ディレクトリに出力される。

### 2. Dev Containers を使用した環境構築

VS Code の Dev Containers を使用して環境を構築することもできる：

1. VS Code に [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) 拡張機能をインストールする。
2. このリポジトリを VS Code で開く。
3. コマンドパレット（`Cmd + Shift + P または Ctrl + Shift + P`）を開き、`Dev Containers: Rebuild and Reopen in Container` を選択する。もしくは、GUI 左下の青い >< から、`コンテナーで再度開く` -> `ワークスペースに構成を追加する` -> `` `Dockerfile` から`` -> 青い OK ボタン -> 青い OK ボタン の順で選択する。
4. コンテナ内で以下のコマンドを使用して作業を進める：

これにより、Docker コンテナ内で `make` を実行可能となり、以下の手順で環境を構築できる：

```bash
# src 下の .tex ファイルをコンパイルし、PDF に変換
make

# 最新の .tex ファイルの内容をコピーし、現在の日付で新規 .tex ファイルを作成
# 変更を自動監視し、変更後の内容で PDF を再生成
make copy
```
Dev Container 環境下では Docker 関連のコマンドの操作は不要。

`make copy` 実行後は、新規作成した .tex ファイルの変更を監視する。

生成された PDF ファイルは `pdf/` ディレクトリに出力される。

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

### LaTeX 関連コマンド

| コマンド          | 説明                                                         |
|------------------|-------------------------------------------------------------|
| `make help`      | 利用可能なコマンド一覧を表示 |
| `make compile`   | `src` 下の TeX ファイルを強制再コンパイル |
| `make watch`     | ファイルの変更を監視してコンパイル |
| `make copy`      | 今日の日付で新しい `.tex` ファイルを作成。変更を監視し、自動コンパイル |
| `make clean`     | LaTeX 中間ファイルを削除 |
| `make clean-all` | すべての LaTeX 生成ファイルを削除 |
| `make open-pdf`  | 生成された PDF を開く (Mac用) |

### Docker 関連コマンド

| コマンド          | 説明                          |
|------------------|------------------------------|
| `make setup`     | 初回セットアップ (ビルド + 起動) |
| `make build`     | Docker イメージをビルド |
| `make up`        | コンテナを起動 |
| `make down`      | コンテナを停止・削除 |
| `make exec`      | コンテナに接続 |
| `make stop`      | コンテナを停止 |
| `make logs`      | コンテナのログを表示 |
| `make restart`   | コンテナを再起動 |
| `make rebuild`   | 完全に再ビルド |
| `make dev`       | 開発モード (起動 + 監視コンパイル) |

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

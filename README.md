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

#### 標準的なLaTeX文書
```
src/
├── sample.tex
└── other.tex
```

#### IPSJ論文形式
IPSJ論文の場合は、エンコーディングに応じたサブディレクトリに配置：
```
src/IPSJ/
├── UTF8/              # UTF-8エンコーディング（推奨）
│   └── paper.tex
└── SJIS/              # Shift-JISエンコーディング
    └── paper.tex
```

他にも必要なファイルが複数存在するため、各自のリンクもしくは [情報処理学会, LaTeXスタイルファイル、MS-Wordテンプレートファイル](https://www.ipsj.or.jp/journal/submit/style.html) からテンプレートのフォルダを入手し、ファイルを各ディレクトリへコピーすること。

### 2. コンパイル方法

```bash
# src/ 下のすべての .tex ファイルの変更分をコンパイル
make

# src/ 下のすべての .tex ファイルを強制的に再コンパイル
make compile

# src/ 下のすべての .tex ファイルを監視し、変更があったら自動コンパイル、PDF 出力
make watch
```

生成されたPDFファイルは `pdf/` ディレクトリにサブディレクトリ構造を保持して出力される。

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

### IPSJ論文専用コマンド

| コマンド          | 説明                                                         |
|------------------|-------------------------------------------------------------|
| `make convert-punctuation FILE=path/to/file.tex` | 指定したIPSJファイルの句読点を変換（、→，、。→．） |
| `make restore-punctuation FILE=path/to/file.tex` | 変換前の句読点に戻す |

**使用例:**
```bash
# 句読点変換
make convert-punctuation FILE=src/IPSJ/UTF8/paper.tex

# 句読点復元
make restore-punctuation FILE=src/IPSJ/UTF8/paper.tex
```

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
├── scripts/           # ビルドスクリプト
│   └── watch.sh       # ファイル監視スクリプト
├── build/             # コンパイル中間ファイル
│   └── *.aux, *.dvi など
├── pdf/               # 生成されたPDF
│   └── *.pdf
└── src/               # TeX ソースファイル
    ├── *.tex          # 標準的なLaTeXファイル
    └── IPSJ/          # IPSJ論文形式
        ├── UTF8/      # UTF-8エンコーディング用
        │   ├── .latexmkrc # 2025年8月現在のもの、コンパイルオプション等に変更があれば編集必須
        │   ├── ipsj.cls   # クラスファイル、テンプレートファイルからコピーして配置
        │   └── *.tex
        └── SJIS/      # Shift-JISエンコーディング用
            ├── .latexmkrc
            ├── ipsj.cls
            └── *.tex
```

## 対応する論文形式とエンコーディング

### 標準LaTeX
- **エンコーディング**: UTF-8
- **コンパイラ**: uplatex + dvipdfmx
- **配置場所**: `src/*.tex`

### IPSJ論文形式
- **エンコーディング**: UTF-8 または Shift-JIS
- **コンパイラ**: uplatex + dvipdfmx
- **配置場所**:
  - UTF-8: `src/IPSJ/UTF8/*.tex`
  - SJIS: `src/IPSJ/SJIS/*.tex`
- **クラスファイル**: 各ディレクトリに各自で配置する (2025/8 現在、ファイル名は ipsj.cls)
- **句読点**: `make convert-punctuation` コマンドによる自動変換機能に対応（、→，、。→．）

## 使用できる TeXLive パッケージ

- latexmk: 自動コンパイルツール
- algorythm, algorithmicx: アルゴリズム
- graphicx: 図版挿入
- color: カラー対応

## 不具合対処

### 一般的な問題

1. **ログファイルの確認**
```bash
ls -l build/*.log
```

2. **クリーンアップして再コンパイル**
```bash
make clean-all  # すべての生成ファイルを削除
make compile    # 再コンパイル
```

3. **Docker環境の再構築**
```bash
make rebuild    # コンテナの完全な再構築
```

### IPSJ論文特有の問題

1. **フォントエラーが発生する場合**
   - IPSJクラスファイル(ipsj.cls)がipsj.clsの日本語フォント定義でエラーが発生することがありますが、デフォルトフォントで代替されるため問題ありません

2. **句読点の変換を間違えた場合**
```bash
# 元に戻す
make restore-punctuation FILE=src/IPSJ/UTF8/your-file.tex
```

3. **エンコーディングエラーが発生する場合**
   - UTF-8ファイルは `src/IPSJ/UTF8/` に配置
   - Shift-JISファイルは `src/IPSJ/SJIS/` に配置
   - ファイルのエンコーディングとディレクトリが一致していることを確認
   - .tex ファイル内で使用するクラスファイルを確認

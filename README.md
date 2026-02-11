# 日本語 LaTeX 執筆環境 (Docker)

このリポジトリは、Docker を使用した日本語 LaTeX 執筆環境を提供するリポジトリである。
標準的な LaTeX 文書に加え、情報処理学会 (IPSJ) 論文形式にも対応している。

## IPSJ 論文形式への対応

本環境では、IPSJ が配布するテンプレートファイル一式（`ipsj.cls`、`.bst`、`.sty` など）を `src/IPSJ/` 以下のサブディレクトリにそのまま配置することで、**IPSJ 指定の環境で PDF を作成できる**。

具体的には、[情報処理学会 LaTeX スタイルファイル](https://www.ipsj.or.jp/journal/submit/style.html) から入手したテンプレートフォルダの中身を、エンコーディングに応じて以下のディレクトリにコピーする：

```
src/IPSJ/
├── UTF8/          # UTF-8 エンコーディング用（推奨）
│   ├── .latexmkrc     # IPSJ 用コンパイル設定
│   ├── ipsj.cls       # IPSJ クラスファイル
│   ├── ipsjpref.sty   # IPSJ スタイルファイル
│   ├── ipsjtech.sty
│   ├── *.bst          # 参考文献スタイル (ipsjsort.bst, ipsjunsrt.bst 等)
│   ├── *.bib          # 参考文献データ
│   ├── images/        # 図版ディレクトリ
│   └── your-paper.tex # 自分の論文ファイル
└── SJIS/          # Shift-JIS エンコーディング用
    ├── .latexmkrc
    ├── ipsj.cls
    └── ...（同様の構成）
```

テンプレートファイルをディレクトリごと配置することで、以下が可能になる：

- **IPSJ 指定環境での PDF 生成**: `ipsj.cls` や各種 `.bst` ファイルが同一ディレクトリにあるため、IPSJ のフォーマットに準拠した PDF を `make` コマンド一つで生成できる
- **句読点の自動変換**: IPSJ 論文で求められるカンマ・ピリオド表記（「、」→「，」、「。」→「．」）への変換を `make convert-punctuation` で一括実行できる
- **参考文献の処理**: pBibTeX による参考文献処理と、参照番号の解決のための多重コンパイルを自動で行う

## 環境構築

### 1. Makefile を使用した環境構築

`make` コマンドが利用可能な環境では、以下の手順で環境を構築できる：

```bash
# 初回セットアップ（Docker イメージのビルドと起動）
make setup

# src 下の .tex ファイルをコンパイルし、PDF に変換。その後、変更を自動監視
make
```

生成された PDF ファイルは `pdf/` ディレクトリに出力される。

### 2. Dev Containers を使用した環境構築

VS Code の Dev Containers を使用して環境を構築することもできる：

1. VS Code に [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) 拡張機能をインストールする。
2. このリポジトリを VS Code で開く。
3. コマンドパレット（`Cmd + Shift + P または Ctrl + Shift + P`）を開き、`Dev Containers: Rebuild and Reopen in Container` を選択する。もしくは、GUI 左下の青い >< から、`コンテナーで再度開く` -> `ワークスペースに構成を追加する` -> `` `Dockerfile` から`` -> 青い OK ボタン -> 青い OK ボタン の順で選択する。
4. コンテナ内で以下のコマンドを使用して作業を進める：

```bash
# src 下の .tex ファイルをコンパイルし、PDF に変換。その後、変更を自動監視
make

# ファイルの変更を監視してコンパイル（監視のみ）
make watch
```

Dev Container 環境下では Docker 関連のコマンドの操作は不要。

生成された PDF ファイルは `pdf/` ディレクトリに出力される。

## LaTeX 文書の作成とコンパイル

### 1. TeX ファイルの配置

#### 標準的な LaTeX 文書

`src/` ディレクトリ直下に `.tex` ファイルを配置する：

```
src/
├── sample.tex
└── other.tex
```

#### IPSJ 論文形式

IPSJ 論文の場合は、IPSJ から配布されるテンプレートファイル一式をエンコーディングに応じたサブディレクトリに配置する。テンプレートは [情報処理学会 LaTeX スタイルファイル](https://www.ipsj.or.jp/journal/submit/style.html) から入手できる。

**重要**: `ipsj.cls` や `.bst` ファイルなど、テンプレートに含まれるファイルをすべて同一ディレクトリに配置すること。これにより、IPSJ のスタイル定義やコンパイル設定がそのまま利用でき、IPSJ 指定のフォーマットで PDF が生成される。

```
src/IPSJ/
├── UTF8/                  # UTF-8 エンコーディング（推奨）
│   ├── .latexmkrc         # コンパイル設定（同梱済み）
│   ├── ipsj.cls           # クラスファイル（テンプレートからコピー）
│   ├── ipsjpref.sty       # スタイルファイル（テンプレートからコピー）
│   ├── ipsjsort.bst       # 参考文献スタイル（テンプレートからコピー）
│   ├── ipsjunsrt.bst
│   ├── your-paper.tex     # 自分の論文
│   ├── your-paper.bib     # 参考文献データ
│   └── images/            # 図版
└── SJIS/                  # Shift-JIS エンコーディング
    └── ...（同様の構成）
```

### 2. コンパイル方法

```bash
# src/ 下のすべての .tex ファイルの変更分をコンパイルし、監視開始
make

# src/ 下のすべての .tex ファイルを強制的に再コンパイル
make compile

# src/ 下のすべての .tex ファイルを監視し、変更があったら自動コンパイル、PDF 出力
make watch
```

生成された PDF ファイルは `pdf/` ディレクトリにサブディレクトリ構造を保持して出力される。
例: `src/IPSJ/UTF8/paper.tex` → `pdf/IPSJ/UTF8/paper.pdf`

## 利用可能な Make コマンド

### LaTeX 関連コマンド

| コマンド          | 説明                                                         |
|------------------|-------------------------------------------------------------|
| `make`           | すべての TeX ファイルを PDF に変換し、変更の自動監視を開始 |
| `make help`      | 利用可能なコマンド一覧を表示 |
| `make compile`   | `src` 下の TeX ファイルを強制再コンパイル |
| `make watch`     | ファイルの変更を監視してコンパイル |
| `make clean`     | LaTeX 中間ファイルを削除 |
| `make clean-all` | すべての LaTeX 生成ファイルを削除 |
| `make open-pdf`  | 生成された PDF を開く (Mac 用) |

### IPSJ 論文専用コマンド

| コマンド          | 説明                                                         |
|------------------|-------------------------------------------------------------|
| `make convert-punctuation FILE=<path>` | 指定した IPSJ ファイルの句読点をカンマ・ピリオドに変換（「、」→「，」、「。」→「．」） |
| `make restore-punctuation FILE=<path>` | 変換前の句読点に戻す |

**使用例:**
```bash
# 句読点変換（IPSJ 投稿規定に合わせる）
make convert-punctuation FILE=src/IPSJ/UTF8/paper.tex

# 句読点復元（元の表記に戻す）
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
├── Makefile            # ビルドタスク定義
├── .latexmkrc          # LaTeXmk 設定（標準 LaTeX 用）
├── scripts/            # ビルドスクリプト
│   ├── watch.sh        # ファイル監視スクリプト
│   └── full-compile.sh # IPSJ 用多重コンパイルスクリプト
├── build/              # コンパイル中間ファイル
├── image/              # 標準 LaTeX 用の画像ファイル
├── pdf/                # 生成された PDF
└── src/                # TeX ソースファイル
    ├── *.tex           # 標準的な LaTeX ファイル
    └── IPSJ/           # IPSJ 論文形式（テンプレートごと配置）
        ├── UTF8/       # UTF-8 エンコーディング用
        │   ├── .latexmkrc     # IPSJ 用コンパイル設定
        │   ├── ipsj.cls       # クラスファイル
        │   ├── *.sty          # スタイルファイル
        │   ├── *.bst          # 参考文献スタイル
        │   ├── *.tex          # 論文ファイル
        │   └── images/        # 図版ディレクトリ
        └── SJIS/       # Shift-JIS エンコーディング用
            └── ...（UTF8 と同様の構成）
```

## 対応する論文形式とエンコーディング

### 標準 LaTeX
- **エンコーディング**: UTF-8
- **コンパイラ**: uplatex + dvipdfmx
- **配置場所**: `src/*.tex`

### IPSJ 論文形式
- **エンコーディング**: UTF-8 または Shift-JIS
- **コンパイラ**: platex + dvipdfmx（`full-compile.sh` による多重コンパイル）
- **配置場所**:
  - UTF-8: `src/IPSJ/UTF8/`（テンプレートファイル一式を含む）
  - SJIS: `src/IPSJ/SJIS/`（テンプレートファイル一式を含む）
- **クラスファイル**: IPSJ 配布のテンプレートから `ipsj.cls` を各ディレクトリに配置
- **句読点変換**: `make convert-punctuation` による自動変換に対応（「、」→「，」、「。」→「．」）

## 使用できる TeXLive パッケージ

- latexmk: 自動コンパイルツール
- algorithms, algorithmicx: アルゴリズム記述
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

3. **Docker 環境の再構築**
```bash
make rebuild    # コンテナの完全な再構築
```

### IPSJ 論文特有の問題

1. **フォントエラーが発生する場合**
   - `ipsj.cls` の日本語フォント定義でエラーが発生することがあるが、デフォルトフォントで代替されるため問題ない

2. **句読点の変換を間違えた場合**
```bash
# 元に戻す
make restore-punctuation FILE=src/IPSJ/UTF8/your-file.tex
```

3. **エンコーディングエラーが発生する場合**
   - UTF-8 ファイルは `src/IPSJ/UTF8/` に配置
   - Shift-JIS ファイルは `src/IPSJ/SJIS/` に配置
   - ファイルのエンコーディングとディレクトリが一致していることを確認

4. **参考文献や図表の番号が表示されない場合**
   - `make compile` で再コンパイルを実行する（多重コンパイルにより参照が解決される）
   - `.bib` ファイルが論文ファイルと同じディレクトリに配置されているか確認する

.PHONY: help build up down exec clean compile watch pdf stop logs convert-punctuation restore-punctuation

# TeXファイルのリストを取得（サブディレクトリも含む）
TEX_FILES := $(shell find src -name "*.tex" -type f)
PDF_FILES := $(patsubst src/%.tex,pdf/%.pdf,$(TEX_FILES))

# 実行環境の判定
IN_DEVCONTAINER := $(shell test -f /.dockerenv && test -f /workspace/.devcontainer/devcontainer.json && echo 1 || echo 0)

# 環境に応じたコマンドの定義
ifeq ($(IN_DEVCONTAINER),1)
    # Dev Container 内での実行コマンド
    DOCKER_PREFIX =
    CD_PREFIX = cd /workspace &&
else
    # Docker Compose 経由での実行コマンド
    DOCKER_PREFIX = docker compose exec -T latex
    CD_PREFIX = bash -c cd /workspace &&
endif

# 共通のコマンドを定義
LATEX_CMD       = $(DOCKER_PREFIX) $(CD_PREFIX) TEXINPUTS=./src//: LANG=ja_JP.UTF-8 LC_ALL=ja_JP.UTF-8 latexmk -pdfdvi
LATEX_CLEAN     = $(DOCKER_PREFIX) $(CD_PREFIX) latexmk -c
LATEX_CLEAN_ALL = $(DOCKER_PREFIX) $(CD_PREFIX) latexmk -C
CP_CMD          = $(DOCKER_PREFIX) $(CD_PREFIX) cp
RM_CMD          = $(DOCKER_PREFIX) $(CD_PREFIX) rm -rf

# エンコーディング別コンパイルコマンド
UTF8_COMPILE    = $(DOCKER_PREFIX) bash -c "cd /workspace/src/UTF8 && TEXINPUTS=.:../../src//: LANG=ja_JP.UTF-8 LC_ALL=ja_JP.UTF-8 uplatex -interaction=nonstopmode"
SJIS_COMPILE    = $(DOCKER_PREFIX) bash -c "cd /workspace/src/SJIS && TEXINPUTS=.:../../src//: LANG=ja_JP.SJIS LC_ALL=ja_JP.SJIS platex -interaction=nonstopmode"
DVI_TO_PDF_UTF8 = $(DOCKER_PREFIX) bash -c "cd /workspace/src/UTF8 && dvipdfmx -o ../../build"
DVI_TO_PDF_SJIS = $(DOCKER_PREFIX) bash -c "cd /workspace/src/SJIS && dvipdfmx -o ../../build"

# ファイル監視スクリプト（全環境対応）
WATCH_CMD       = $(DOCKER_PREFIX) bash -c "sed -i 's/\r$$//' /workspace/scripts/watch.sh && bash /workspace/scripts/watch.sh"

# デフォルトターゲット - 初回コンパイル後、自動監視開始
all: compile-all ## すべての TeX ファイルを PDF に変換し、監視開始

# 初回コンパイル（監視なし）
compile-all: $(PDF_FILES) ## すべての TeX ファイルを PDF に変換（監視なし）
	@if [ -n "$(TEX_FILES)" ]; then \
		echo "初回コンパイル完了。"; \
	else \
		echo "[WARNING] src/ ディレクトリに .tex ファイルが見つかりません。"; \
		exit 1; \
	fi

# デフォルト：初回コンパイル後、監視開始
default: compile-all watch ## 初回コンパイル後、ファイル監視開始

.DEFAULT_GOAL := default

help: ## ヘルプを表示
	@echo "利用可能なコマンド:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

# ヘルパー関数: ファイルタイプを判定
define get_file_type
$(if $(findstring UTF8/,$(1)),UTF8,$(if $(findstring SJIS/,$(1)),SJIS,NORMAL))
endef

# ヘルパー関数: エンコーディング別コンパイル
define compile_by_encoding
$(if $(filter UTF8,$(call get_file_type,$(1))),\
	$(UTF8_COMPILE) $(notdir $(1)) || true && $(DVI_TO_PDF_UTF8)/$(notdir $(basename $(1))).pdf $(notdir $(basename $(1))).dvi || true,\
	$(if $(filter SJIS,$(call get_file_type,$(1))),\
		$(SJIS_COMPILE) $(notdir $(1)) || true && $(DVI_TO_PDF_SJIS)/$(notdir $(basename $(1))).pdf $(notdir $(basename $(1))).dvi || true,\
		$(DOCKER_PREFIX) bash -c "cd /workspace && TEXINPUTS=./src//: latexmk -pdfdvi $(1)" || true\
	)\
)
endef

# ファイル別の PDF ビルドルール（エンコーディング対応）
pdf/%.pdf: src/%.tex
	@mkdir -p pdf build $(dir $@)
	@echo "$(call get_file_type,$<)ファイルをコンパイル: $<"
	@$(call compile_by_encoding,$<)
	@$(CP_CMD) build/$(notdir $(basename $<)).pdf $@ || true

# ヘルパー関数: 単一ファイルコンパイル
define compile_single_file
	@echo "コンパイル: $(1)"
	@rel_path=$$(echo "$(1)" | sed 's|^src/||'); \
	pdf_dir=pdf/$$(dirname "$$rel_path"); \
	mkdir -p "$$pdf_dir"; \
	$(call compile_by_encoding,$(1)); \
	pdf_name=$$(echo "$$rel_path" | sed 's/\.tex$$/\.pdf/'); \
	$(CP_CMD) build/$$(basename $(basename $(1))).pdf "pdf/$$pdf_name" || true
endef

# LaTeX 関連コマンド
compile: ## src 下の .tex ファイルをコンパイル（エンコーディング対応）
	@mkdir -p pdf build
	@$(foreach tex,$(TEX_FILES),$(call compile_single_file,$(tex));)
	@echo "コンパイル完了"

watch: ## ファイル変更を監視してコンパイル（全環境対応）
	@mkdir -p pdf build
	@echo "watching: src/**/*.tex (auto-detecting best method for your environment)"
	$(WATCH_CMD)

clean: ## LaTeX 中間ファイルを削除
	@for tex in $(TEX_FILES); do \
		echo "中間ファイル削除中: $$tex"; \
		$(LATEX_CLEAN) $$tex; \
	done
	$(RM_CMD) pdf/*

clean-all: ## すべての LaTeX 生成ファイルを削除
	@for tex in $(TEX_FILES); do \
		echo "生成ファイル完全削除中: $$tex"; \
		$(LATEX_CLEAN_ALL) $$tex; \
	done
	$(RM_CMD) pdf/* build/*

# ヘルパー関数: Docker環境チェック
define check_docker_env
	@if [ "$(IN_DEVCONTAINER)" = "1" ]; then \
		echo "[ERROR] Dev Container 環境では Docker 関連コマンドは使用できません"; \
		exit 1; \
	fi
endef

# ヘルパー関数: 環境別メッセージ表示
define show_env_message
	@if [ "$(IN_DEVCONTAINER)" = "1" ]; then \
		echo "[INFO] Dev Container 環境では $(1) は不要です。"; \
		echo "以下のコマンドでコンパイルできます:"; \
		echo "  make compile  # src 下の .tex ファイルをコンパイル"; \
		echo "  make watch   # ファイルの変更を監視してコンパイル"; \
	else \
		$(2); \
	fi
endef

# Docker 関連コマンド
build: ## Docker イメージをビルド
	$(call check_docker_env)
	docker compose build

up: ## コンテナを起動（バックグラウンド）
	$(call check_docker_env)
	docker compose up -d

down: ## コンテナを停止・削除
	$(call check_docker_env)
	docker compose down

exec: ## コンテナに接続
	$(call check_docker_env)
	docker compose exec latex bash

stop: ## コンテナを停止
	$(call check_docker_env)
	docker compose stop

logs: ## コンテナのログを表示
	$(call check_docker_env)
	docker compose logs -f latex

# 開発用コマンド
setup: ## 初回セットアップ (ビルド + 起動)
	$(call show_env_message,make setup による初回セットアップ,make build up && echo "環境構築を完了しました。以下のコマンドでコンパイルできます:" && echo "  make compile  # src 下の .tex ファイルをコンパイル" && echo "  make watch   # ファイルの変更を監視してコンパイル")

dev: ## 開発モード (起動 + 監視コンパイル)
	@if [ "$(IN_DEVCONTAINER)" = "1" ]; then \
		echo "[WARNING] Dev Container 環境では make up は不要です。make watch を実行します"; \
		make watch; \
	else \
		make up watch; \
	fi

restart: ## コンテナを再起動
	$(call check_docker_env)
	@make down up

rebuild: ## 完全に再ビルド
	$(call check_docker_env)
	@make down build up

# ファイル操作
open-pdf: ## 生成されたPDFを開く（Mac用）
	@if [ -f build/sample.pdf ]; then \
		open build/sample.pdf; \
	else \
		echo "PDFファイルが見つかりません。先に make compile を実行してください。"; \
	fi

# IPSJ形式の句読点変換
convert-punctuation: ## 指定したIPSJファイルの句読点を変換（例: make convert-punctuation FILE=src/IPSJ/UTF8/sample.tex）
	@if [ -z "$(FILE)" ]; then \
		echo "[ERROR] ファイルを指定してください。例: make convert-punctuation FILE=src/IPSJ/UTF8/sample.tex"; \
		exit 1; \
	fi
	@if [ ! -f "$(FILE)" ]; then \
		echo "[ERROR] ファイルが見つかりません: $(FILE)"; \
		exit 1; \
	fi
	@if ! echo "$(FILE)" | grep -q "IPSJ/"; then \
		echo "[ERROR] IPSJディレクトリ下のファイルを指定してください"; \
		exit 1; \
	fi
	@echo "句読点を変換中: $(FILE)"
	@$(DOCKER_PREFIX) bash -c "cd /workspace && cp '$(FILE)' '$(FILE).bak' && sed -i 's/、/，/g; s/。/．/g' '$(FILE)'"
	@echo "変換完了。元ファイルは $(FILE).bak として保存されました。"
	@echo "元に戻すには: make restore-punctuation FILE=$(FILE)"

restore-punctuation: ## 変換前の句読点に戻す（例: make restore-punctuation FILE=src/IPSJ/UTF8/sample.tex）
	@if [ -z "$(FILE)" ]; then \
		echo "[ERROR] ファイルを指定してください。例: make restore-punctuation FILE=src/IPSJ/UTF8/sample.tex"; \
		exit 1; \
	fi
	@if [ ! -f "$(FILE).bak" ]; then \
		echo "[ERROR] バックアップファイルが見つかりません: $(FILE).bak"; \
		exit 1; \
	fi
	@echo "句読点を復元中: $(FILE)"
	@$(DOCKER_PREFIX) bash -c "cd /workspace && mv '$(FILE).bak' '$(FILE)'"
	@echo "復元完了: $(FILE)"

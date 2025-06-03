.PHONY: help build up down exec clean compile watch pdf stop logs

# TeXファイルのリストを取得
TEX_FILES := $(wildcard src/*.tex)
PDF_FILES := $(patsubst src/%.tex,pdf/%.pdf,$(TEX_FILES))

# デフォルトターゲット
all: $(PDF_FILES) ## すべてのTeXファイルをPDFに変換

help: ## ヘルプを表示
	@echo "利用可能なコマンド:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

# ファイル別の PDF ビルドルール
pdf/%.pdf: src/%.tex
	@mkdir -p pdf build
	docker compose exec -T latex bash -c "cd /workspace && TEXINPUTS=./src//: latexmk -pdfdvi $<"
	docker compose exec -T latex cp build/$(notdir $(basename $<)).pdf $@

# LaTeX関連コマンド
compile: ## src 下の .tex ファイルをコンパイル
	@mkdir -p pdf build
	@for tex in $(TEX_FILES); do \
		echo "コンパイル: $$tex"; \
		docker compose exec -T latex bash -c "cd /workspace && TEXINPUTS=./src//: latexmk -pdfdvi $$tex && bibtex build/$$(basename $$tex .tex)"; \
		docker compose exec -T latex cp build/$$(basename $${tex%.tex}).pdf pdf/; \
	done

watch: ## ファイル変更を監視してコンパイル
	@mkdir -p pdf build
	docker compose exec -T latex bash -c "cd /workspace && TEXINPUTS=./src//: latexmk -pvc -pdfdvi src/*.tex"

clean: ## LaTeX 中間ファイルを削除
	@for tex in $(TEX_FILES); do \
		echo "中間ファイル削除中: $$tex"; \
		docker compose exec latex latexmk -c $$tex; \
		done
	docker compose exec latex rm -rf pdf/*

clean-all: ## すべての LaTeX 生成ファイルを削除
	@for tex in $(TEX_FILES); do \
		echo "生成ファイル完全削除中: $$tex"; \
		docker compose exec latex latexmk -C $$tex; \
	done
	docker compose exec latex rm -rf pdf/* build/*

# Docker 関連コマンド
build: ## Docker イメージをビルド
	docker compose build

up: ## コンテナを起動（バックグラウンド）
	docker compose up -d

down: ## コンテナを停止・削除
	docker compose down

exec: ## コンテナに接続
	docker compose exec latex bash

stop: ## コンテナを停止
	docker compose stop

logs: ## コンテナのログを表示
	docker compose logs -f latex

# 開発用コマンド
setup: build up ## 初回セットアップ (ビルド + 起動)
	@echo "環境が準備できました。以下のコマンドでコンパイルできます:"
	@echo "  make compile  # sample.texをコンパイル"
	@echo "  make watch    # ファイル変更を監視してコンパイル"

dev: up watch ## 開発モード (起動 + 監視コンパイル)

restart: down up ## コンテナを再起動

rebuild: down build up ## 完全に再ビルド

# ファイル操作
open-pdf: ## 生成されたPDFを開く（Mac用）
	@if [ -f build/sample.pdf ]; then \
		open build/sample.pdf; \
	else \
		echo "PDFファイルが見つかりません。先にmake compileを実行してください。"; \
	fi

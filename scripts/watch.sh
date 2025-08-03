#!/usr/bin/env bash
set -uo pipefail

cd /workspace || {
  echo "[ERROR] Cannot change directory to /workspace" >&2
  exit 1
}

# ログ出力関数
log_info() {
  echo "[INFO] $*"
}

log_warn() {
  echo "[WARN] $*"
}

log_error() {
  echo "[ERROR] $*" >&2
}

log_debug() {
  [[ "${DEBUG:-}" == "1" ]] && echo "[DEBUG] $*"
}

# エンコーディング判定関数
detect_encoding() {
  local tex="$1"

  if [[ "$tex" =~ UTF8/ ]]; then
    echo "UTF8"
  elif [[ "$tex" =~ SJIS/ ]]; then
    echo "SJIS"
  else
    echo "STANDARD"
  fi
}

# ソースディレクトリを取得する関数
get_source_dir() {
  local tex="$1"

  if [[ "$tex" =~ IPSJ/UTF8/ ]]; then
    echo "/workspace/src/IPSJ/UTF8"
  elif [[ "$tex" =~ IPSJ/SJIS/ ]]; then
    echo "/workspace/src/IPSJ/SJIS"
  else
    echo "/workspace/src"
  fi
}

# パス設定を決定する関数
get_paths() {
  local tex="$1"

  if [[ "$tex" =~ IPSJ/ ]]; then
    echo "../../../build" ".:./../../../src//:"
  else
    echo "../../build" ".:../../src//:"
  fi
}

# 中間ファイルをクリーンアップする関数
cleanup_intermediate_files() {
  local tex="$1"
  local output_dir="$2"

  rm -f "${output_dir}/$(basename "$tex" .tex)".{aux,dvi,log,out,toc,synctex.gz}
}

# pBibTeX処理を統一する関数
process_pbibtex() {
  local tex="$1"
  local tex_base="$2"
  local output_dir="$3"

  # 絶対パスでaux fileパスを構築
  local aux_file
  if [[ "$output_dir" = /* ]]; then
    aux_file="${output_dir}/${tex_base}.aux"
  else
    aux_file="/workspace/${output_dir}/${tex_base}.aux"
  fi

  log_debug "Checking aux file: $aux_file"
  log_debug "Current working directory: $(pwd)"

  # auxファイルの存在とbibdataの確認を一定時間待機
  local max_wait=3
  local count=0
  while [[ $count -lt $max_wait ]]; do
    if [[ -f "$aux_file" ]] && grep -q "\\\\bibdata" "$aux_file"; then
      break
    fi
    sleep 0.5
    ((count++))
  done
  
  if [[ -f "$aux_file" ]] && grep -q "\\\\bibdata" "$aux_file"; then
    log_info "Running pBibTeX for $tex"

    # buildディレクトリに移動
    local build_dir="/workspace/build"
    local original_dir="$(pwd)"
    cd "$build_dir"

    # 必要なファイルを直接buildディレクトリにコピー
    local source_dir="$(get_source_dir "$tex")"

    log_debug "Copying bibliography files from $source_dir"
    cp "$source_dir"/*.bst . 2>/dev/null || log_warn "No .bst files found"
    cp "$source_dir"/*.bib . 2>/dev/null || log_warn "No .bib files found"

    # pBibTeX実行とファイル生成の確認
    if pbibtex "$tex_base"; then
      # .bblファイルの生成を確認
      local bbl_file="${tex_base}.bbl"
      local bbl_wait=0
      while [[ ! -f "$bbl_file" && $bbl_wait -lt 5 ]]; do
        sleep 0.2
        ((bbl_wait++))
      done
      
      if [[ -f "$bbl_file" ]]; then
        log_debug "pBibTeX completed successfully, .bbl file generated"
      else
        log_warn "pBibTeX completed but .bbl file not found"
      fi
    else
      log_warn "pBibTeX failed for $tex_base"
    fi

    cd "$original_dir"
  else
    log_debug "No bibliography processing needed for $tex"
  fi
}

# DVIからPDFへの変換を行う関数
convert_dvi_to_pdf() {
  local tex="$1"
  local output_dir="$2"

  local dvi_file="${output_dir}/$(basename "$tex" .tex).dvi"
  local pdf_output="${output_dir}/$(basename "$tex" .tex).pdf"

  if [[ -f "$dvi_file" ]]; then
    if dvipdfmx -o "$pdf_output" "$dvi_file" 2>/dev/null; then
      log_info "LaTeX compilation successful for $tex"
      return 0
    else
      log_warn "DVI to PDF conversion failed for $tex"
      return 1
    fi
  else
    log_warn "LaTeX compilation failed for $tex - DVI file not generated"
    return 1
  fi
}

# LaTeXコンパイルを実行する関数（複数回実行対応）
compile_latex() {
  local tex="$1"
  local encoding="$2"
  local compiler="$3"

  local tex_file="$(basename "$tex")"
  local tex_base="$(basename "$tex" .tex)"
  local paths=($(get_paths "$tex"))
  local output_dir="${paths[0]}"
  local texinputs_path="${paths[1]}"

  # 中間ファイルをクリーンアップ
  cleanup_intermediate_files "$tex" "$output_dir"

  # LaTeXコンパイルコマンドを準備
  local compile_cmd
  if [[ "$encoding" == "UTF8" ]]; then
    compile_cmd="TEXINPUTS=\"$texinputs_path\" LANG=ja_JP.UTF-8 LC_ALL=ja_JP.UTF-8 $compiler -output-directory=\"$output_dir\" -interaction=nonstopmode \"$tex_file\""
  elif [[ "$encoding" == "SJIS" ]]; then
    compile_cmd="TEXINPUTS=\"$texinputs_path\" LANG=ja_JP.SJIS LC_ALL=ja_JP.SJIS $compiler -output-directory=\"$output_dir\" -interaction=nonstopmode \"$tex_file\""
  else
    compile_cmd="TEXINPUTS=\"$texinputs_path\" LANG=ja_JP.UTF-8 LC_ALL=ja_JP.UTF-8 $compiler -output-directory=\"$output_dir\" -interaction=nonstopmode \"$tex\""
  fi

  # 1回目のコンパイル
  log_info "First compilation pass for $tex"
  eval "$compile_cmd" || true

  # pBibTeX処理
  process_pbibtex "$tex" "$tex_base" "$output_dir"

  # 2回目のコンパイル（参照解決のため）
  log_info "Second compilation pass for $tex"
  eval "$compile_cmd" || true

  # 3回目のコンパイル（相互参照の完全解決のため）
  log_info "Third compilation pass for $tex"
  eval "$compile_cmd" || true

  # DVIからPDFへの変換
  convert_dvi_to_pdf "$tex" "$output_dir"
}

# 標準エンコーディング用のコンパイル関数
compile_standard() {
  local tex="$1"
  local tex_base="$(basename "$tex" .tex)"

  cleanup_intermediate_files "$tex" "build"

  # 1回目のコンパイル
  log_info "First compilation pass for $tex"
  TEXINPUTS=./src//: LANG=ja_JP.UTF-8 LC_ALL=ja_JP.UTF-8 uplatex -output-directory=build -interaction=nonstopmode "$tex" || true

  # pBibTeX処理
  process_pbibtex "$tex" "$tex_base" "build"

  # 2回目のコンパイル
  log_info "Second compilation pass for $tex"
  TEXINPUTS=./src//: LANG=ja_JP.UTF-8 LC_ALL=ja_JP.UTF-8 uplatex -output-directory=build -interaction=nonstopmode "$tex" || true

  # 3回目のコンパイル
  log_info "Third compilation pass for $tex"
  TEXINPUTS=./src//: LANG=ja_JP.UTF-8 LC_ALL=ja_JP.UTF-8 uplatex -output-directory=build -interaction=nonstopmode "$tex" || true

  convert_dvi_to_pdf "$tex" "build"
}

# メインのコンパイル関数
tex_compile() {
  local tex="$1"
  log_info "Compiling: $tex"

  local original_dir="$(pwd)"

  local encoding="$(detect_encoding "$tex")"

  case "$encoding" in
    "UTF8")
      log_info "UTF-8 encoding detected: $tex"
      if [[ "$tex" =~ IPSJ/UTF8/ ]]; then
        cd src/IPSJ/UTF8
      else
        cd src/UTF8
      fi
      compile_latex "$tex" "UTF8" "uplatex"
      ;;
    "SJIS")
      log_info "SJIS encoding detected: $tex"
      if [[ "$tex" =~ IPSJ/SJIS/ ]]; then
        cd src/IPSJ/SJIS
      else
        cd src/SJIS
      fi
      compile_latex "$tex" "SJIS" "platex"
      ;;
    "STANDARD")
      log_info "Standard encoding: $tex"
      compile_standard "$tex"
      ;;
  esac

  cd "$original_dir"

  # サブディレクトリ構造を維持してPDFをコピー
  copy_pdf_to_output "$tex"
}

# PDFを最終出力ディレクトリにコピーする関数
copy_pdf_to_output() {
  local tex="$1"
  local rel_path="${tex#src/}"
  local pdf_dir="pdf/$(dirname "$rel_path")"
  local pdf_name="${rel_path%.tex}.pdf"
  local build_pdf="build/$(basename "$tex" .tex).pdf"

  mkdir -p "$pdf_dir"

  if [[ -f "$build_pdf" ]]; then
    if cp "$build_pdf" "pdf/$pdf_name"; then
      log_info "PDF created: pdf/$pdf_name"
    else
      log_warn "Failed to copy PDF for $tex"
    fi
  else
    log_warn "Build PDF not found: $build_pdf"
  fi
}

# 単一ファイルコンパイル関数
compile_single() {
  local tex="$1"
  tex_compile "$tex"
  log_info "Single file compilation finished for: $tex"
}

# コンパイル進行中フラグ
declare -A compilation_in_progress

# シグナルハンドリング
trap 'log_info "Watch stopped"; exit 0' SIGINT SIGTERM

log_info "Using polling method for Docker mount compatibility"

# ポーリング監視
declare -A file_times

# 初期ファイル時刻を記録
while IFS= read -r -d '' tex; do
  file_times["$tex"]=$(stat -c %Y "$tex" 2>/dev/null || stat -f %m "$tex")
  compilation_in_progress["$tex"]=0
  log_info "Tracking: $tex"
done < <(find src -name "*.tex" -type f -print0)

# メインの監視ループ
while true; do
  while IFS= read -r -d '' tex; do
    current=$(stat -c %Y "$tex" 2>/dev/null || stat -f %m "$tex")
    if [[ "${file_times[$tex]:-}" != "$current" ]]; then
      # コンパイル進行中の場合はスキップ
      if [[ "${compilation_in_progress[$tex]:-0}" == "1" ]]; then
        log_debug "Skipping compilation for $tex (already in progress)"
        continue
      fi
      
      file_times["$tex"]=$current
      log_info "Change detected in: $tex"
      
      # コンパイル開始フラグを設定
      compilation_in_progress["$tex"]=1
      
      # 短い待機時間で複数変更をまとめる
      sleep 0.5
      
      # 再度時刻をチェックして、さらに変更があった場合は最新を取得
      latest=$(stat -c %Y "$tex" 2>/dev/null || stat -f %m "$tex")
      if [[ "$current" != "$latest" ]]; then
        file_times["$tex"]=$latest
        log_debug "Multiple changes detected, using latest version"
      fi
      
      compile_single "$tex"
      
      # コンパイル完了フラグをリセット
      compilation_in_progress["$tex"]=0
    fi
  done < <(find src -name "*.tex" -type f -print0)
  sleep 1
done

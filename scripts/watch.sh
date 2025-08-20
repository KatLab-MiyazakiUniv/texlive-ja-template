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
    echo "/workspace/build" ".:./../../../src//:"
  else
    echo "/workspace/build" ".:../../src//:"
  fi
}

# 中間ファイルをクリーンアップする関数
cleanup_intermediate_files() {
  local tex="$1"
  local output_dir="$2"

  # output_dirが絶対パスでない場合は/workspace/buildに正規化
  if [[ "$output_dir" != "/workspace/build" ]]; then
    output_dir="/workspace/build"
  fi

  rm -f "${output_dir}/$(basename "$tex" .tex)".{aux,dvi,log,out,toc,synctex.gz,bbl,blg}
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
  local max_wait=5
  local count=0
  while [[ $count -lt $max_wait ]]; do
    if [[ -f "$aux_file" ]] && grep -q "\\\\bibdata" "$aux_file"; then
      break
    fi
    sleep 1
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
      while [[ ! -f "$bbl_file" && $bbl_wait -lt 10 ]]; do
        sleep 0.5
        ((bbl_wait++))
      done

      if [[ -f "$bbl_file" ]]; then
        log_info "pBibTeX completed successfully, .bbl file generated"
        # .bblファイルをソースディレクトリにもコピー
        cp "$bbl_file" "$source_dir/" 2>/dev/null && log_debug "Copied .bbl file to source directory"
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
    # buildディレクトリに移動してimagesディレクトリをコピー
    local source_dir="$(get_source_dir "$tex")"
    local build_dir="/workspace/build"
    local original_dir="$(pwd)"

    cd "$build_dir"
    if [[ -d "$source_dir/images" ]]; then
      log_debug "Copying images from $source_dir/images to $build_dir"
      rm -rf images 2>/dev/null
      if ! cp -r "$source_dir/images" . 2>/dev/null; then
        # ディレクトリが既に存在する場合は内容を同期
        if [[ -d images ]]; then
          log_debug "Images directory exists, syncing contents"
          cp -r "$source_dir/images/"* images/ 2>/dev/null || log_warn "Failed to sync images directory contents"
        else
          log_warn "Failed to copy images directory"
        fi
      fi
    fi

    # 絶対パスを使用してDVI→PDF変換
    local abs_dvi_file
    local abs_pdf_output
    
    # buildディレクトリは常に/workspace/buildに正規化
    if [[ "$output_dir" == "../../../build" ]]; then
      abs_dvi_file="/workspace/build/$(basename "$tex" .tex).dvi"
      abs_pdf_output="/workspace/build/$(basename "$tex" .tex).pdf"
    elif [[ "$output_dir" == "../../build" ]]; then
      abs_dvi_file="/workspace/build/$(basename "$tex" .tex).dvi"
      abs_pdf_output="/workspace/build/$(basename "$tex" .tex).pdf"
    elif [[ "$output_dir" == "build" ]]; then
      abs_dvi_file="/workspace/build/$(basename "$tex" .tex).dvi"
      abs_pdf_output="/workspace/build/$(basename "$tex" .tex).pdf"
    else
      # 絶対パスの場合
      if [[ "$dvi_file" = /* ]]; then
        abs_dvi_file="$dvi_file"
      else
        abs_dvi_file="/workspace/$dvi_file"
      fi
      
      if [[ "$pdf_output" = /* ]]; then
        abs_pdf_output="$pdf_output"
      else
        abs_pdf_output="/workspace/$pdf_output"
      fi
    fi
    
    log_debug "Converting DVI to PDF: dvipdfmx -o $abs_pdf_output $abs_dvi_file"
    if dvipdfmx -o "$abs_pdf_output" "$abs_dvi_file"; then
      log_info "LaTeX compilation successful for $tex"
      cd "$original_dir"
      return 0
    else
      log_warn "DVI to PDF conversion failed for $tex"
      cd "$original_dir"
      return 1
    fi
  else
    log_warn "LaTeX compilation failed for $tex - DVI file not generated"
    return 1
  fi
}

# 統一コンパイル関数（full-compile.shを使用）
compile_unified() {
  local tex="$1"
  local encoding="$2"

  local tex_base="$(basename "$tex" .tex)"
  
  log_info "Unified compilation for $tex (encoding: $encoding)"
  bash /workspace/scripts/full-compile.sh "$tex_base" "$encoding" || log_error "Unified compilation failed for $tex"
}

# 標準エンコーディング用のコンパイル関数（統一版）
compile_standard() {
  local tex="$1"
  local tex_base="$(basename "$tex" .tex)"

  log_info "Standard compilation for $tex using latexmk"
  TEXINPUTS=./src//: latexmk -pdfdvi "$tex" || log_error "Standard compilation failed for $tex"
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
        compile_unified "$tex" "UTF8"
      else
        cd src/UTF8
        compile_unified "$tex" "UTF8"
      fi
      ;;
    "SJIS")
      log_info "SJIS encoding detected: $tex"
      compile_unified "$tex" "SJIS"
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

# .bibファイルも監視対象に追加
while IFS= read -r -d '' bib; do
  file_times["$bib"]=$(stat -c %Y "$bib" 2>/dev/null || stat -f %m "$bib")
  compilation_in_progress["$bib"]=0
  log_info "Tracking bibliography: $bib"
done < <(find src -name "*.bib" -type f -print0)

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

  # .bibファイルの変更を監視
  while IFS= read -r -d '' bib; do
    current=$(stat -c %Y "$bib" 2>/dev/null || stat -f %m "$bib")
    if [[ "${file_times[$bib]:-}" != "$current" ]]; then
      file_times["$bib"]=$current
      log_info "Bibliography change detected in: $bib"

      # この.bibファイルを使用している.texファイルを見つけてコンパイル
      bib_name="$(basename "$bib" .bib)"
      tex_dir="$(dirname "$bib")"

      # 同じディレクトリの.texファイルでこのbibファイルを参照しているものを検索
      while IFS= read -r -d '' related_tex; do
        if [[ -n "$related_tex" && "${compilation_in_progress[$related_tex]:-0}" == "0" ]]; then
          log_info "Recompiling $related_tex due to bibliography change"
          compilation_in_progress["$related_tex"]=1
          compile_single "$related_tex"
          compilation_in_progress["$related_tex"]=0
        fi
      done < <(find "$tex_dir" -name "*.tex" -type f -print0 | xargs -0 grep -l "\\\\bibliography{$bib_name}" 2>/dev/null | tr '\n' '\0')
    fi
  done < <(find src -name "*.bib" -type f -print0)

  sleep 1
done

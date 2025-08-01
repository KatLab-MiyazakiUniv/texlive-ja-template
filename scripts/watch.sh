#!/usr/bin/env bash
set -euo pipefail

cd /workspace || {
  echo "[ERROR] Cannot change directory to /workspace" >&2
  exit 1
}

tex_compile() {
  local tex="$1"
  echo "[INFO] Compiling: $tex"

  if [[ "$tex" =~ UTF8/ ]]; then
    echo "[INFO] UTF-8 encoding detected: $tex"

    # ディレクトリを適切に設定
    if [[ "$tex" =~ IPSJ/UTF8/ ]]; then
      cd src/IPSJ/UTF8
      echo "[INFO] IPSJ format: Converting punctuation marks"
      sed 's/、/，/g; s/。/．/g' "$(basename "$tex")" > "$(basename "$tex" .tex)_converted.tex"
      tex_file="$(basename "$tex" .tex)_converted.tex"
    else
      cd src/UTF8
      tex_file="$(basename "$tex")"
    fi

    # 古いファイルをクリーンアップ
    rm -f "$(basename "$tex" .tex)".{aux,dvi,log,out,toc,synctex.gz}

    # TEXINPUTSパスをディレクトリに応じて設定
    if [[ "$tex" =~ IPSJ/ ]]; then
      texinputs_path=".:./../../../src//:"
      build_path="../../../build/$(basename "$tex" .tex).pdf"
    else
      texinputs_path=.:../../src//:
      build_path="../../build/$(basename "$tex" .tex).pdf"
    fi

    if TEXINPUTS="$texinputs_path" LANG=ja_JP.UTF-8 LC_ALL=ja_JP.UTF-8 uplatex -interaction=nonstopmode "$tex_file"; then
      if dvipdfmx -o "$build_path" "$(basename "$tex" .tex).dvi"; then
        echo "[INFO] LaTeX compilation successful for $tex"
      else
        echo "[WARN] DVI to PDF conversion failed for $tex"
      fi
    else
      echo "[WARN] LaTeX compilation failed for $tex"
    fi

    # 一時ファイルをクリーンアップ
    [[ "$tex" =~ IPSJ/ ]] && rm -f "$(basename "$tex" .tex)_converted.tex"
    cd - >/dev/null
  elif [[ "$tex" =~ SJIS/ ]]; then
    echo "[INFO] SJIS encoding detected: $tex"

    # ディレクトリを適切に設定
    if [[ "$tex" =~ IPSJ/SJIS/ ]]; then
      cd src/IPSJ/SJIS
      echo "[INFO] IPSJ format: Converting punctuation marks"
      sed 's/、/，/g; s/。/．/g' "$(basename "$tex")" > "$(basename "$tex" .tex)_converted.tex"
      tex_file="$(basename "$tex" .tex)_converted.tex"
    else
      cd src/SJIS
      tex_file="$(basename "$tex")"
    fi

    # 古いファイルをクリーンアップ
    rm -f "$(basename "$tex" .tex)".{aux,dvi,log,out,toc,synctex.gz}

    # TEXINPUTSパスをディレクトリに応じて設定
    if [[ "$tex" =~ IPSJ/ ]]; then
      texinputs_path=".:./../../../src//:"
      build_path="../../../build/$(basename "$tex" .tex).pdf"
    else
      texinputs_path=.:../../src//:
      build_path="../../build/$(basename "$tex" .tex).pdf"
    fi

    if TEXINPUTS="$texinputs_path" LANG=ja_JP.SJIS LC_ALL=ja_JP.SJIS platex -interaction=nonstopmode "$tex_file"; then
      if dvipdfmx -o "$build_path" "$(basename "$tex" .tex).dvi"; then
        echo "[INFO] LaTeX compilation successful for $tex"
      else
        echo "[WARN] DVI to PDF conversion failed for $tex"
      fi
    else
      echo "[WARN] LaTeX compilation failed for $tex"
    fi
    
    # 一時ファイルをクリーンアップ
    [[ "$tex" =~ IPSJ/ ]] && rm -f "$(basename "$tex" .tex)_converted.tex"
    cd - >/dev/null
  else
    echo "[INFO] Standard encoding: $tex"
    # 古いファイルをクリーンアップ
    rm -f "$(basename "$tex" .tex)".{aux,dvi,log,out,toc,synctex.gz}
    if TEXINPUTS=./src//: LANG=ja_JP.UTF-8 LC_ALL=ja_JP.UTF-8 uplatex -interaction=nonstopmode "$tex"; then
      if dvipdfmx -o "build/$(basename "$tex" .tex).pdf" "$(basename "$tex" .tex).dvi"; then
        echo "[INFO] LaTeX compilation successful for $tex"
      else
        echo "[WARN] DVI to PDF conversion failed for $tex"
      fi
    else
      echo "[WARN] LaTeX compilation failed for $tex"
    fi
  fi

  # サブディレクトリ構造を維持してPDFをコピー
  local rel_path="${tex#src/}"
  local pdf_dir="pdf/$(dirname "$rel_path")"
  mkdir -p "$pdf_dir"
  local pdf_name="${rel_path%.tex}.pdf"
  if cp "build/$(basename "$tex" .tex).pdf" "pdf/$pdf_name" 2>/dev/null; then
    echo "[INFO] PDF created: pdf/$pdf_name"
  else
    echo "[WARN] Failed to copy PDF for $tex"
  fi
}

compile_single() {
  local tex="$1"
  tex_compile "$tex"
  echo "[INFO] Single file compilation finished for: $tex"
}

# シグナルハンドリング
trap 'echo "[INFO] Watch stopped"; exit 0' SIGINT SIGTERM

echo "[INFO] Using polling method for Docker mount compatibility"

# ポーリング監視
declare -A file_times

# 初期ファイル時刻を記録
while IFS= read -r -d '' tex; do
  file_times["$tex"]=$(stat -c %Y "$tex" 2>/dev/null || stat -f %m "$tex")
  echo "[INFO] Tracking: $tex"
done < <(find src -name "*.tex" -type f -print0)

while true; do
  while IFS= read -r -d '' tex; do
    current=$(stat -c %Y "$tex" 2>/dev/null || stat -f %m "$tex")
    if [[ "${file_times[$tex]:-}" != "$current" ]]; then
      file_times["$tex"]=$current
      echo "[INFO] Change detected in: $tex"
      compile_single "$tex"
    fi
  done < <(find src -name "*.tex" -type f -print0)
  sleep 1
done

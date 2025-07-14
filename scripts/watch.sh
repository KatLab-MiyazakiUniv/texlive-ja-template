#!/usr/bin/env bash
set -euo pipefail

cd /workspace || {
  echo "[ERROR] Cannot change directory to /workspace" >&2
  exit 1
}

tex_compile() {
  local tex="$1"
  echo "[INFO] Compiling: $tex"
  TEXINPUTS=./src//: LANG=ja_JP.UTF-8 LC_ALL=ja_JP.UTF-8 latexmk -pdfdvi "$tex"
  mkdir -p pdf
  cp "build/$(basename "$tex" .tex).pdf" pdf/ || echo "[WARN] Failed to copy PDF for $tex"
}

compile_all() {
  for tex in src/*.tex; do
    [ -f "$tex" ] && tex_compile "$tex"
  done
  echo "[INFO] Compilation finished. Watching for further changes..."
}

###############################
# 監視方式の自動選択
###############################
monitor_method="polling"
if command -v inotifywait >/dev/null 2>&1; then
  echo "[INFO] Checking inotify functionality on mounted directory..."
  testfile="src/.inotify_test_$$"
  inotifywait -qq -e create "src" --timeout 1 &
  pid=$!
  touch "$testfile"
  if wait $pid 2>/dev/null; then
    monitor_method="inotify"
    echo "[INFO] inotify events detected on mounted directory. Using inotify."
  else
    echo "[WARN] inotify events NOT detected on mounted directory. Falling back to polling."
  fi
  rm -f "$testfile"
fi

echo "[INFO] Using $monitor_method based monitoring"

###############################
# inotify 監視
###############################
if [[ "$monitor_method" == "inotify" ]]; then
  while inotifywait -qq -r -e modify,create,delete,move src/; do
    echo "[INFO] Change detected via inotify"
    compile_all
  done
  exit 0
fi

###############################
# ポーリング監視 (全環境対応)
###############################
declare -A file_times
for tex in src/*.tex; do
  [[ -f "$tex" ]] && file_times["$tex"]=$(stat -c %Y "$tex" 2>/dev/null || stat -f %m "$tex")
  echo "[INFO] Tracking: $tex"
done

while true; do
  changed=false
  for tex in src/*.tex; do
    if [[ -f "$tex" ]]; then
      current=$(stat -c %Y "$tex" 2>/dev/null || stat -f %m "$tex")
      if [[ "${file_times[$tex]:-}" != "$current" ]]; then
        changed=true
        file_times["$tex"]=$current
        echo "[INFO] Change detected in: $tex"
      fi
    fi
  done
  if $changed; then
    compile_all
  fi
done 

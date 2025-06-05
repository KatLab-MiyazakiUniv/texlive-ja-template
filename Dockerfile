FROM paperist/texlive-ja:latest

# 非対話的インストールのための環境変数
ENV DEBIAN_FRONTEND=noninteractive

# 必要なパッケージのインストール
RUN apt-get update && \
    apt-get install -y \
    latexmk \
    git \
    make \
    inotify-tools \
    procps \
    locales && \
    # ロケールの生成と設定
    sed -i -E 's/# (ja_JP.UTF-8)/\1/' /etc/locale.gen && \
    locale-gen && \
    # ロケールの設定
    update-locale LANG=ja_JP.UTF-8 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# TeXLive パッケージのインストール
RUN tlmgr update --self && \
    tlmgr install \
    algorithms \
    algorithmicx

# ロケール設定
ENV LANG=ja_JP.UTF-8
ENV LANGUAGE=ja_JP:ja
ENV LC_ALL=ja_JP.UTF-8

# 作業ディレクトリの設定
WORKDIR /workspace

# デフォルトコマンド
CMD ["bash"]

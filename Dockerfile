FROM paperist/texlive-ja:latest
# FROM ubuntu:25.10

# 非対話的インストールのための環境変数
ENV DEBIAN_FRONTEND=noninteractive

# 必要なパッケージのインストール
RUN apt-get update && \
    apt-get install -y \
    latexmk \
    git \
    make \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 作業ディレクトリの設定
WORKDIR /workspace

# デフォルトコマンド
CMD ["bash"]

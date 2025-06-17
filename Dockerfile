# Dockerfile
FROM ruby:3.2.1

# Node.jsとYarnのインストール (アセットパイプライン用)
RUN apt-get update -qq && \
    apt-get install -y build-essential libpq-dev nodejs npm && \
    npm install --global yarn

# MySQLクライアントライブラリのインストール
RUN apt-get install -y default-mysql-client

RUN apt-get update -qq && \
    apt-get install -y build-essential libpq-dev netcat-openbsd && \
    rm -rf /var/lib/apt/lists/*

# 作業ディレクトリの作成と設定
WORKDIR /myapp

# GemfileとGemfile.lockをコピーしてbundle install
COPY Gemfile /myapp/Gemfile
COPY Gemfile.lock /myapp/Gemfile.lock
RUN bundle install

# アプリケーションコードをコピー
COPY . /myapp

# エントリーポイントスクリプトの権限付与と実行
COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]

# ポート公開とサーバー起動
EXPOSE 3000
CMD ["bin/rails", "server", "-b", "0.0.0.0"]
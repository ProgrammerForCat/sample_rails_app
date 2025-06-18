#!/bin/bash

# EC2サーバーの初期セットアップスクリプト

echo "Starting server setup..."

# システムの更新
sudo apt update && sudo apt upgrade -y

# 必要なパッケージのインストール
sudo apt install -y curl git build-essential libssl-dev zlib1g-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev software-properties-common libffi-dev libgdbm-dev libncurses5-dev automake libtool bison libffi-dev

# Node.jsのインストール
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# MySQLクライアントのインストール
sudo apt install -y mysql-client

# rbenvのインストール
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
source ~/.bashrc

# ruby-buildのインストール
git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build

# Ruby 3.2.1のインストール
rbenv install 3.2.1
rbenv global 3.2.1

# Bundlerのインストール
gem install bundler

# Nginxのインストール
sudo apt install -y nginx

# アプリケーションディレクトリ構造の作成
sudo mkdir -p /var/www/sample_rails_app/{releases,shared,current}
sudo mkdir -p /var/www/sample_rails_app/shared/{log,tmp/{pids,sockets},config}
sudo chown -R ubuntu:ubuntu /var/www/sample_rails_app

# Unicornのsystemdサービスファイル作成
sudo tee /etc/systemd/system/unicorn.service > /dev/null <<EOF
[Unit]
Description=Unicorn application server
After=network.target

[Service]
Type=forking
User=ubuntu
WorkingDirectory=/var/www/sample_rails_app/current
Environment=RAILS_ENV=production
ExecStart=/usr/local/bin/bundle exec unicorn_rails -c /var/www/sample_rails_app/current/config/unicorn.rb -E production -D
ExecReload=/bin/kill -USR2 \$MAINPID
ExecStop=/bin/kill -QUIT \$MAINPID
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# systemdの再読み込み
sudo systemctl daemon-reload

# NginxとUnicornの有効化
sudo systemctl enable nginx
sudo systemctl enable unicorn

echo "Server setup completed!" 
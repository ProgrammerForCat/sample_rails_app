#!/bin/bash

# GitHub Actions用のEC2サーバーセットアップスクリプト

echo "Starting server setup for GitHub Actions deployment..."

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

# アプリケーションディレクトリの作成
sudo mkdir -p /var/www/sample_rails_app
sudo chown ubuntu:ubuntu /var/www/sample_rails_app

# Gitリポジトリのクローン（初回のみ）
cd /var/www/sample_rails_app
git clone https://github.com/yourusername/sample_rails_app.git .

# 共有ディレクトリの作成
sudo mkdir -p /var/www/sample_rails_app/shared

# 環境変数ファイルの作成（テンプレート）
sudo tee /var/www/sample_rails_app/shared/.env > /dev/null <<EOF
# Rails設定
RAILS_ENV=production
RAILS_MASTER_KEY=your_master_key_here

# データベース設定（RDS）
DATABASE_HOST=your-rds-endpoint.region.rds.amazonaws.com
DATABASE_USERNAME=sample_rails_app
DATABASE_PASSWORD=your_database_password
DATABASE_NAME=sample_rails_app_production
DATABASE_PORT=3306

# アプリケーション設定
RAILS_SERVE_STATIC_FILES=true
ALLOWED_HOSTS=your-domain.com,your-ec2-ip

# パフォーマンス設定
RAILS_MAX_THREADS=5
WEB_CONCURRENCY=3
EOF

# 環境変数ファイルの権限設定
sudo chown ubuntu:ubuntu /var/www/sample_rails_app/shared/.env
sudo chmod 600 /var/www/sample_rails_app/shared/.env

# 環境変数を読み込むための設定
echo 'source /var/www/sample_rails_app/shared/.env' >> ~/.bashrc

# Unicornのsystemdサービスファイル作成
sudo tee /etc/systemd/system/unicorn.service > /dev/null <<EOF
[Unit]
Description=Unicorn application server
After=network.target

[Service]
Type=forking
User=ubuntu
WorkingDirectory=/var/www/sample_rails_app
Environment=RAILS_ENV=production
EnvironmentFile=/var/www/sample_rails_app/shared/.env
ExecStart=/usr/local/bin/bundle exec unicorn_rails -c /var/www/sample_rails_app/config/unicorn.rb -E production -D
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

# Nginx設定ファイルの配置
sudo tee /etc/nginx/sites-available/sample_rails_app > /dev/null <<EOF
upstream unicorn {
  server unix:/var/www/sample_rails_app/tmp/sockets/unicorn.sock fail_timeout=0;
}

server {
  listen 80;
  server_name gl-service-test.net;

  root /var/www/sample_rails_app/public;

  location ^~ /assets/ {
    gzip_static on;
    expires max;
    add_header Cache-Control public;
  }

  try_files \$uri/index.html \$uri @unicorn;
  location @unicorn {
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header Host \$http_host;
    proxy_redirect off;
    proxy_pass http://unicorn;
  }

  error_page 500 502 503 504 /500.html;
  client_max_body_size 4G;
  keepalive_timeout 10;
}
EOF

# Nginx設定の有効化
sudo ln -s /etc/nginx/sites-available/sample_rails_app /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# 必要なディレクトリの作成
mkdir -p /var/www/sample_rails_app/tmp/sockets
mkdir -p /var/www/sample_rails_app/tmp/pids
mkdir -p /var/www/sample_rails_app/log

# 権限の設定
sudo chown -R ubuntu:ubuntu /var/www/sample_rails_app

# sudoersの設定（GitHub Actionsからのデプロイ用）
echo "ubuntu ALL=(ALL) NOPASSWD: /bin/systemctl restart unicorn" | sudo tee /etc/sudoers.d/unicorn
echo "ubuntu ALL=(ALL) NOPASSWD: /bin/systemctl restart nginx" | sudo tee /etc/sudoers.d/nginx

echo "Server setup completed for GitHub Actions deployment!"
echo ""
echo "Next steps:"
echo "1. Edit /var/www/sample_rails_app/shared/.env with your actual values"
echo "2. Set up GitHub Secrets in your repository"
echo "3. Push your code to trigger the first deployment" 
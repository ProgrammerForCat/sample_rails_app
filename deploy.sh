#!/bin/bash

# デプロイスクリプト
echo "Starting deployment..."

# 環境変数の設定
export RAILS_ENV=production
export RAILS_SERVE_STATIC_FILES=true

# アセットのプリコンパイル
echo "Precompiling assets..."
bundle exec rake assets:precompile

# データベースマイグレーション
echo "Running database migrations..."
bundle exec rake db:migrate

# Unicornの再起動
echo "Restarting Unicorn..."
sudo systemctl restart unicorn

# Nginxの再起動
echo "Restarting Nginx..."
sudo systemctl restart nginx

echo "Deployment completed!" 
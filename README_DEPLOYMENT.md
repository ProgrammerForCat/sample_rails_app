# AWS EC2 + RDS デプロイ手順

## 前提条件
- AWS EC2インスタンス（Ubuntu 20.04 LTS推奨）
- AWS RDS MySQLインスタンス
- ドメイン名（オプション）

## 1. EC2インスタンスの準備

### 1.1 セキュリティグループの設定
EC2インスタンスのセキュリティグループで以下のポートを開放：
- SSH (22)
- HTTP (80)
- HTTPS (443)

### 1.2 サーバーの初期セットアップ
```bash
# サーバーにSSH接続
ssh -i your-key.pem ubuntu@your-ec2-ip

# セットアップスクリプトを実行
chmod +x setup_server.sh
./setup_server.sh
```

## 2. RDSの設定

### 2.1 データベースの作成
RDSコンソールで以下の設定を行う：
- データベース名: `sample_rails_app_production`
- ユーザー名: `sample_rails_app`
- パスワード: 強力なパスワードを設定

### 2.2 セキュリティグループの設定
RDSのセキュリティグループでEC2インスタンスからのアクセスを許可：
- ポート: 3306
- ソース: EC2インスタンスのセキュリティグループ

## 3. アプリケーションのデプロイ

### 3.1 ローカルでの準備
```bash
# 必要なgemをインストール
bundle install

# マスターキーの生成（初回のみ）
rails credentials:edit

# Gitリポジトリにプッシュ
git add .
git commit -m "Add deployment configuration"
git push origin main
```

### 3.2 環境変数の設定
サーバー上で以下の環境変数を設定：
```bash
# /var/www/sample_rails_app/shared/.env ファイルを作成
sudo nano /var/www/sample_rails_app/shared/.env
```

以下の内容を追加：
```bash
RAILS_ENV=production
RAILS_MASTER_KEY=your_master_key_here
DATABASE_HOST=your-rds-endpoint.region.rds.amazonaws.com
DATABASE_USERNAME=sample_rails_app
DATABASE_PASSWORD=your_database_password
DATABASE_NAME=sample_rails_app_production
DATABASE_PORT=3306
RAILS_SERVE_STATIC_FILES=true
ALLOWED_HOSTS=your-domain.com,your-ec2-ip
```

### 3.3 Capistranoの設定
```bash
# config/deploy/production.rb を編集
# EC2インスタンスのIPアドレスとSSHキーのパスを設定

# 初回デプロイ
bundle exec cap production deploy:check
bundle exec cap production deploy
```

## 4. Nginxの設定

### 4.1 設定ファイルの配置
```bash
# nginx.conf をサーバーにコピー
sudo cp nginx.conf /etc/nginx/sites-available/sample_rails_app
sudo ln -s /etc/nginx/sites-available/sample_rails_app /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default
```

### 4.2 Nginxの再起動
```bash
sudo nginx -t
sudo systemctl restart nginx
```

## 5. SSL証明書の設定（オプション）

### 5.1 Let's Encryptのインストール
```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d your-domain.com
```

## 6. アプリケーションの起動

### 6.1 データベースのセットアップ
```bash
# サーバー上で実行
cd /var/www/sample_rails_app/current
bundle exec rake db:create
bundle exec rake db:migrate
bundle exec rake db:seed
```

### 6.2 サービスの起動
```bash
sudo systemctl start unicorn
sudo systemctl start nginx
```

## 7. 動作確認

ブラウザで以下のURLにアクセスしてアプリケーションが正常に動作することを確認：
- `http://your-ec2-ip` または
- `https://your-domain.com`

## トラブルシューティング

### ログの確認
```bash
# Unicornのログ
sudo journalctl -u unicorn -f

# Nginxのログ
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/access.log

# Railsのログ
tail -f /var/www/sample_rails_app/current/log/production.log
```

### よくある問題
1. **データベース接続エラー**: RDSのセキュリティグループ設定を確認
2. **権限エラー**: ファイルの所有者とパーミッションを確認
3. **静的ファイルが表示されない**: `RAILS_SERVE_STATIC_FILES=true` を設定

## 更新デプロイ

アプリケーションを更新する場合：
```bash
# ローカルで変更をコミット・プッシュ
git add .
git commit -m "Update application"
git push origin main

# デプロイ実行
bundle exec cap production deploy
``` 
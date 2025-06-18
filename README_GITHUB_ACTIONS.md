# GitHub Actions + AWS EC2 + RDS デプロイ手順

## 概要
GitHub Actionsを使用してRailsアプリケーションをAWS EC2とRDSに自動デプロイする手順です。

## 前提条件
- GitHubリポジトリ
- AWS EC2インスタンス（Ubuntu 20.04 LTS推奨）
- AWS RDS MySQLインスタンス
- SSHキーペア

## 1. GitHubリポジトリの準備

### 1.1 リポジトリの作成
```bash
# ローカルでGitリポジトリを初期化
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/yourusername/sample_rails_app.git
git push -u origin main
```

### 1.2 GitHub Secretsの設定
GitHubリポジトリの Settings > Secrets and variables > Actions で以下のシークレットを設定：

- `RAILS_MASTER_KEY`: Railsのマスターキー（`config/master.key`の内容）
- `EC2_HOST`: EC2インスタンスのパブリックIPアドレス
- `EC2_USERNAME`: EC2インスタンスのユーザー名（通常は`ubuntu`）
- `EC2_SSH_KEY`: EC2インスタンスのSSH秘密鍵の内容
- `EC2_PORT`: SSHポート（通常は`22`）

## 2. EC2インスタンスの準備

### 2.1 セキュリティグループの設定
EC2インスタンスのセキュリティグループで以下のポートを開放：
- SSH (22)
- HTTP (80)
- HTTPS (443)

### 2.2 サーバーの初期セットアップ
```bash
# サーバーにSSH接続
ssh -i your-key.pem ubuntu@your-ec2-ip

# セットアップスクリプトを実行
chmod +x setup_server_github_actions.sh
./setup_server_github_actions.sh
```

### 2.3 環境変数の設定
```bash
# 環境変数ファイルを編集
sudo nano /var/www/sample_rails_app/shared/.env
```

以下の内容を設定：
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

## 3. RDSの設定

### 3.1 データベースの作成
RDSコンソールで以下の設定を行う：
- データベース名: `sample_rails_app_production`
- ユーザー名: `sample_rails_app`
- パスワード: 強力なパスワードを設定

### 3.2 セキュリティグループの設定
RDSのセキュリティグループでEC2インスタンスからのアクセスを許可：
- ポート: 3306
- ソース: EC2インスタンスのセキュリティグループ

## 4. 初回デプロイ

### 4.1 データベースのセットアップ
```bash
# サーバー上で実行
cd /var/www/sample_rails_app
source shared/.env

# データベースの作成とマイグレーション
bundle exec rake db:create
bundle exec rake db:migrate
bundle exec rake db:seed
```

### 4.2 サービスの起動
```bash
sudo systemctl start nginx
sudo systemctl start unicorn
```

## 5. GitHub Actionsの動作確認

### 5.1 テストの実行
mainブランチにプッシュすると自動的にテストが実行されます：
```bash
git add .
git commit -m "Add GitHub Actions workflow"
git push origin main
```

### 5.2 デプロイの実行
テストが成功すると自動的にデプロイが実行されます。

## 6. デプロイの流れ

1. **コードプッシュ**: mainブランチにプッシュ
2. **テスト実行**: GitHub Actionsでテストを実行
3. **アセットプリコンパイル**: 本番用アセットを生成
4. **SSH接続**: EC2インスタンスにSSH接続
5. **コード更新**: `git pull`で最新コードを取得
6. **依存関係インストール**: `bundle install`を実行
7. **アセット更新**: アセットを再プリコンパイル
8. **マイグレーション**: データベースマイグレーションを実行
9. **サービス再起動**: UnicornとNginxを再起動

## 7. 手動デプロイ

GitHub Actionsのページから手動でデプロイを実行することも可能です：
1. GitHubリポジトリの Actions タブに移動
2. "Deploy to AWS EC2" ワークフローを選択
3. "Run workflow" ボタンをクリック

## 8. ログの確認

### 8.1 GitHub Actionsのログ
- GitHubリポジトリの Actions タブで確認

### 8.2 サーバーのログ
```bash
# Unicornのログ
sudo journalctl -u unicorn -f

# Nginxのログ
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/access.log

# Railsのログ
tail -f /var/www/sample_rails_app/log/production.log
```

## 9. トラブルシューティング

### 9.1 よくある問題

#### SSH接続エラー
- SSHキーの権限を確認: `chmod 600 your-key.pem`
- セキュリティグループでSSHポート(22)が開放されているか確認

#### データベース接続エラー
- RDSのエンドポイントが正しいか確認
- RDSのセキュリティグループ設定を確認
- データベースのユーザー名とパスワードが正しいか確認

#### 権限エラー
- ファイルの所有者を確認: `sudo chown -R ubuntu:ubuntu /var/www/sample_rails_app`
- sudoersの設定を確認

#### 静的ファイルが表示されない
- `RAILS_SERVE_STATIC_FILES=true` が設定されているか確認
- アセットが正しくプリコンパイルされているか確認

### 9.2 ロールバック
デプロイに問題がある場合：
```bash
# サーバー上で前のバージョンに戻す
cd /var/www/sample_rails_app
git log --oneline
git reset --hard <commit-hash>
sudo systemctl restart unicorn
```

## 10. セキュリティのベストプラクティス

1. **環境変数の管理**: 機密情報はGitHub Secretsで管理
2. **SSHキーの管理**: SSHキーは安全に保管し、定期的に更新
3. **ファイアウォール**: 必要最小限のポートのみ開放
4. **SSL証明書**: Let's EncryptでSSL証明書を設定
5. **ログローテーション**: ログファイルのサイズを管理

## 11. 監視とアラート

### 11.1 ヘルスチェック
```bash
# アプリケーションのヘルスチェック
curl -f http://your-domain.com/up
```

### 11.2 監視の設定
- CloudWatchでEC2インスタンスの監視
- RDSのパフォーマンス監視
- アプリケーションログの監視

## 12. 更新とメンテナンス

### 12.1 定期的な更新
```bash
# システムの更新
sudo apt update && sudo apt upgrade -y

# Rubyの更新（必要に応じて）
rbenv install 3.2.2
rbenv global 3.2.2
```

### 12.2 バックアップ
```bash
# データベースのバックアップ
mysqldump -h your-rds-endpoint -u sample_rails_app -p sample_rails_app_production > backup.sql

# アプリケーションファイルのバックアップ
tar -czf app_backup.tar.gz /var/www/sample_rails_app
``` 
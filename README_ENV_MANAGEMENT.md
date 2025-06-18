# .envファイル管理ガイド

## 概要
このプロジェクトでは、`/var/www/sample_rails_app/shared/.env`ファイルを使用して環境変数を管理しています。

## .envファイルの場所
- **本番環境**: `/var/www/sample_rails_app/shared/.env`
- **テンプレート**: `env.example`

## .envファイルの作成方法

### 1. 手動で作成する場合
```bash
# サーバーにSSH接続
ssh -i your-key.pem ubuntu@your-ec2-ip

# .envファイルを作成
sudo nano /var/www/sample_rails_app/shared/.env
```

以下の内容を追加：
```bash
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
```

### 2. デプロイ時に自動作成される場合
初回デプロイ時、`.env`ファイルが存在しない場合は自動的にテンプレートが作成されます。
その後、実際の値に更新する必要があります。

## デプロイ時の動作

### バックアップ
デプロイ時に既存の`.env`ファイルは自動的にバックアップされます：
- バックアップファイル名: `shared/.env.backup.YYYYMMDDHHMMSS`
- 最新の3つのバックアップが保持されます

### 復元
デプロイ後、最新のバックアップから`.env`ファイルが自動的に復元されます。

## 環境変数の説明

| 変数名 | 説明 | 例 |
|--------|------|-----|
| `RAILS_ENV` | Rails環境 | `production` |
| `RAILS_MASTER_KEY` | Railsマスターキー | `config/master.key`の内容 |
| `DATABASE_HOST` | データベースホスト | `your-rds-endpoint.region.rds.amazonaws.com` |
| `DATABASE_USERNAME` | データベースユーザー名 | `sample_rails_app` |
| `DATABASE_PASSWORD` | データベースパスワード | 強力なパスワード |
| `DATABASE_NAME` | データベース名 | `sample_rails_app_production` |
| `DATABASE_PORT` | データベースポート | `3306` |
| `RAILS_SERVE_STATIC_FILES` | 静的ファイル配信 | `true` |
| `ALLOWED_HOSTS` | 許可されたホスト | `your-domain.com,your-ec2-ip` |
| `RAILS_MAX_THREADS` | 最大スレッド数 | `5` |
| `WEB_CONCURRENCY` | Web並行性 | `3` |

## トラブルシューティング

### .envファイルが上書きされる問題
デプロイ時に`.env`ファイルが上書きされる場合：
1. バックアップが正しく作成されているか確認
2. デプロイログで復元処理を確認
3. 必要に応じて手動で復元

### 環境変数が読み込まれない問題
1. `.env`ファイルの権限を確認
2. アプリケーションの再起動
3. ログでエラーを確認

### バックアップの確認
```bash
# バックアップファイルの一覧
ls -la /var/www/sample_rails_app/shared/.env.backup.*

# 最新のバックアップを確認
ls -t /var/www/sample_rails_app/shared/.env.backup.* | head -1
```

## セキュリティのベストプラクティス

1. **権限設定**: `.env`ファイルの権限を600に設定
2. **バックアップ**: 定期的にバックアップを確認
3. **監査**: 環境変数の変更を記録
4. **暗号化**: 機密情報は暗号化して保存

## 手動バックアップの作成
```bash
# 現在の.envファイルをバックアップ
cp /var/www/sample_rails_app/shared/.env /var/www/sample_rails_app/shared/.env.backup.manual.$(date +%Y%m%d%H%M%S)
```

## 手動復元の実行
```bash
# 特定のバックアップから復元
cp /var/www/sample_rails_app/shared/.env.backup.YYYYMMDDHHMMSS /var/www/sample_rails_app/shared/.env

# アプリケーションの再起動
sudo systemctl restart unicorn
``` 
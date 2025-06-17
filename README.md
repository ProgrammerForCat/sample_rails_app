# 本の検索システム

Railsで作成した本の検索・管理システムです。

## 機能

- 本の一覧表示
- 本の検索（タイトルと著者で検索可能）
- 本の詳細表示
- 本の新規追加
- 本の情報編集
- 本の削除

## 技術スタック

- Ruby on Rails
- MySQL
- Docker
- Bootstrap

## セットアップ

1. リポジトリをクローン
```bash
git clone [リポジトリのURL]
cd sample_rails_app
```

2. Dockerコンテナの起動
```bash
docker-compose up -d
```

3. データベースのセットアップ
```bash
docker-compose exec web rails db:create
docker-compose exec web rails db:migrate
```

4. アプリケーションの起動
```bash
docker-compose exec web rails server -b '0.0.0.0'
```

5. ブラウザでアクセス
```
http://localhost:3000
```

## 開発環境

- Ruby 3.2.2
- Rails 7.0.8
- MySQL 8.0
- Docker

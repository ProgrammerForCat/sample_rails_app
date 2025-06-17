#!/bin/bash
set -e

# Remove a potentially pre-existing server.pid for Rails.
rm -f /myapp/tmp/pids/server.pid

# # データベースが存在しない場合のみ作成・マイグレーションする (初回起動時など)
# bundle exec rails db:prepare # db:create と db:migrate を実行

# もし `db:prepare` がうまく動作しない、またはより明示的に制御したい場合は以下のようにします。
echo "Waiting for DB to be ready..."
while ! nc -z db 3306; do
  sleep 0.1
done
echo "DB is ready!"

bundle exec rails db:create || echo "Database already exists or error creating"
bundle exec rails db:migrate || echo "Error migrating database"
# bundle exec rails db:seed # 必要であればシードデータも投入

# Then exec the container's main process (what's set as CMD in the Dockerfile).
exec "$@"
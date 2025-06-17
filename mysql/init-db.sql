CREATE DATABASE IF NOT EXISTS sample_rails_app_test;

-- 'rails_user' に全てのデータベースに対する全ての権限を付与します。
-- 'IDENTIFIED BY' 句は、既存のユーザーに権限を付与する際には不要です。
-- MYSQL_USER環境変数でユーザーが作成されていることを前提とします。
GRANT ALL PRIVILEGES ON *.* TO 'rails_user'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;

-- 再度テストデータベースの作成を試みる（念のため）
CREATE DATABASE IF NOT EXISTS sample_rails_app_test;

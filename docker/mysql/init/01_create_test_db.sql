-- MYSQL_USER には MYSQL_DATABASE の権限しか付かないため、RSpec用のテストDBの権限を追加で付与する
CREATE DATABASE IF NOT EXISTS naiken_test CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
GRANT ALL PRIVILEGES ON naiken_test.* TO 'naiken_user'@'%';
FLUSH PRIVILEGES;

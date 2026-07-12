-- ────────────────────────────────────────────────────────────
-- 石器时代 (StoneAge 2.5) SAAC 服务端数据库初始化脚本
--
-- 用法:
--   mysql -uroot -p < saac/sql/init_db.sql
--
-- 对应源码: saac/sasql.c  与  saac/acserv.cf
-- ────────────────────────────────────────────────────────────

-- 设置 root 密码 (若尚未设置, 或想改回 acserv.cf 中的密码)
-- Ubuntu 24.04 的 mysql-server 默认 root 使用 auth_socket 插件
-- (本机免密登录), 此处切换为 mysql_native_password 以匹配 saac 程序。
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'stoneage2025';
FLUSH PRIVILEGES;

-- 创建数据库 `sa`
CREATE DATABASE IF NOT EXISTS sa
  CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;

USE sa;

-- ────────────────────────────────────────────────────────────
-- 用户信息表 (对应 acserv.cf 中 sql_Table = user_table)
--   sasql.c 中:
--     sasql_query:   select * from user_table where Name=BINARY'<nm>'
--                    返回行的第 2 列(mysql_row[1]) 为密码
--     sasql_register: INSERT INTO user_table (Name, Pass, RegTime, Path)
--                     VALUES (BINARY'<id>','<ps>', NOW(), 'char/0x<hash>')
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS user_table (
  Name      VARCHAR(32)  CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  Pass      VARCHAR(32)  NOT NULL,
  RegTime   DATETIME     NULL DEFAULT NULL,
  Path      VARCHAR(64)  NULL DEFAULT NULL,
  PRIMARY KEY (Name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ────────────────────────────────────────────────────────────
-- 用户锁定表 (对应 acserv.cf 中 sql_LOCK = user_lock)
--   sasql.c 中:
--     sasql_chehk_lock: select * from user_lock where Name=BINARY'<idip>'
--     sasql_add_lock:  INSERT INTO user_lock (Name) VALUES (BINARY'<idip>')
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS user_lock (
  Name      VARCHAR(64)  CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  PRIMARY KEY (Name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ────────────────────────────────────────────────────────────
-- 可选: 预置一个测试账号 (账号: test, 密码: test)
-- ────────────────────────────────────────────────────────────
INSERT IGNORE INTO user_table (Name, Pass, RegTime, Path)
VALUES (BINARY'test', 'test', NOW(), 'char/0x0');

-- 验证
SHOW TABLES;
DESC user_table;
DESC user_lock;
SELECT * FROM user_table;

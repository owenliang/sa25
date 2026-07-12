# 石器时代 2.5 服务端 (StoneAge 2.5 Server)

石器时代 2.5 服务端源码,原为 32 位 Linux 环境编写,现已适配可在 64 位 Linux 上编译运行。

## 目录结构

```
stone-age/
├── gmsv/          # 游戏服务器 (Game Server)
│   ├── gmsvjt.exe # 编译产出的 32 位可执行文件
│   ├── setup.cf   # gmsv 配置文件
│   ├── makefile   # 主 makefile (递归编译 char/npc/map/item/battle/magic 子目录)
│   └── data/      # 地图、物品、NPC、宠物等静态数据
├── saac/          # 账号服务器 (Account Server)
│   ├── saacjt.exe # 编译产出的 32 位可执行文件
│   ├── acserv.cf  # saac 配置文件 (含 MySQL 连接信息)
│   ├── makefile
│   ├── sasql.c    # MySQL 数据库操作
│   └── sql/init_db.sql  # 数据库初始化脚本
└── start.sh       # 服务端启动/停止脚本
```

## 环境要求

- **OS**: 64 位 Linux (Ubuntu 24.04 测试通过)
- **编译器**: gcc 13+ (需 32 位交叉编译支持)
- **数据库**: MySQL 8.0+
- **32 位运行库**: `libc6-dev-i386`、`libmysqlclient-dev:i386`、`zlib1g-dev:i386`

### 安装依赖

```bash
apt-get install -y gcc-multilib libc6-dev-i386 \
    libmysqlclient-dev:i386 zlib1g-dev:i386 libssl-dev:i386 \
    mysql-server-8.0
```

## 编译

```bash
# 编译 gmsv (游戏服务器)
cd gmsv && make

# 编译 saac (账号服务器)
cd saac && make

# 清理
make clean
```

### 编译参数说明

makefile 中通过 `ARCHFLAGS` 变量实现 64 位环境下的 32 位编译:

| 参数 | 作用 |
|---|---|
| `-m32` | 生成 32 位 ELF,保留原代码对 int/指针大小的假设 |
| `-fcommon` | 恢复旧版 GCC 的 common 符号语义 (新版默认 `-fno-common` 导致多重定义错误) |
| `-fgnu89-inline` | 使用 gnu89 inline 语义,使 `INLINE` 函数生成外部符号 |
| `-U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=0` | 禁用 glibc fortify 检查 (原代码有 sprintf 小缓冲溢出) |
| `-no-pie` | 生成非 PIE 可执行文件,匹配原始 32 位构建 |

## 数据库初始化

```bash
mysql -uroot -p < saac/sql/init_db.sql
```

该脚本会:
- 设置 root 密码为 `Qq120848369` (与 `saac/acserv.cf` 一致)
- 创建数据库 `sa`
- 创建 `user_table` 表 (`Name`, `Pass`, `RegTime`, `Path`)
- 创建 `user_lock` 表 (`Name`)
- 预置测试账号 `test` / `test`

如需自定义数据库连接信息,修改 `saac/acserv.cf` 中的 `sql_IP`、`sql_Port`、`sql_ID`、`sql_PS`、`sql_DataBase` 等字段。

## 运行

### 方式一: 使用启动脚本

```bash
# 启动 saac 和 gmsv
./start.sh both

# 查看状态
./start.sh status

# 停止
./start.sh stop
```

### 方式二: 手动启动

```bash
# 1. 先启动 MySQL
systemctl start mysql

# 2. 启动 saac (账号服务器,监听 9300)
cd saac && ./saacjt.exe

# 3. 启动 gmsv (游戏服务器,监听 9065,需 saac 已启动)
cd gmsv && ./gmsvjt.exe
```

### 端口说明

| 服务 | 端口 | 说明 |
|---|---|---|
| saac | 9300 | 账号服务器,gmsv 连接此端口进行账号验证 |
| gmsv | 9065 | 游戏服务器,客户端连接此端口 |
| MySQL | 3306 | 数据库,saac 连接 |

### 启动顺序

**MySQL → saac → gmsv** (gmsv 启动时会连接 saac,若 saac 未启动则 gmsv 退出)

## 配置文件

### saac/acserv.cf

| 配置项 | 默认值 | 说明 |
|---|---|---|
| `sql_IP` | 127.0.0.1 | MySQL 地址 |
| `sql_Port` | 3306 | MySQL 端口 |
| `sql_ID` | root | MySQL 用户名 |
| `sql_PS` | Qq120848369 | MySQL 密码 |
| `sql_DataBase` | sa | 数据库名 |
| `sql_Table` | user_table | 用户信息表 |
| `sql_LOCK` | user_lock | 用户锁定表 |
| `AutoReg` | 1 | 开放自动注册 |
| `port` | 9300 | saac 监听端口 |

### gmsv/setup.cf

| 配置项 | 默认值 | 说明 |
|---|---|---|
| `port` | 9065 | gmsv 游戏端口 |
| `acservport` | 9300 | saac 端口 |
| `accountserver` | 127.0.0.1 | saac 地址 |
| `loginserver` | 极度1线 | 游戏服务器名称 |
| `mapdir` | ./data/map | 地图文件目录 |
| `itemfile` | ./data/itemset.txt | 物品配置文件 |
| `npcdir` | ./data/npc | NPC 配置目录 |

## 运行时数据目录

以下目录在程序运行时自动创建/写入,无需手动维护:

| 目录 | 用途 | 自动创建方式 |
|---|---|---|
| `saac/char/0x00-0xff/` | 玩家存档 | `prepareDirectories()` 自动 mkdir 256 个子目录 |
| `saac/log/0x00-0xff/` | 操作日志 | `prepareDirectories()` 自动 mkdir |
| `saac/mail/0x00-0xff/` | 宠物邮件 | `readMail()` 自动 mkdir,`mail_id` 自动重建 |
| `saac/data/family/` | 家族档案 | `readFamily()` 自动 mkdir |
| `saac/data/fmpointdir/` | 庄园据点配置 | `readFMPoint()` 自动 mkdir |
| `saac/data/fmsmemodir/` | 家族留言 | `readFMSMemo()` 自动 mkdir |
| `saac/db/int/` | 整型键值表 | `dbRead()` 自动 mkdir |
| `saac/db/string/` | 字符串键值表 | `dbRead()` 自动 mkdir |
| `gmsv/Schedule/` | 家族对战日程 | `NPC_SchedulemanInit()` 自动创建 |
| `gmsv/Dengon/` | 留言板 | `NPC_DengonInit()` 自动创建 |

> 注意: `saac/data/fmpointdir/db_fmpoint` 是庄园据点配置文件(非自动生成),已随仓库提供,不要删除。

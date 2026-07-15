# Gobang

五子棋对战平台，基于 Qt 6 / QML 开发，支持本地对战、人机对战（三档 AI 难度）和局域网联机对战。已完成 Android 平台适配。

## 功能特点

- 本地双人对战：两人在同一设备上轮流对弈
- 人机对战：三档 AI 难度可选（简单 / 一般 / 困难）
- 局域网联机对战：主机创建房间，客户端输入 IP 加入
- 两步落子交互：悬停预览 + 点击确认，防止误触
- 15 分钟包干计时：黑白双方各 15 分钟，超时判负
- 实时聊天：局域网对战模式下支持文字聊天
- 对战记录：自动保存每局对战记录（玩家、对手、胜负、步数、时间）
- Android 支持：已适配安卓设备，可直接安装运行

## 技术栈

| 技术 | 版本 | 用途 |
| --- | --- | --- |
| Qt | 6.x | 核心框架 |
| QML | 6.x | 用户界面渲染 |
| C++ | C++17 | 业务逻辑、网络通信、AI 算法 |
| SQLite | 3.x | 本地数据持久化 |
| Android NDK | r25+ | Android 平台编译与打包 |

## 项目结构

\`\`\`text
skloten_project/
├── CMakeLists.txt                # 主构建配置
├── main.cpp                      # 应用程序入口
├── core/                         # 核心游戏逻辑
│   ├── board.h / board.cpp       # 15x15 棋盘数据与胜负判定
│   ├── gomoku_engine.h / .cpp    # 游戏引擎（回合、计时、状态）
│   └── databasemanager.h / .cpp  # SQLite 数据库管理
├── ui/                           # 用户界面控制与 QML 资源
│   ├── game_controller.h / .cpp  # 总控制器（协调游戏、AI、网络）
│   └── qml/                      # QML 界面文件
│       ├── main.qml              # 应用主入口
│       ├── MainMenu.qml          # 主菜单
│       ├── GameView.qml          # 游戏视图
│       ├── HistoryView.qml       # 历史记录视图
│       └── BoardInputHandler.qml # 棋盘交互处理器
├── nerwork/                      # 网络通信模块
│   ├── network_player.h / .cpp   # 统一 TCP 通信类
│   ├── game_client.h / .cpp      # 旧版客户端（已废弃）
│   └── game_server.h / .cpp      # 旧版服务器（已废弃）
├── nfc_peer.h / .cpp             # NFC 通信模块（实验性）
├── android/                      # Android 平台资源
│   └── AndroidManifest.xml
├── image/                        # 图片资源
└── documents/                    # 文档及图标
\`\`\`

## 编译与运行

### 环境要求

- Qt 6.0 及以上
- CMake 3.16 及以上
- C++17 兼容编译器（MSVC 2019+ / GCC 11+ / Clang 14+）
- Android SDK / NDK（如需编译安卓版本）

## Android 端编译
打开 Qt Creator，配置 Android 套件（ARM64-v8a / armeabi-v7a）

将 android/ 目录下的 AndroidManifest.xml 复制到构建目录

点击构建并运行，连接 Android 设备即可安装 APK

如 Gradle 依赖下载失败，请手动下载离线 Gradle 版本，并在构建目录下的 gradle/wrapper/gradle-wrapper.properties 中配置本地路径。

## 使用说明
### 游戏模式
模式	说明
本地对战	双人轮流在同一设备上对弈
人机对战	三档难度可选：简单、一般、困难
局域网对战	主机创建房间，客户端输入 IP 加入
### AI 难度
难度	策略
简单	随机走棋
一般	基于方向评分 + 中心偏好 + 随机概率
困难	基于方向评分 + 中心偏好，选取最优走法
### 局域网联机步骤
主机点击「局域网对战」→「创建房间」，获取本机 IP 地址

客户端点击「局域网对战」→「加入房间」，输入主机 IP 地址

连接成功后自动开始对局，黑棋先走

### 核心模块
### GameController
唯一暴露给 QML 的控制类，协调游戏引擎、网络通信、数据库、AI 策略。

### QML 可调用方法：

placePiece(row, col)：落子

startHost(port)：启动局域网服务端

connectToServer(ip, port)：连接局域网服务端

sendChat(msg)：发送聊天消息

giveUp()：认输

requestRestart()：重新开始

getLocalIp()：获取本机局域网 IP

### NetworkPeer
统一网络通信类，合并了原 GameServer 和 GameClient。基于 TCP + JSON 协议：

消息格式：4 字节十六进制长度头 + JSON 体

支持指令：drop（落子）、chat（聊天）、giveup（认输）、gameover（结束）、restart（重启）

### DatabaseManager
基于 SQLite 的本地数据持久化：

用户名设置与读取

对战记录的保存与查询

记录清空

### NfcPeer（实验性）
基于 JNI 封装 Android NFC API，尝试通过 NFC 触碰建立连接。因 Android 10+ 已移除 Android Beam API，该功能未能实现，代码保留供后续研究。

#ifndef GAME_CONTROLLER_H
#define GAME_CONTROLLER_H

#include <QObject>
#include "../core/gomoku_engine.h"

class NetworkPeer;

class GameController : public QObject
{
    Q_OBJECT   // 启用 Qt 元对象特性，支持信号槽和属性系统

    // 暴露给 QML 的属性：当前轮到谁（0黑1白）
    Q_PROPERTY(int currentPlayer READ currentPlayer NOTIFY gameStateChanged)
    // 暴露给 QML 的属性：游戏是否结束
    Q_PROPERTY(bool gameOver READ isGameOver NOTIFY gameStateChanged)
    // 暴露给 QML 的属性：获胜者文本
    Q_PROPERTY(QString winnerText READ winnerText NOTIFY gameStateChanged)
    // 暴露给 QML 的属性：黑方剩余时间（秒）
    Q_PROPERTY(int blackTime READ blackTime NOTIFY gameStateChanged)
    // 暴露给 QML 的属性：白方剩余时间（秒）
    Q_PROPERTY(int whiteTime READ whiteTime NOTIFY gameStateChanged)
    // 暴露给 QML 的属性：网络状态提示字符串
    Q_PROPERTY(QString networkStatus READ networkStatus NOTIFY networkStatusChanged)
    // 暴露给 QML 的属性：聊天历史记录
    Q_PROPERTY(QString chatHistory READ chatHistory NOTIFY chatHistoryChanged)
    // 暴露的游戏步数
    Q_PROPERTY(int movesCount READ movesCount NOTIFY gameStateChanged)
public:
    // 游戏模式枚举：本地、AI、网络主机、网络客户端
    enum GameMode { LocalMode, AIMode, NetworkHostMode, NetworkClientMode };
    Q_ENUM(GameMode)

    // AI 难度枚举：简单、一般、困难
    enum AIDifficulty { Easy, Medium, Hard };
    Q_ENUM(AIDifficulty)

    // 构造函数，可指定父对象
    explicit GameController(QObject *parent = nullptr);
    // 析构函数，释放网络资源
    ~GameController();

    // ----- QML 可调用的公共方法 -----
    // 获取棋盘上指定位置（row, col）的棋子颜色（0空、1黑、2白）
    Q_INVOKABLE int pieceAt(int row, int col) const;
    // 尝试在（row, col）落子，会检查合法性及回合权限
    Q_INVOKABLE void placePiece(int row, int col);
    // 开始新游戏（重置引擎，清空棋盘，重置计时）
    Q_INVOKABLE void startGame();
    // 设置游戏模式（需传入 GameMode 枚举值）
    Q_INVOKABLE void setGameMode(int mode);
    // 设置 AI 难度（需传入 AIDifficulty 枚举值）
    Q_INVOKABLE void setAIDifficulty(int difficulty);

    // ----- 网络相关操作（由 QML 调用）-----
    // 作为主机启动网络服务，监听指定端口，返回是否成功
    Q_INVOKABLE bool startHost(quint16 port);
    // 作为客户端连接至指定 IP 和端口，返回是否成功
    Q_INVOKABLE bool connectToServer(const QString &ip, quint16 port);
    // 断开网络连接，清理资源，切换回本地模式
    Q_INVOKABLE void cancelNetwork();
    // 请求重新开始对局（网络模式下会发送重启消息给对方）
    Q_INVOKABLE void requestRestart();

    // ----- 聊天与认输 -----
    // 发送聊天消息（网络模式会发给对方，本地会记录）
    Q_INVOKABLE void sendChat(const QString &msg);
    // 认输（结束当前对局，并通知对方）
    Q_INVOKABLE void giveUp();

    // ----- 属性访问器（用于 Q_PROPERTY）-----
    int currentPlayer() const;   // 获取当前玩家（0黑/1白）
    bool isGameOver() const;     // 获取游戏是否结束
    QString winnerText() const;  // 获取获胜者描述文字
    int blackTime() const;       // 获取黑方剩余秒数
    int whiteTime() const;       // 获取白方剩余秒数
    QString networkStatus() const { return m_networkStatus; }  // 获取网络状态字符串
    QString chatHistory() const { return m_chatHistory; }      // 获取聊天记录
    int movesCount() const { return m_movesCount; } //访问游戏步数
signals:
    // 当游戏状态（回合、胜负、时间）变化时发射，QML 中绑定更新界面
    void gameStateChanged();
    // 当棋盘某位置落子时发射，参数：行、列、玩家颜色
    void boardChanged(int row, int col, int player);
    // 当网络状态变化时发射
    void networkStatusChanged();
    // 当聊天历史更新时发射
    void chatHistoryChanged();


    //开始加载允许下
    void lanGameStart();

private slots:
    // 引擎回合变化时的处理（触发 AI 走棋或界面更新）
    void onEngineTurnChanged();
    // 引擎游戏结束时的处理（网络模式下发送结果）
    void onEngineGameOverChanged();
    // 引擎棋盘变化时的处理（转发 boardChanged 信号）
    void onEngineBoardChanged(int row, int col, int player);
    // 引擎计时更新时的处理（发射 gameStateChanged 刷新时间显示）
    void onEngineTimeChanged();

    // ----- 网络对端事件的响应（由 NetworkPeer 信号触发）-----
    // 对端连接成功（主机收到客户端，或客户端连接上服务器）
    void onPeerConnected();
    // 对端断开连接
    void onPeerDisconnected();
    // 收到对端落子消息
    void onPeerMove(int row, int col);
    // 收到对端聊天消息
    void onPeerChat(const QString &name, const QString &msg);
    // 收到对端认输消息
    void onPeerGiveUp();
    // 收到对端重启请求
    void onPeerRestart();

private:
    // 游戏引擎实例（负责棋盘逻辑、胜负判定、计时）
    GameEngine m_engine;
    // 当前游戏模式（取 GameMode 枚举值）
    int m_gameMode;
    // 当前 AI 难度（取 AIDifficulty 枚举值）
    int m_aiDifficulty;
    // 网络状态显示字符串
    QString m_networkStatus;
    // 网络对等端对象（管理 TCP 连接，收发消息）
    NetworkPeer *m_peer;
    // 是否为网络主机（true=主机执黑，false=客户端执白）
    bool m_isHost;
    // 是否正在处理远程落子（防止递归，避免重复落子）
    bool m_processingRemote;
    // 聊天记录缓存
    QString m_chatHistory;
    //记录的游戏步数
    int m_movesCount = 0;

    // ----- 私有辅助函数 -----
    // 设置网络状态字符串并发射信号
    void setNetworkStatus(const QString &status);
    // 应用远端落子（直接调用引擎，不发送网络消息）
    void applyRemoteMove(int row, int col);
    // 追加聊天记录（本地显示）
    void appendChat(const QString &name, const QString &msg);
    // 触发 AI 走棋（根据当前难度）
    void aiMove();

    // ----- AI 走法生成函数 -----
    // 简单模式：随机走棋
    QPair<int, int> getAIMoveEasy();
    // 一般模式：基于简单评分 + 随机
    QPair<int, int> getAIMoveMedium();
    // 困难模式：基于评分选最优
    QPair<int, int> getAIMoveHard();
    // 评估在（row, col）放置某颜色棋子的价值分
    int evaluatePosition(int row, int col, int pieceColor) const;
};

#endif // GAME_CONTROLLER_H

// File: game_controller.h
// Created: YuHaoRan   1730822455@qq.com   2026-06-14 15:07:56
// Description:游戏控制类
// Module
// File: game_controller.h   Version: 0.1.0   License: AGPLv3
// Created: Yijunchen      2026-06-14 17:34:29
// Description:
//
#ifndef GAME_CONTROLLER_H
#define GAME_CONTROLLER_H

#include <QObject>
#include "../core/gomoku_engine.h"

class GameServer;
class GameClient;

class GameController : public QObject
{
    Q_OBJECT

    Q_PROPERTY(int currentPlayer READ currentPlayer NOTIFY gameStateChanged)
    Q_PROPERTY(bool gameOver READ isGameOver NOTIFY gameStateChanged)
    Q_PROPERTY(QString winnerText READ winnerText NOTIFY gameStateChanged)
    Q_PROPERTY(int blackTime READ blackTime NOTIFY gameStateChanged)
    Q_PROPERTY(int whiteTime READ whiteTime NOTIFY gameStateChanged)
    Q_PROPERTY(QString networkStatus READ networkStatus NOTIFY networkStatusChanged)
    Q_PROPERTY(QString chatHistory READ chatHistory NOTIFY chatHistoryChanged)

public:
    enum GameMode { LocalMode, AIMode, NetworkHostMode, NetworkClientMode };
    Q_ENUM(GameMode)

    enum AIDifficulty { Easy, Medium, Hard };
    Q_ENUM(AIDifficulty)

    explicit GameController(QObject *parent = nullptr);
    ~GameController();

    // QML 调用
    Q_INVOKABLE int pieceAt(int row, int col) const;
    Q_INVOKABLE void placePiece(int row, int col);
    Q_INVOKABLE void startGame();
    Q_INVOKABLE void setGameMode(int mode);
    Q_INVOKABLE void setAIDifficulty(int difficulty);

    // 网络相关
    Q_INVOKABLE bool startHost(quint16 port);
    Q_INVOKABLE bool connectToServer(const QString &ip, quint16 port);
    Q_INVOKABLE void cancelNetwork();

    // 聊天与认输
    Q_INVOKABLE void sendChat(const QString &msg);
    Q_INVOKABLE void giveUp();

    // 属性访问
    int currentPlayer() const;
    bool isGameOver() const;
    QString winnerText() const;
    int blackTime() const;
    int whiteTime() const;
    QString networkStatus() const { return m_networkStatus; }
    QString chatHistory() const { return m_chatHistory; }

    // 【新增】强制刷新棋盘（供 QML 调用）
    Q_INVOKABLE void refreshBoard();

signals:
    void gameStateChanged();
    void boardChanged(int row, int col, int player);
    void networkStatusChanged();
    void chatHistoryChanged();
    void boardRefreshNeeded();  // 【新增】强制刷新信号

private slots:
    void onEngineTurnChanged();
    void onEngineGameOverChanged();
    void onEngineBoardChanged(int row, int col, int player);
    void onEngineTimeChanged();

    // 服务器信号
    void onServerConnected();
    void onServerDisconnected();
    void onServerMove(int row, int col);
    void onServerGameOver(const QString &winner);
    void onServerChat(const QString &name, const QString &msg);
    void onServerGiveUp();

    // 客户端信号
    void onClientConnected();
    void onClientDisconnected();
    void onClientMove(int row, int col);
    void onClientGameOver(const QString &winner);
    void onClientChat(const QString &name, const QString &msg);
    void onClientGiveUp();

    void onNetworkError(const QString &msg);

private:
    GameEngine m_engine;
    int m_gameMode;
    int m_aiDifficulty;
    QString m_networkStatus;
    GameServer *m_server;
    GameClient *m_client;
    bool m_isHost;
    bool m_processingRemote;
    QString m_chatHistory;

    // 用于批量刷新
    QList<QPair<int, QPair<int, int>>> m_pendingMoves;

    void setNetworkStatus(const QString &status);
    void sendMoveToPeer(int row, int col);
    void sendGameOverToPeer(const QString &winner);
    void sendGiveUpToPeer();
    void applyRemoteMove(int row, int col);
    void appendChat(const QString &name, const QString &msg);
    void aiMove();

    // AI 决策函数
    QPair<int, int> getAIMoveEasy();
    QPair<int, int> getAIMoveMedium();
    QPair<int, int> getAIMoveHard();
    int evaluatePosition(int row, int col, int pieceColor) const;
    bool isNearPiece(int row, int col, int distance = 2) const;
};

#endif
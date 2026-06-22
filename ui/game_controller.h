
#ifndef GAME_CONTROLLER_H
#define GAME_CONTROLLER_H

#include <QObject>
#include "../core/gomoku_engine.h"

class NetworkPeer;

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
    Q_INVOKABLE void requestRestart();  // 供 QML 调用要求进行重启开始对局操作
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

signals:
    void gameStateChanged();
    void boardChanged(int row, int col, int player);
    void networkStatusChanged();
    void chatHistoryChanged();

private slots:
    void onEngineTurnChanged();
    void onEngineGameOverChanged();
    void onEngineBoardChanged(int row, int col, int player);
    void onEngineTimeChanged();

    //  onServerXxx / onClientXxx
    void onPeerConnected();
    void onPeerDisconnected();
    void onPeerMove(int row, int col);
    void onPeerChat(const QString &name, const QString &msg);
    void onPeerGiveUp();


     void onPeerRestart();  // 处理远程重启
private:
    GameEngine m_engine;
    int m_gameMode;
    int m_aiDifficulty;
    QString m_networkStatus;
    NetworkPeer *m_peer;          // 统一的网络对象
    bool m_isHost;
    bool m_processingRemote;
    QString m_chatHistory;

    void setNetworkStatus(const QString &status);
    void applyRemoteMove(int row, int col);
    void appendChat(const QString &name, const QString &msg);
    void aiMove();

    // AI 决策函数
    QPair<int, int> getAIMoveEasy();
    QPair<int, int> getAIMoveMedium();
    QPair<int, int> getAIMoveHard();
    int evaluatePosition(int row, int col, int pieceColor) const;
};

#endif // GAME_CONTROLLER_H
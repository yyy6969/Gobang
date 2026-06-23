#ifndef GAME_SERVER_H
#define GAME_SERVER_H

#include <QTcpServer>
#include <QTcpSocket>
#include <QObject>
#include <QJsonObject>

class GameServer : public QObject
{
    Q_OBJECT
public:
    explicit GameServer(QObject *parent = nullptr);
    ~GameServer();

    bool start(quint16 port);//创建套接字，然后对客户端进行监听操作
    void stop();

    // 发送各种指令
    void sendMove(int row, int col);
    void sendGameOver(const QString &winner);
    void sendChat(const QString &name, const QString &msg);
    void sendGiveUp();

signals:
    void clientConnected();
    void clientDisconnected();
    void moveReceived(int row, int col);
    void gameOverReceived(const QString &winner);
    void chatReceived(const QString &name, const QString &msg);
    void giveUpReceived();
    void errorOccurred(const QString &msg);

private slots:
    void onNewConnection();
    void onReadyRead();
    void onClientDisconnected();

private:
    QTcpServer *m_server;
    QTcpSocket *m_clientSocket;
    QByteArray m_buffer;          // 接收缓冲区，用于分包

    void sendMessage(const QJsonObject &obj);
    void parseMessage(const QByteArray &data);
};

#endif // GAME_SERVER_H
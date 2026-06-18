#ifndef GAME_CLIENT_H
#define GAME_CLIENT_H

#include <QTcpSocket>
#include <QObject>
#include <QJsonObject>

class GameClient : public QObject
{
    Q_OBJECT
public:
    explicit GameClient(QObject *parent = nullptr);
    ~GameClient();

    bool connectToServer(const QString &ip, quint16 port);
    void disconnect();

    void sendMove(int row, int col);
    void sendGameOver(const QString &winner);
    void sendChat(const QString &name, const QString &msg);
    void sendGiveUp();

signals:
    void connected();
    void disconnected();
    void moveReceived(int row, int col);
    void gameOverReceived(const QString &winner);
    void chatReceived(const QString &name, const QString &msg);
    void giveUpReceived();
    void errorOccurred(const QString &msg);

private slots:
    void onReadyRead();
    void onConnected();
    void onDisconnected();
    void onError(QAbstractSocket::SocketError error);

private:
    QTcpSocket *m_socket;
    QByteArray m_buffer;

    void sendMessage(const QJsonObject &obj);
    void parseMessage(const QByteArray &data);
};

#endif // GAME_CLIENT_H
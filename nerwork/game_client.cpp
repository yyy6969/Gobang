#include "game_client.h"
#include <QDataStream>
#include <QJsonDocument>
#include <QJsonObject>
#include <QDebug>

static QByteArray buildMessage(const QJsonObject &obj) {
    QByteArray json = QJsonDocument(obj).toJson(QJsonDocument::Compact);
    QByteArray len = QByteArray::number(json.size(), 16);
    while (len.size() < 4) len.prepend('0');
    return len + json;
}

GameClient::GameClient(QObject *parent)
    : QObject(parent), m_socket(nullptr)
{
}

GameClient::~GameClient()
{
    disconnect();
}

bool GameClient::connectToServer(const QString &ip, quint16 port)
{
    if (m_socket) return false;
    m_socket = new QTcpSocket(this);
    connect(m_socket, &QTcpSocket::connected, this, &GameClient::onConnected);
    connect(m_socket, &QTcpSocket::readyRead, this, &GameClient::onReadyRead);
    m_socket->connectToHost(ip, port);//进行输入然后连接操作
    return true;
}

void GameClient::disconnect()
{
    if (m_socket) {
        m_socket->disconnectFromHost();
        m_socket->deleteLater();
        m_socket = nullptr;
    }
    m_buffer.clear();
}

void GameClient::sendMessage(const QJsonObject &obj)
{
    if (!m_socket || m_socket->state() != QAbstractSocket::ConnectedState)
        return;
    m_socket->write(buildMessage(obj));
}

void GameClient::sendMove(int row, int col)
{
    QJsonObject obj;
    obj["cmd"] = "drop";
    obj["x"] = row;
    obj["y"] = col;
    sendMessage(obj);
}

void GameClient::sendGameOver(const QString &winner)
{
    QJsonObject obj;
    obj["cmd"] = "gameover";
    obj["winner"] = winner;
    sendMessage(obj);
}

void GameClient::sendChat(const QString &name, const QString &msg)
{
    QJsonObject obj;
    obj["cmd"] = "chat";
    obj["name"] = name;
    obj["msg"] = msg;
    sendMessage(obj);
}

void GameClient::sendGiveUp()
{
    QJsonObject obj;
    obj["cmd"] = "giveup";
    sendMessage(obj);
}

void GameClient::onConnected()
{
    emit connected();
}

void GameClient::onDisconnected()
{
    emit disconnected();
    disconnect(); // 清理资源
}

void GameClient::onError(QAbstractSocket::SocketError error)
{
    Q_UNUSED(error);
    if (m_socket)
        emit errorOccurred(m_socket->errorString());
}

void GameClient::onReadyRead()
{
    m_buffer.append(m_socket->readAll());
    while (m_buffer.size() >= 4) {
        bool ok;
        int len = m_buffer.left(4).toInt(&ok, 16);
        if (!ok || len <= 0) {
            m_buffer.remove(0, 1);
            continue;
        }
        if (m_buffer.size() < 4 + len) break;
        QByteArray jsonData = m_buffer.mid(4, len);
        m_buffer.remove(0, 4 + len);
        parseMessage(jsonData);
    }
}

void GameClient::parseMessage(const QByteArray &data)
{
    QJsonDocument doc = QJsonDocument::fromJson(data);
    if (!doc.isObject()) return;
    QJsonObject obj = doc.object();
    QString cmd = obj["cmd"].toString();

    if (cmd == "drop") {
        int row = obj["x"].toInt(-1);
        int col = obj["y"].toInt(-1);
        if (row >= 0 && col >= 0)
            emit moveReceived(row, col);
    } else if (cmd == "chat") {
        emit chatReceived(obj["name"].toString(), obj["msg"].toString());
    } else if (cmd == "giveup") {
        emit giveUpReceived();
    } else if (cmd == "gameover") {
        emit gameOverReceived(obj["winner"].toString());
    }
}
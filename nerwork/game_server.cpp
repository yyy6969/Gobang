#include "game_server.h"
#include <QDataStream>
#include <QJsonDocument>
#include <QJsonObject>
#include <QDebug>

static QByteArray buildMessage(const QJsonObject &obj) {
    QByteArray json = QJsonDocument(obj).toJson(QJsonDocument::Compact);
    QByteArray len = QByteArray::number(json.size(), 16); // 16进制长度头，补零至4字节
    while (len.size() < 4) len.prepend('0');
    return len + json;
}

GameServer::GameServer(QObject *parent)
    : QObject(parent), m_server(nullptr), m_clientSocket(nullptr)
{
}

GameServer::~GameServer()
{
    stop();
}

bool GameServer::start(quint16 port)
{

    if (m_server) return false;
    m_server = new QTcpServer(this);
    connect(m_server, &QTcpServer::newConnection, this, &GameServer::onNewConnection);
    if (!m_server->listen(QHostAddress::Any, port)) {
        emit errorOccurred("服务器启动失败: " + m_server->errorString());
        return false;
    }
    return true;
}

void GameServer::stop()
{
    if (m_clientSocket) {
        m_clientSocket->disconnectFromHost();
        m_clientSocket->deleteLater();
        m_clientSocket = nullptr;
    }
    if (m_server) {
        m_server->close();
        m_server->deleteLater();
        m_server = nullptr;
    }
    m_buffer.clear();
}

void GameServer::sendMessage(const QJsonObject &obj)
{
    if (!m_clientSocket || m_clientSocket->state() != QAbstractSocket::ConnectedState)
        return;
    m_clientSocket->write(buildMessage(obj));
}

void GameServer::sendMove(int row, int col)
{
    QJsonObject obj;
    obj["cmd"] = "drop";
    obj["x"] = row;
    obj["y"] = col;
    sendMessage(obj);
}

void GameServer::sendGameOver(const QString &winner)
{
    QJsonObject obj;
    obj["cmd"] = "gameover";
    obj["winner"] = winner;
    sendMessage(obj);
}

void GameServer::sendChat(const QString &name, const QString &msg)
{
    QJsonObject obj;
    obj["cmd"] = "chat";
    obj["name"] = name;
    obj["msg"] = msg;
    sendMessage(obj);
}

void GameServer::sendGiveUp()
{
    QJsonObject obj;
    obj["cmd"] = "giveup";
    sendMessage(obj);
}

void GameServer::onNewConnection()
{
    if (m_clientSocket) {
        // 已有客户端，拒绝新连接
        m_server->nextPendingConnection()->disconnectFromHost();
        return;
    }
    m_clientSocket = m_server->nextPendingConnection();
    connect(m_clientSocket, &QTcpSocket::readyRead, this, &GameServer::onReadyRead);
    connect(m_clientSocket, &QTcpSocket::disconnected, this, &GameServer::onClientDisconnected);
    connect(m_clientSocket, &QTcpSocket::errorOccurred, this, [this](QAbstractSocket::SocketError) {
        emit errorOccurred(m_clientSocket->errorString());
    });
    emit clientConnected();
}

void GameServer::onReadyRead()
{
    m_buffer.append(m_clientSocket->readAll());
    while (m_buffer.size() >= 4) {
        bool ok;
        int len = m_buffer.left(4).toInt(&ok, 16);
        if (!ok || len <= 0) {
            // 长度头非法，跳过1字节尝试恢复
            m_buffer.remove(0, 1);
            continue;
        }
        if (m_buffer.size() < 4 + len) break; // 数据不完整，等待
        QByteArray jsonData = m_buffer.mid(4, len);
        m_buffer.remove(0, 4 + len);
        parseMessage(jsonData);
    }
}

void GameServer::parseMessage(const QByteArray &data)
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
        QString name = obj["name"].toString();
        QString msg = obj["msg"].toString();
        emit chatReceived(name, msg);
    } else if (cmd == "giveup") {
        emit giveUpReceived();
    } else if (cmd == "gameover") {
        QString winner = obj["winner"].toString();
        emit gameOverReceived(winner);
    }
}

void GameServer::onClientDisconnected()
{
    if (m_clientSocket) {
        m_clientSocket->deleteLater();
        m_clientSocket = nullptr;
    }
    emit clientDisconnected();
}
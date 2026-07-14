#include "network_player.h"
#include <QJsonDocument>
#include <QDebug>

// 构建消息：4字节十六进制长度头 + JSON---用于转发操作的方式
QByteArray NetworkPeer::buildMessage(const QJsonObject &obj)
{
    QByteArray json = QJsonDocument(obj).toJson(QJsonDocument::Compact);
    QByteArray len = QByteArray::number(json.size(), 16);
    while (len.size() < 4) len.prepend('0');
    return len + json;
}

NetworkPeer::NetworkPeer(QObject *parent)
    : QObject(parent)
    , m_server(nullptr)
    , m_socket(nullptr)
    , m_isServer(false)
{
}

NetworkPeer::~NetworkPeer()
{
    disconnect();
}

bool NetworkPeer::startServer(quint16 port)
{
    if (m_server) return false;
    m_server = new QTcpServer(this);
    connect(m_server, &QTcpServer::newConnection, this, &NetworkPeer::onNewConnection);
    if (!m_server->listen(QHostAddress::Any, port)) {
        delete m_server;
        m_server = nullptr;
        return false;
    }
    m_isServer = true;
    return true;
}

bool NetworkPeer::connectToHost(const QString &ip, quint16 port)
{
    qDebug() << "[NetworkPeer] connectToHost called" << ip << port;
    if (m_socket) return false;
    m_socket = new QTcpSocket(this);
    connect(m_socket, &QTcpSocket::connected, this, &NetworkPeer::connected);
    connect(m_socket, &QTcpSocket::readyRead, this, &NetworkPeer::onReadyRead);
    connect(m_socket, &QTcpSocket::disconnected, this, &NetworkPeer::onSocketDisconnected);
    m_socket->connectToHost(ip, port);
    qDebug() << "[NetworkPeer] connectToHost called, waiting for connection";
    m_isServer = false;
    return true;
}

void NetworkPeer::disconnect()
{
    if (m_socket) {
        m_socket->disconnectFromHost();
        m_socket->deleteLater();
        m_socket = nullptr;
    }
    if (m_server) {
        m_server->close();
        m_server->deleteLater();
        m_server = nullptr;
    }
    m_buffer.clear();
    m_isServer = false;
}

void NetworkPeer::sendMessage(const QJsonObject &obj)
{
    qDebug() << "[NetworkPeer] sendMessage called, socket=" << m_socket
             << "state=" << (m_socket ? m_socket->state() : -1);
    if (!m_socket || m_socket->state() != QAbstractSocket::ConnectedState) {
        qDebug() << "[NetworkPeer] sendMessage failed: socket not connected";
        return;
    }
    m_socket->write(buildMessage(obj));
    qDebug() << "[NetworkPeer] Message sent";
}
void NetworkPeer::sendMove(int row, int col)
{
    QJsonObject obj;
    obj["cmd"] = "drop";
    obj["x"] = row;
    obj["y"] = col;
    sendMessage(obj);
}

void NetworkPeer::sendChat(const QString &name, const QString &msg)
{
    QJsonObject obj;
    obj["cmd"] = "chat";
    obj["name"] = name;
    obj["msg"] = msg;
    sendMessage(obj);
}

void NetworkPeer::sendGiveUp()
{
    QJsonObject obj;
    obj["cmd"] = "giveup";
    sendMessage(obj);
}

void NetworkPeer::sendGameOver(const QString &winner)
{
    QJsonObject obj;
    obj["cmd"] = "gameover";
    obj["winner"] = winner;
    sendMessage(obj);
}


void NetworkPeer::onNewConnection()
{
    qDebug() << "[NetworkPeer] onNewConnection called";
    if (m_socket) {
        qDebug() << "[NetworkPeer] Already have a socket, rejecting new connection";
        m_server->nextPendingConnection()->disconnectFromHost();
        return;
    }
    m_socket = m_server->nextPendingConnection();
    qDebug() << "[NetworkPeer] New socket accepted";
    connect(m_socket, &QTcpSocket::readyRead, this, &NetworkPeer::onReadyRead);
    connect(m_socket, &QTcpSocket::disconnected, this, &NetworkPeer::onSocketDisconnected);
    emit connected();
}

void NetworkPeer::onReadyRead()
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

void NetworkPeer::onSocketDisconnected()
{
    if (m_socket) {
        m_socket->deleteLater();
        m_socket = nullptr;
    }
    emit disconnected();
}

void NetworkPeer::parseMessage(const QByteArray &data)
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
    } else if (cmd == "restart") {
    emit restartReceived();
    }
}

void NetworkPeer::sendRestart()
{
    QJsonObject obj;
    obj["cmd"] = "restart";
    sendMessage(obj);
}
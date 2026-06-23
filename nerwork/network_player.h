// Module
// File: network_player.h   Version: 0.1.0   License: AGPLv3
// Created: 唐晟庆2024051604041   2026-06-22 17:26:00
// Description: 整合game_server以及game_server的操作，通过bool变量标识客户端或者服务端，减少冗余代码分析
//


#ifndef NETWORK_PEER_H
#define NETWORK_PEER_H

#include <QObject>
#include <QTcpServer>
#include <QTcpSocket>
#include <QJsonObject>
#include <QByteArray>

class NetworkPeer : public QObject
{
    Q_OBJECT

public:
    explicit NetworkPeer(QObject *parent = nullptr);
    ~NetworkPeer();

    // 启动服务器模式---监听客户端连接操作）
    bool startServer(quint16 port);
    // 连接至服务器（客户端模式）
    bool connectToHost(const QString &ip, quint16 port);
    // 断开连接并清理的操作
    void disconnect();

    // 发送操作
    void sendMove(int row, int col);
    void sendChat(const QString &name, const QString &msg);
    void sendGiveUp();
    void sendGameOver(const QString &winner);


    void sendRestart(); //重新开始后通知同步

signals:
    void connected(); // 连接成功（服务器角色收到客户端连接，客户端角色连接到服务器）
    void disconnected(); // 对方断开连接
    void moveReceived(int row, int col);
    void chatReceived(const QString &name, const QString &msg);
    void giveUpReceived();
    void gameOverReceived(const QString &winner);

    void restartReceived();

private slots:
    void onNewConnection();    // 服务器收到新连接
    void onReadyRead();        // 套接字可读
    void onSocketDisconnected(); // 套接字断开

private:
    QTcpServer *m_server;
    QTcpSocket *m_socket;
    QByteArray m_buffer;
    bool m_isServer;           // true: 服务器模式, false: 客户端模式--勇于判断作为哪个人

    void sendMessage(const QJsonObject &obj);
    void parseMessage(const QByteArray &data);
    QByteArray buildMessage(const QJsonObject &obj);
};

#endif // NETWORK_PEER_H
// Module: NFC 对等连接模块,-----------目前开发失败
// File: nfc_peer.h   Version: 1.0.0   License: AGPLv3
// Created: 唐晟庆2024051604041   2026-07-14 12:20:10
// Email: 2052448030@qq.com
// Description:
//    通过 NFC 进行设备间局域网连接操作。
//    主机（服务端）调用 startServer() 进入等待模式，
//    副机（客户端）调用 connectToTarget() 进行连接。
//    本模块基于 Android 原生 NFC API（通过 JNI 调用），
//    使用 enableReaderMode 强制前台应用获得 NFC 数据读取权，
//    绕过部分厂商（如 OPPO）系统对 NFC 事件的拦截。
//
//    1. 主机调用 startServer() → 创建 Java 辅助类 NfcReaderHelper
//       → 调用 NfcAdapter.enableReaderMode() 进入读卡器模式
//    2. 副机调用 connectToTarget() → 同样进入读卡器模式
//    3. 两部手机触碰 → 主机检测到 Tag → 通过 writeNdefMessage 写入握手消息
//    4. 副机检测到 Tag → 通过 readNdefMessages 读取消息 → 触发连接信号
//    5. 连接建立后，通过 Qt 信号槽机制通知上层（GameController）
//
// 注意：
//    - 本模块需要 Android 设备支持 NFC 功能
//    - 需在 AndroidManifest.xml 中声明 NFC 权限
//    - 当前实现基于 JNI 调用 Android 原生 API，不依赖 Qt NFC 模块
//
// 使用示例（在 GameController 中）：
//    m_nfcPeer = new NfcPeer(this);
//    connect(m_nfcPeer, &NfcPeer::connected, this, &GameController::onNfcConnected);
//    m_nfcPeer->startServer();  // 主机模式
//    // 或
//    m_nfcPeer->connectToTarget();  // 客户端模式

#ifndef NFC_PEER_H
#define NFC_PEER_H

#include <QObject>
#include <QByteArray>
#include <QJsonObject>
#include <QJniObject> // Qt6 使用 QJniObject

class NfcPeer : public QObject
{
    Q_OBJECT
public:
    // 构造函数，初始化 NFC 辅助对象
    explicit NfcPeer(QObject *parent = nullptr);

    // 析构函数，释放资源并断开连接
    ~NfcPeer();

    // 以主机模式启动 NFC 监听，等待对方触碰
    bool startServer();

    // 以客户端模式启动 NFC 监听（行为与 startServer 相同）
    bool connectToTarget();

    // 发送落子指令（行、列）
    void sendMove(int row, int col);

    // 发送聊天消息（发送者名称、消息内容）
    void sendChat(const QString &name, const QString &msg);

    // 发送认输指令
    void sendGiveUp();

    // 发送游戏结束通知（获胜者）
    void sendGameOver(const QString &winner);

    // 发送重新开始请求
    void sendRestart();

    // 断开 NFC 连接并停止监听
    void disconnect();

signals:
    // NFC 连接建立时发射
    void connected();

    // NFC 连接断开时发射
    void disconnected();

    // 收到对方落子时发射（行、列）
    void moveReceived(int row, int col);

    // 收到对方聊天消息时发射（发送者、消息内容）
    void chatReceived(const QString &name, const QString &msg);

    // 收到对方认输时发射
    void giveUpReceived();

    // 收到游戏结束通知时发射（获胜者）
    void gameOverReceived(const QString &winner);

    // 收到重新开始请求时发射
    void restartReceived();

    // 发生错误时发射（错误信息）
    void errorOccurred(const QString &message);

public slots:
    // JNI 回调：收到 NDEF 数据时调用
    void onNdefDataReceived(const QByteArray &data);

    // JNI 回调：NFC 连接成功时调用
    void onNfcConnected();

    // JNI 回调：NFC 连接断开时调用
    void onNfcDisconnected();

    // JNI 回调：NFC 发生错误时调用
    void onNfcError(const QString &message);

private:
    // 内部启用读卡器模式
    bool enableReaderModeInternal();

    // 创建或重建 Java 辅助对象
    void createHelper(bool isServer);

    // 防止 disconnect 重入死循环的标志
    bool m_disconnecting;

    // Java 辅助对象指针（JNI 调用用）
    QJniObject *m_helper;

    // 是否为主机模式
    bool m_isServer;

    // 是否已与对方建立连接
    bool m_isConnected;

    // 是否有待发送的数据
    bool m_hasPendingData;

    // 待发送的数据缓存
    QByteArray m_pendingData;

    // 发送 NDEF 消息（内部方法）
    void sendNdefMessage(const QByteArray &jsonData);

    // 处理接收到的数据（解析 JSON 并发射信号）
    void processReceivedData(const QByteArray &data);

    // 清除内部状态（连接标志、待发送数据等）
    void clearState();
};

#endif // NFC_PEER_H
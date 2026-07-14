#include "nfc_peer.h"
#include <QJsonDocument>
#include <QJniEnvironment>
#include <QDebug>

// ---------------------------- JNI 全局函数（由 Java 回调）----------------------------

extern "C" JNIEXPORT void JNICALL
Java_com_Gonbal_1My_1Game_NfcReaderHelper_onNdefDataReceived(
    JNIEnv *env, jobject thiz, jlong ptr, jbyteArray data)
{
    Q_UNUSED(thiz);
    NfcPeer *peer = reinterpret_cast<NfcPeer*>(ptr);
    if (!peer) return;

    jsize len = env->GetArrayLength(data);
    QByteArray bytes(len, Qt::Uninitialized);
    env->GetByteArrayRegion(data, 0, len, reinterpret_cast<jbyte*>(bytes.data()));
    peer->onNdefDataReceived(bytes);
}

extern "C" JNIEXPORT void JNICALL
Java_com_Gonbal_1My_1Game_NfcReaderHelper_onNfcConnectedNative(
    JNIEnv *env, jobject thiz, jlong ptr)
{
    Q_UNUSED(env);
    Q_UNUSED(thiz);
    NfcPeer *peer = reinterpret_cast<NfcPeer*>(ptr);
    if (!peer) return;
    peer->onNfcConnected();
}

extern "C" JNIEXPORT void JNICALL
Java_com_Gonbal_1My_1Game_NfcReaderHelper_onNfcDisconnectedNative(
    JNIEnv *env, jobject thiz, jlong ptr)
{
    Q_UNUSED(env);
    Q_UNUSED(thiz);
    NfcPeer *peer = reinterpret_cast<NfcPeer*>(ptr);
    if (!peer) return;
    peer->onNfcDisconnected();
}

extern "C" JNIEXPORT void JNICALL
Java_com_Gonbal_1My_1Game_NfcReaderHelper_onNfcErrorNative(
    JNIEnv *env, jobject thiz, jlong ptr, jstring message)
{
    Q_UNUSED(env);
    Q_UNUSED(thiz);
    NfcPeer *peer = reinterpret_cast<NfcPeer*>(ptr);
    if (!peer) return;
    const char *msg = env->GetStringUTFChars(message, nullptr);
    peer->onNfcError(QString::fromUtf8(msg));
    env->ReleaseStringUTFChars(message, msg);
}

// ---------------------------- NfcPeer 实现 ----------------------------

NfcPeer::NfcPeer(QObject *parent)
    : QObject(parent)
    , m_helper(nullptr)
    , m_isServer(false)
    , m_isConnected(false)
    , m_hasPendingData(false)
    , m_disconnecting(false)
{
}

NfcPeer::~NfcPeer()
{
    disconnect();
    delete m_helper;
}

void NfcPeer::createHelper(bool isServer)
{
    if (m_helper) {
        delete m_helper;
        m_helper = nullptr;
    }

#ifdef Q_OS_ANDROID
    QJniObject context = QJniObject::callStaticObjectMethod(
        "org/qtproject/qt/android/QtNative",
        "getContext",
        "()Landroid/content/Context;"
        );
    jobject contextObj = context.object<jobject>();
    if (!contextObj) {
        qWarning() << "Failed to get Context";
        return;
    }

    jlong ptr = reinterpret_cast<jlong>(this);
    m_helper = new QJniObject(
        "com/Gonbal_My_Game/NfcReaderHelper",
        "(JLandroid/content/Context;Z)V",
        ptr,
        contextObj,
        isServer
        );
    if (!m_helper->isValid()) {
        qWarning() << "Failed to create NfcReaderHelper Java object";
        delete m_helper;
        m_helper = nullptr;
    }
#else
    Q_UNUSED(isServer);
#endif
}

bool NfcPeer::enableReaderModeInternal()
{
    if (!m_helper || !m_helper->isValid()) {
        emit errorOccurred("NFC 辅助对象无效");
        return false;
    }
    m_hasPendingData = false;
    m_isConnected = false;

    bool success = m_helper->callMethod<jboolean>("enableReaderMode");
    if (!success) {
        emit errorOccurred("启动 NFC 读卡器失败");
        return false;
    }
    return true;
}

bool NfcPeer::startServer()
{
    m_isServer = true;
    createHelper(true);
    return enableReaderModeInternal();
}

bool NfcPeer::connectToTarget()
{
    m_isServer = false;
    createHelper(false);
    return enableReaderModeInternal();   // 直接调用，不调用 startServer()
}

void NfcPeer::sendMove(int row, int col)
{
    QJsonObject obj;
    obj["cmd"] = "drop";
    obj["x"] = row;
    obj["y"] = col;
    m_pendingData = QJsonDocument(obj).toJson(QJsonDocument::Compact);
    m_hasPendingData = true;
    if (m_isConnected) {
        sendNdefMessage(m_pendingData);
        m_hasPendingData = false;
    }
}

void NfcPeer::sendChat(const QString &name, const QString &msg)
{
    QJsonObject obj;
    obj["cmd"] = "chat";
    obj["name"] = name;
    obj["msg"] = msg;
    m_pendingData = QJsonDocument(obj).toJson(QJsonDocument::Compact);
    m_hasPendingData = true;
    if (m_isConnected) {
        sendNdefMessage(m_pendingData);
        m_hasPendingData = false;
    }
}

void NfcPeer::sendGiveUp()
{
    QJsonObject obj;
    obj["cmd"] = "giveup";
    m_pendingData = QJsonDocument(obj).toJson(QJsonDocument::Compact);
    m_hasPendingData = true;
    if (m_isConnected) {
        sendNdefMessage(m_pendingData);
        m_hasPendingData = false;
    }
}

void NfcPeer::sendGameOver(const QString &winner)
{
    QJsonObject obj;
    obj["cmd"] = "gameover";
    obj["winner"] = winner;
    m_pendingData = QJsonDocument(obj).toJson(QJsonDocument::Compact);
    m_hasPendingData = true;
    if (m_isConnected) {
        sendNdefMessage(m_pendingData);
        m_hasPendingData = false;
    }
}

void NfcPeer::sendRestart()
{
    QJsonObject obj;
    obj["cmd"] = "restart";
    m_pendingData = QJsonDocument(obj).toJson(QJsonDocument::Compact);
    m_hasPendingData = true;
    if (m_isConnected) {
        sendNdefMessage(m_pendingData);
        m_hasPendingData = false;
    }
}

void NfcPeer::disconnect()
{
    if (m_disconnecting) return;
    m_disconnecting = true;

    if (m_helper && m_helper->isValid()) {
        m_helper->callMethod<void>("disableReaderMode");
    }
    clearState();

    m_disconnecting = false;

}

void NfcPeer::onNdefDataReceived(const QByteArray &data)
{
    processReceivedData(data);
}

void NfcPeer::onNfcConnected()
{
    if (!m_isConnected) {
        m_isConnected = true;
        emit connected();
        if (m_hasPendingData) {
            sendNdefMessage(m_pendingData);
            m_hasPendingData = false;
        }
    }
}

void NfcPeer::onNfcDisconnected()
{
    clearState();
    emit disconnected();
}

void NfcPeer::onNfcError(const QString &message)
{
    emit errorOccurred(message);
    disconnect();
}

void NfcPeer::sendNdefMessage(const QByteArray &jsonData)
{
    if (!m_helper || !m_helper->isValid()) {
        emit errorOccurred("NFC 辅助对象无效");
        return;
    }

    QJniEnvironment env;
    JNIEnv* jniEnv = env.jniEnv();
    if (!jniEnv) {
        emit errorOccurred("获取 JNI 环境失败");
        return;
    }

    jbyteArray jData = jniEnv->NewByteArray(jsonData.size());
    jniEnv->SetByteArrayRegion(jData, 0, jsonData.size(),
                               reinterpret_cast<const jbyte*>(jsonData.constData()));

    // 调用 Java 的 setPushMessage，而非 writeNdefMessage
    m_helper->callMethod<void>("setPushMessage", "([B)V", jData);

    jniEnv->DeleteLocalRef(jData);


}

void NfcPeer::processReceivedData(const QByteArray &data)
{
    QJsonDocument doc = QJsonDocument::fromJson(data);
    if (!doc.isObject()) return;
    QJsonObject obj = doc.object();
    QString cmd = obj["cmd"].toString();

    if (!m_isConnected) {
        m_isConnected = true;
        emit connected();
    }

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
    } else if (cmd == "hello") {
        // 忽略握手消息
    }
}

void NfcPeer::clearState()
{
    m_isConnected = false;
    m_hasPendingData = false;
    m_pendingData.clear();
}
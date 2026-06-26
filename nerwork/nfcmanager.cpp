#include "nfcmanager.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkInterface>
#include <QDebug>
#include <QJniObject>
#include <QCoreApplication>

// JNI 注册函数
void NfcManager::registerNfcJni() {
    JNINativeMethod methods[] = {
        {"nativeOnNdefReceived", "(J[B)V", reinterpret_cast<void*>(NfcManager::onNdefReceived)}
    };
    QJniEnvironment env;
    jclass clazz = env->FindClass("com/NfcHelper");
    if (clazz) {
        env->RegisterNatives(clazz, methods, 1);
    }
}

NfcManager::NfcManager(QObject *parent)
    : QObject(parent)
    , m_isHost(false)
    , m_pendingPort(0)
{
    registerNfcJni();   // 注册 JNI 回调
}

NfcManager::~NfcManager()
{
    stopNfc();
}

QString NfcManager::getLocalIp() const
{
    for (const QNetworkInterface &iface : QNetworkInterface::allInterfaces()) {
        if (!(iface.flags() & QNetworkInterface::IsUp) ||
            (iface.flags() & QNetworkInterface::IsLoopBack))
            continue;
        for (const QNetworkAddressEntry &entry : iface.addressEntries()) {
            QHostAddress addr = entry.ip();
            if (addr.protocol() == QAbstractSocket::IPv4Protocol && !addr.isLoopback()) {
                return addr.toString();
            }
        }
    }
    return QString();
}

bool NfcManager::startNfc()
{
    qDebug() << "🔷 [MyApp] startNfc called";

    QJniObject activity = QJniObject::callStaticObjectMethod(
        "org/qtproject/qt/android/QtNative", "activity", "()Landroid/app/Activity;");

    // 注册 native 指针
    QJniObject::callStaticMethod<void>("com/NfcHelper",
                                       "setNativePtr", "(J)V",
                                       reinterpret_cast<jlong>(this));

    jboolean ok = QJniObject::callStaticMethod<jboolean>("com/NfcHelper",
                                                         "startReader",
                                                         "(Landroid/app/Activity;)Z",
                                                         activity.object());
    if (!ok) {
        emit errorOccurred("启动 NFC 读卡器失败");
        return false;
    }
    return true;
}

void NfcManager::stopNfc()
{
    QJniObject activity = QJniObject::callStaticObjectMethod(
        "org/qtproject/qt/android/QtNative", "activity", "()Landroid/app/Activity;");
    QJniObject::callStaticMethod<void>("com/NfcHelper",
                                       "stopReader",
                                       "(Landroid/app/Activity;)V",
                                       activity.object());
}

void NfcManager::sendHostInfo(const QString &ip, int port)
{
    qDebug() << "🔷 [MyApp] sendHostInfo" << ip << port;
    m_isHost = true;
    m_pendingIp = ip;
    m_pendingPort = port;

    QJsonObject obj;
    obj["ip"] = ip;
    obj["port"] = port;
    QByteArray json = QJsonDocument(obj).toJson(QJsonDocument::Compact);
    m_pendingPayload = json;   // 暂存

    QJniEnvironment env;
    jbyteArray jbytes = env->NewByteArray(json.size());
    env->SetByteArrayRegion(jbytes, 0, json.size(), reinterpret_cast<const jbyte*>(json.constData()));

    QJniObject::callStaticMethod<void>("com/NfcHelper",
                                       "setHostMode", "(Z[B)V",
                                       jboolean(true), jbytes);
    qDebug() << "🔷 [MyApp] Host mode set, waiting for client...";
}

// 静态 JNI 回调
void NfcManager::onNdefReceived(JNIEnv *env, jobject /*thiz*/, jlong ptr, jbyteArray payload)
{
    NfcManager *self = reinterpret_cast<NfcManager*>(ptr);
    if (!self) return;

    jsize len = env->GetArrayLength(payload);
    QByteArray data(len, Qt::Uninitialized);
    env->GetByteArrayRegion(payload, 0, len, reinterpret_cast<jbyte*>(data.data()));

    QJsonDocument doc = QJsonDocument::fromJson(data);
    if (!doc.isObject()) return;

    QJsonObject obj = doc.object();
    QString ip = obj["ip"].toString();
    int port = obj["port"].toInt(-1);
    if (!ip.isEmpty() && port > 0) {
        emit self->hostInfoReceived(ip, port);
    }
}

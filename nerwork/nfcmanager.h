//create by :唐晟庆2024051604041
//email: 2052448030@qq.com
//models: 改模块用于nfc相互连接,需要一部手机启动热点,,然后内置函数会获取本机的ip地址以及端口号通过nfc发送给另一部
//手机,通过这样的方式,进行局域网连接操作,
//create time : 2026-06-26 13:02:30
#ifndef NFCMANAGER_H
#define NFCMANAGER_H

#include <QObject>
#include <QJniObject>
#include <QByteArray>

class NfcManager : public QObject
{
    Q_OBJECT
public:
    explicit NfcManager(QObject *parent = nullptr);
    ~NfcManager();

    Q_INVOKABLE QString getLocalIp() const;
    Q_INVOKABLE bool startNfc();
    Q_INVOKABLE void stopNfc();
    Q_INVOKABLE void sendHostInfo(const QString &ip, int port);

signals:
    void hostInfoReceived(const QString &ip, int port);
    void errorOccurred(const QString &message);
    void targetDetected();   //

private:
    QJniObject m_androidNfcAdapter;   //
    bool m_isHost;
    QString m_pendingIp;
    int m_pendingPort;
    QByteArray m_pendingPayload;      // 用于暂存待发送的 JSON

    static void onNdefReceived(JNIEnv *env, jobject thiz, jlong ptr, jbyteArray payload);

    static void registerNfcJni();
};

#endif // NFCMANAGER_H

// create by :唐晟庆2024051604041
// email: 2052448030@qq.com
// models:
// create time : 2026-06-10 10:02:46
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QDebug>
#include <QTimer>
#include <QStandardPaths>
#include "ui/game_controller.h"
#include "core/databasemanager.h"
#include "nerwork/nfc_peer.h"

#ifdef Q_OS_ANDROID
#include <QJniObject>
#include <QtCore/private/qandroidextras_p.h>

static void onStoragePermissionResult(JNIEnv *env, jobject /*thiz*/, jintArray grantResults)
{
    jsize len = env->GetArrayLength(grantResults);
    if (len > 0) {
        jint *results = env->GetIntArrayElements(grantResults, nullptr);
        bool granted = (results[0] == 0); // 0 = PERMISSION_GRANTED
        env->ReleaseIntArrayElements(grantResults, results, 0);
        qDebug() << (granted ? "✅ 存储权限已授予" : "❌ 存储权限被拒绝，请到设置里手动开启");
    }


}

static void requestStoragePermissionJNI()
{
    QJniObject activity = QJniObject::callStaticObjectMethod(
        "org/qtproject/qt/android/QtNative",
        "activity",
        "()Landroid/app/Activity;"
        );
    if (!activity.isValid()) {
        qWarning("Activity is null, cannot request permission");
        return;
    }

    QJniEnvironment env;
    // 构建权限字符串数组
    jobjectArray permArray = env->NewObjectArray(
        1,
        env->FindClass("java/lang/String"),
        env->NewStringUTF("android.permission.WRITE_EXTERNAL_STORAGE")
        );


}


#endif

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    // 用私有目录，完全不申请权限
    qDebug() << "Data path:" << QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);

    GameController gameController;
    DatabaseManager dbmanager;
    NfcPeer nfcManager;

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("nfcManager", &nfcManager);
    engine.rootContext()->setContextProperty("game", &gameController);
    engine.rootContext()->setContextProperty("dbManager", &dbmanager);

    engine.load(QUrl("qrc:/ui/qml/main.qml"));
    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}

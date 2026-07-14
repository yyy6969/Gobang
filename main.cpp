// create by :唐晟庆2024051604041
// email: 2052448030@qq.com
// models:
// create time : 2026-06-10 10:02:46
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QDebug>
#include <QStandardPaths>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    // 用私有目录，完全不申请权限
    qDebug() << "Data path:" << QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);

    QQmlApplicationEngine engine;

    engine.load(QUrl("qrc:/ui/qml/main.qml"));
    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}

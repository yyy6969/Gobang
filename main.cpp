//create by :唐晟庆2024051604041
//email: 2052448030@qq.com
//models:
//create time : 2026-06-10 10:02:46
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "ui/game_controller.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    GameController gameController;
    QQmlApplicationEngine engine;

    engine.rootContext()->setContextProperty("game", &gameController);
    engine.load(QUrl("qrc:/ui/qml/main.qml"));

    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}
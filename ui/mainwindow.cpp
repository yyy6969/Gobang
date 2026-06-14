#include "mainwindow.h"
#include <QQuickWidget>
#include <QQmlContext>

MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent)
{
    m_gameEngine = new GameEngine(this);

    m_quickWidget = new QQuickWidget(this);
    m_quickWidget->setResizeMode(QQuickWidget::SizeRootObjectToView);
    m_quickWidget->rootContext()->setContextProperty("game", m_gameEngine);
    m_quickWidget->setSource(QUrl("../../ui/qml/GameView.qml"));



    m_gameEngine->startGame();  // 启动游戏

    setCentralWidget(m_quickWidget);
    setFixedSize(600, 650);   // 禁止缩放
    setWindowTitle("五子棋 - 人人对战");
}

MainWindow::~MainWindow(){}

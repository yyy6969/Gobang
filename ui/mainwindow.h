//create by :唐晟庆2024051604041
//email: 2052448030@qq.com
//models:主窗口,用于管理渲染的,分发操作输入逻辑等
//create time : 2026-06-10 11:28:32


#pragma once

#include <QMainWindow>
#include "../core/gomoku_engine.h"

class QQuickWidget;

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    explicit MainWindow(QWidget *parent = nullptr);
    ~MainWindow();

private:
    GameEngine *m_gameEngine;
    QQuickWidget *m_quickWidget;
};

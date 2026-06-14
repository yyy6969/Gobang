// File: game_controller.h
// Created: YuHaoRan   1730822455@qq.com   2026-06-14 15:07:56
// Description:游戏控制类
#ifndef GAME_CONTROLLER_H
#define GAME_CONTROLLER_H

#include <QObject>

class GameController : public QObject
{
    Q_OBJECT
public:
    explicit GameController(QObject *parent = nullptr) : QObject(parent) {}

    // 最小接口，让 QML 调用不报错
    Q_INVOKABLE void setGameMode(int) {}
    Q_INVOKABLE void startGame() {}
    Q_INVOKABLE int pieceAt(int, int) const { return 0; }
    Q_INVOKABLE void placePiece(int, int) {}
};

#endif
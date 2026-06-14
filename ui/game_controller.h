// File: game_controller.h
// Created: YuHaoRan   1730822455@qq.com   2026-06-14 15:07:56
// Description:游戏控制类
#ifndef GAME_CONTROLLER_H
#define GAME_CONTROLLER_H

#include <QObject>
#include "../core/gomoku_engine.h"
// 包含你的 GameEngine 头文件

class GameController : public QObject
{
    Q_OBJECT

    // 直接将 GameEngine 的属性暴露给 QML
    Q_PROPERTY(int currentPlayer READ currentPlayer NOTIFY gameStateChanged)
    Q_PROPERTY(bool gameOver READ isGameOver NOTIFY gameStateChanged)
    Q_PROPERTY(QString winnerText READ winnerText NOTIFY gameStateChanged)
    Q_PROPERTY(int blackTime READ blackTime NOTIFY gameStateChanged)
    Q_PROPERTY(int whiteTime READ whiteTime NOTIFY gameStateChanged)

public:
    explicit GameController(QObject *parent = nullptr);

    // 委托给 GameEngine
    Q_INVOKABLE int pieceAt(int row, int col) const;
    Q_INVOKABLE void placePiece(int row, int col);
    Q_INVOKABLE void startGame();
    Q_INVOKABLE void setGameMode(int mode);   // 预留，本地对战用 mode=0

    // 属性读取（直接调用 engine 的方法）
    int currentPlayer() const;
    bool isGameOver() const;
    QString winnerText() const;
    int blackTime() const;
    int whiteTime() const;

signals:
    void gameStateChanged();          // 当游戏状态（回合/结束/计时）变化时发射
    void boardChanged(int row, int col, int player);  // 落子信号

private slots:
    void onEngineTurnChanged();
    void onEngineGameOverChanged();
    void onEngineBoardChanged(int row, int col, int player);
    void onEngineTimeChanged();

private:
    GameEngine m_engine;   // 你的真实游戏引擎
    int m_gameMode;        // 0:本地,1:人机,2:局域网
};

#endif
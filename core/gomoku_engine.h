//create by :唐晟庆2024051604041
//email: 2052448030@qq.com
//models:   游戏的核心--检测状态,记录玩家剩余时间,计算游戏是否结束
//玩家循环落子操作逻辑
// QML 绑定 game.currentPlayer 显示当前回合

//  当 C++ 里回合切换时，调用 switchTurn() 改变 m_turn，然后发射 turnChanged() 信号

//     QML 收到 turnChanged 信号，自动重新读取 currentPlayer() 获取新值，更新 UI
// //create time : 2026-06-10 11:45:38

#pragma once

#include <QObject>
#include <QTimer>
#include "board.h"
#include<QDebug>
class GameEngine : public QObject
{
    Q_OBJECT


public:

    // 供 QML 查询棋子-----放在public区域!!!!!!!!!!!!不然qml访问不到会报错
    Q_INVOKABLE int pieceAt(int row, int col) const;
    // 当内部数据改变,通过发送信号,让qml读取道最新的信号数据,然后再进行更新渲染操作
    Q_PROPERTY(int currentPlayer READ currentPlayer NOTIFY turnChanged)
    Q_PROPERTY(int blackTime READ blackTime NOTIFY blackTimeChanged)
    Q_PROPERTY(int whiteTime READ whiteTime NOTIFY whiteTimeChanged)
    Q_PROPERTY(bool gameOver READ isGameOver NOTIFY gameOverChanged)
    Q_PROPERTY(QString winnerText READ winnerText NOTIFY gameOverChanged)





    explicit GameEngine(QObject *parent = nullptr);

    // 属性读取方法
    int currentPlayer() const;   // 0=黑，1=白
    int blackTime() const;       // 剩余秒数
    int whiteTime() const;
    bool isGameOver() const;
    QString winnerText() const;

    // QML 可调用的方法
    Q_INVOKABLE void startGame();
    Q_INVOKABLE void placePiece(int row, int col);

signals:
    //信号发送了,然后自动通过函数读取道最新的属性值
    void turnChanged();
    void blackTimeChanged();
    void whiteTimeChanged();
    void gameOverChanged();
    void boardChanged(int row, int col, int player); // 通知 UI 刷新

private slots:
    void onTimeout();

private:
    Board m_board;
    int m_turn;               // 0 或 1
    int m_times[2];           // 黑、白剩余时间（秒）
    QTimer m_timer;
    bool m_gameOver;
    QString m_winnerText;

    void switchTurn();
    void setGameOver(const QString &msg);
    void reset();
};

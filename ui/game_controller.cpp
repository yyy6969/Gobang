// File: game_controller.cpp
// Created: YuHaoRan   1730822455@qq.com   2026-06-14 15:28:20
// Description:游戏控制类，
#include "game_controller.h"
#include <QDebug>

GameController::GameController(QObject *parent)
    : QObject(parent)
    , m_gameMode(0)
{
    // 连接 GameEngine 的信号
    connect(&m_engine, &GameEngine::turnChanged, this, &GameController::onEngineTurnChanged);
    connect(&m_engine, &GameEngine::gameOverChanged, this, &GameController::onEngineGameOverChanged);
    connect(&m_engine, &GameEngine::boardChanged, this, &GameController::onEngineBoardChanged);
    connect(&m_engine, &GameEngine::blackTimeChanged, this, &GameController::onEngineTimeChanged);
    connect(&m_engine, &GameEngine::whiteTimeChanged, this, &GameController::onEngineTimeChanged);
}

int GameController::pieceAt(int row, int col) const
{
    // 直接使用 GameEngine 提供的 pieceAt 方法
    return m_engine.pieceAt(row, col);
}

void GameController::placePiece(int row, int col)
{
    if (m_engine.isGameOver()) return;

    // 本地模式：直接落子（引擎内部会处理合法性、胜负、切换回合）
    if (m_gameMode == 0) {
        m_engine.placePiece(row, col);
    }
    // 人机模式（仅当当前玩家是黑棋时允许落子，后续可扩展 AI）
    else if (m_gameMode == 1) {
        if (m_engine.currentPlayer() == 0) {
            m_engine.placePiece(row, col);
            // 落子后如果游戏未结束，可以在这里调用 AI 走一步（需要 AI 模块）
            // if (!m_engine.isGameOver()) m_engine.aiMove();
        }
    }
    // 局域网模式暂不实现
}

void GameController::startGame()
{
    m_engine.startGame();   // GameEngine::startGame 会重置棋盘、计时、回合
}

void GameController::setGameMode(int mode)
{
    m_gameMode = mode;
    qDebug() << "Game mode set to" << mode;
}

int GameController::currentPlayer() const
{
    return m_engine.currentPlayer();
}

bool GameController::isGameOver() const
{
    return m_engine.isGameOver();
}

QString GameController::winnerText() const
{
    return m_engine.winnerText();
}

int GameController::blackTime() const
{
    return m_engine.blackTime();
}

int GameController::whiteTime() const
{
    return m_engine.whiteTime();
}

// ---------- 槽函数 ----------
void GameController::onEngineTurnChanged()
{
    emit gameStateChanged();   // 回合变化，UI 需要更新（如提示当前玩家）
}

void GameController::onEngineGameOverChanged()
{
    emit gameStateChanged();   // 游戏结束，UI 显示遮罩
}

void GameController::onEngineBoardChanged(int row, int col, int player)
{
    emit boardChanged(row, col, player);   // 通知 QML 刷新棋子
}

void GameController::onEngineTimeChanged()
{
    emit gameStateChanged();   // 时间变化，UI 刷新计时显示
}

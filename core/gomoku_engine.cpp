#include "gomoku_engine.h"

GameEngine::GameEngine(QObject *parent)
    : QObject(parent),
    m_turn(0),
    m_gameOver(true)
{
    m_times[0] = 900; // 15分钟 = 900秒
    m_times[1] = 900;

    connect(&m_timer, &QTimer::timeout, this, &GameEngine::onTimeout);
}

int GameEngine::currentPlayer() const { return m_turn; }
int GameEngine::blackTime() const { return m_times[0]; }
int GameEngine::whiteTime() const { return m_times[1]; }
bool GameEngine::isGameOver() const { return m_gameOver; }
QString GameEngine::winnerText() const { return m_winnerText; }

void GameEngine::startGame()
{
    reset();
    m_gameOver = false;
    emit gameOverChanged();
    m_timer.start(1000); // 每秒 tick
}

void GameEngine::placePiece(int row, int col)
{
    if (m_gameOver) return;

    Board::Piece piece = (m_turn == 0) ? Board::Black : Board::White;

    if (!m_board.place(row, col, piece))
        return; // 非法落子，忽略

    // 通知 UI 刷新
    emit boardChanged(row, col, m_turn);

    // 检查胜负
    if (m_board.checkWin(row, col) == piece) {
        setGameOver(m_turn == 0 ? "黑方胜！" : "白方胜！");
        return;
    }

    // 切换回合
    switchTurn();
}

// 【新增】外部结束游戏
void GameEngine::endGame(const QString &msg)
{
    setGameOver(msg);
}

void GameEngine::switchTurn()
{
    m_turn = 1 - m_turn;
    emit turnChanged();
}

void GameEngine::onTimeout()
{
    if (m_gameOver) return;

    m_times[m_turn]--;
    if (m_turn == 0)
        emit blackTimeChanged();
    else
        emit whiteTimeChanged();

    if (m_times[m_turn] <= 0) {
        m_times[m_turn] = 0;
        setGameOver(m_turn == 0 ? "黑方超时，白方胜！" : "白方超时，黑方胜！");
    }
}

int GameEngine::pieceAt(int row, int col) const
{
    return m_board.pieceAt(row, col);
}

void GameEngine::setGameOver(const QString &msg)
{
    m_gameOver = true;
    m_winnerText = msg;
    m_timer.stop();
    emit gameOverChanged();
}

void GameEngine::reset()
{
    m_board.reset(); // 新棋盘
    m_turn = 0;
    m_times[0] = 900;
    m_times[1] = 900;
    m_winnerText.clear();
    m_timer.stop();

    qDebug() << "=== After reset ===";
    for (int r = 0; r < 3; ++r) {
        QString line;
        for (int c = 0; c < 3; ++c) {
            line += QString::number(m_board.get(r, c)) + " ";
        }
        qDebug() << line;
    }

    emit turnChanged();
    emit blackTimeChanged();
    emit whiteTimeChanged();
    emit gameOverChanged();
}
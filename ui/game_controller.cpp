#include "game_controller.h"
#include "../nerwork/game_server.h"
#include "../nerwork/game_client.h"
#include <QDebug>
#include <QRandomGenerator>
#include <QVector>
#include <algorithm>
#include <climits>
#include <QTimer>

static const int DIRS[4][2] = {{0,1}, {1,0}, {1,1}, {1,-1}};

GameController::GameController(QObject *parent)
    : QObject(parent)
    , m_gameMode(LocalMode)
    , m_aiDifficulty(Medium)
    , m_server(nullptr)
    , m_client(nullptr)
    , m_isHost(false)
    , m_processingRemote(false)
{
    connect(&m_engine, &GameEngine::turnChanged, this, &GameController::onEngineTurnChanged);
    connect(&m_engine, &GameEngine::gameOverChanged, this, &GameController::onEngineGameOverChanged);
    connect(&m_engine, &GameEngine::boardChanged, this, &GameController::onEngineBoardChanged);
    connect(&m_engine, &GameEngine::blackTimeChanged, this, &GameController::onEngineTimeChanged);
    connect(&m_engine, &GameEngine::whiteTimeChanged, this, &GameController::onEngineTimeChanged);
}

GameController::~GameController()
{
    if (m_server) m_server->stop();
    if (m_client) m_client->disconnect();
}

int GameController::pieceAt(int row, int col) const
{
    return m_engine.pieceAt(row, col);
}

void GameController::placePiece(int row, int col)
{
    if (m_engine.isGameOver()) return;
    if (m_processingRemote) return;

    bool canPlace = false;
    if (m_gameMode == LocalMode) {
        canPlace = true;
    } else if (m_gameMode == AIMode) {
        canPlace = (m_engine.currentPlayer() == 0);
    } else if (m_gameMode == NetworkHostMode || m_gameMode == NetworkClientMode) {
        bool myTurn = (m_isHost && m_engine.currentPlayer() == 0) ||
                      (!m_isHost && m_engine.currentPlayer() == 1);
        canPlace = myTurn;
    }

    if (!canPlace) return;

    m_engine.placePiece(row, col);

    if (m_gameMode == NetworkHostMode || m_gameMode == NetworkClientMode) {
        sendMoveToPeer(row, col);
    }
}

void GameController::startGame()
{
    m_engine.startGame();
    if (m_gameMode == NetworkHostMode || m_gameMode == NetworkClientMode) {
        setNetworkStatus("游戏中");
    }
}

void GameController::setGameMode(int mode)
{
    m_gameMode = mode;
    qDebug() << "Game mode set to" << mode;
}

void GameController::setAIDifficulty(int difficulty)
{
    m_aiDifficulty = difficulty;
    qDebug() << "AI difficulty set to" << difficulty;
}

bool GameController::startHost(quint16 port)
{
    if (m_server) return false;
    m_server = new GameServer(this);
    connect(m_server, &GameServer::clientConnected, this, &GameController::onServerConnected);
    connect(m_server, &GameServer::clientDisconnected, this, &GameController::onServerDisconnected);
    connect(m_server, &GameServer::moveReceived, this, &GameController::onServerMove);
    connect(m_server, &GameServer::gameOverReceived, this, &GameController::onServerGameOver);
    connect(m_server, &GameServer::chatReceived, this, &GameController::onServerChat);
    connect(m_server, &GameServer::giveUpReceived, this, &GameController::onServerGiveUp);
    connect(m_server, &GameServer::errorOccurred, this, &GameController::onNetworkError);

    if (!m_server->start(port)) return false;
    setNetworkStatus("等待客户端连接...");
    m_gameMode = NetworkHostMode;
    m_isHost = true;
    return true;
}

bool GameController::connectToServer(const QString &ip, quint16 port)
{
    if (m_client) return false;
    m_client = new GameClient(this);
    connect(m_client, &GameClient::connected, this, &GameController::onClientConnected);
    connect(m_client, &GameClient::disconnected, this, &GameController::onClientDisconnected);
    connect(m_client, &GameClient::moveReceived, this, &GameController::onClientMove);
    connect(m_client, &GameClient::gameOverReceived, this, &GameController::onClientGameOver);
    connect(m_client, &GameClient::chatReceived, this, &GameController::onClientChat);
    connect(m_client, &GameClient::giveUpReceived, this, &GameController::onClientGiveUp);
    connect(m_client, &GameClient::errorOccurred, this, &GameController::onNetworkError);

    if (!m_client->connectToServer(ip, port)) return false;
    setNetworkStatus("正在连接...");
    m_gameMode = NetworkClientMode;
    m_isHost = false;
    return true;
}

void GameController::cancelNetwork()
{
    if (m_server) { m_server->stop(); delete m_server; m_server = nullptr; }
    if (m_client) { m_client->disconnect(); delete m_client; m_client = nullptr; }
    setNetworkStatus("");
    m_gameMode = LocalMode;
    m_pendingMoves.clear();
}

void GameController::sendChat(const QString &msg)
{
    if (msg.trimmed().isEmpty()) return;
    QString name = m_isHost ? "主机" : "客户端";
    if (m_server) {
        m_server->sendChat(name, msg);
    } else if (m_client) {
        m_client->sendChat(name, msg);
    } else {
        return;
    }
    appendChat("我", msg);
}

// ========== giveUp 函数（只定义一次） ==========
void GameController::giveUp()
{
    if (m_engine.isGameOver()) return;

    if (m_gameMode == NetworkHostMode || m_gameMode == NetworkClientMode) {
        sendGiveUpToPeer();
        QString winner = m_isHost ? "白方" : "黑方";
        m_engine.endGame(winner + "（对方认输）");
    } else if (m_gameMode == AIMode) {
        m_engine.endGame("您认输了，AI 获胜！");
    } else if (m_gameMode == LocalMode) {
        // 本地模式：认输后结束游戏
        QString winner = m_engine.currentPlayer() == 0 ? "白方" : "黑方";
        m_engine.endGame(winner + "（认输）");
    }
}

void GameController::sendGiveUpToPeer()
{
    if (m_server) m_server->sendGiveUp();
    else if (m_client) m_client->sendGiveUp();
}

int GameController::currentPlayer() const { return m_engine.currentPlayer(); }
bool GameController::isGameOver() const { return m_engine.isGameOver(); }
QString GameController::winnerText() const { return m_engine.winnerText(); }
int GameController::blackTime() const { return m_engine.blackTime(); }
int GameController::whiteTime() const { return m_engine.whiteTime(); }

// 刷新棋盘
void GameController::refreshBoard()
{
    qDebug() << "Refresh board called";
    for (int row = 0; row < Board::SIZE; ++row) {
        for (int col = 0; col < Board::SIZE; ++col) {
            int piece = m_engine.pieceAt(row, col);
            if (piece != 0) {
                emit boardChanged(row, col, piece - 1);
            }
        }
    }
    emit boardRefreshNeeded();
}

void GameController::onEngineTurnChanged()
{
    emit gameStateChanged();
    if (m_gameMode == AIMode && !m_engine.isGameOver() && m_engine.currentPlayer() == 1) {
        aiMove();
    }
}

void GameController::onEngineGameOverChanged()
{
    emit gameStateChanged();
    if (m_engine.isGameOver() && (m_gameMode == NetworkHostMode || m_gameMode == NetworkClientMode)) {
        sendGameOverToPeer(m_engine.winnerText());
    }
}

void GameController::onEngineBoardChanged(int row, int col, int player)
{
    qDebug() << "Board changed at" << row << col << "player" << player;
    emit boardChanged(row, col, player);
}

void GameController::onEngineTimeChanged()
{
    emit gameStateChanged();
}

// ---- 网络槽函数 ----
void GameController::onServerConnected()
{
    setNetworkStatus("已连接，黑棋先走");
    startGame();
}

void GameController::onServerDisconnected()
{
    setNetworkStatus("对方断开连接");
    cancelNetwork();
}

void GameController::onServerMove(int row, int col)
{
    qDebug() << "Server received move:" << row << col;
    applyRemoteMove(row, col);
}

void GameController::onServerGameOver(const QString &winner)
{
    Q_UNUSED(winner);
}

void GameController::onServerChat(const QString &name, const QString &msg)
{
    appendChat(name, msg);
}

void GameController::onServerGiveUp()
{
    if (!m_engine.isGameOver()) {
        m_engine.endGame("对方认输，您获胜！");
    }
}

void GameController::onClientConnected()
{
    setNetworkStatus("已连接，您是白棋");
    startGame();
}

void GameController::onClientDisconnected()
{
    setNetworkStatus("服务器断开连接");
    cancelNetwork();
}

void GameController::onClientMove(int row, int col)
{
    qDebug() << "Client received move:" << row << col;
    applyRemoteMove(row, col);
}

void GameController::onClientGameOver(const QString &winner)
{
    Q_UNUSED(winner);
}

void GameController::onClientChat(const QString &name, const QString &msg)
{
    appendChat(name, msg);
}

void GameController::onClientGiveUp()
{
    if (!m_engine.isGameOver()) {
        m_engine.endGame("对方认输，您获胜！");
    }
}

void GameController::onNetworkError(const QString &msg)
{
    setNetworkStatus("网络错误: " + msg);
    cancelNetwork();
}

void GameController::setNetworkStatus(const QString &status)
{
    if (m_networkStatus == status) return;
    m_networkStatus = status;
    emit networkStatusChanged();
}

void GameController::appendChat(const QString &name, const QString &msg)
{
    m_chatHistory += QString("[%1] %2\n").arg(name, msg);
    emit chatHistoryChanged();
}

void GameController::sendMoveToPeer(int row, int col)
{
    if (m_server) m_server->sendMove(row, col);
    else if (m_client) m_client->sendMove(row, col);
}

void GameController::sendGameOverToPeer(const QString &winner)
{
    if (m_server) m_server->sendGameOver(winner);
    else if (m_client) m_client->sendGameOver(winner);
}

// 远程落子
void GameController::applyRemoteMove(int row, int col)
{
    if (m_engine.isGameOver()) return;
    if (m_processingRemote) return;
    if (m_engine.pieceAt(row, col) != 0) {
        qDebug() << "Position already occupied:" << row << col;
        return;
    }

    m_processingRemote = true;

    qDebug() << "Applying remote move at" << row << col;

    m_engine.placePiece(row, col);

    QTimer::singleShot(1, this, [this]() {
        refreshBoard();
        qDebug() << "Board refreshed after remote move";
    });

    m_processingRemote = false;
}

// ---- AI 函数 ----
void GameController::aiMove()
{
    static bool aiBusy = false;
    if (aiBusy || m_engine.isGameOver()) return;
    if (m_engine.currentPlayer() != 1) return;

    aiBusy = true;
    QPair<int, int> move;
    switch (m_aiDifficulty) {
    case Easy:   move = getAIMoveEasy();   break;
    case Medium: move = getAIMoveMedium(); break;
    case Hard:   move = getAIMoveHard();   break;
    default:     move = getAIMoveMedium(); break;
    }
    if (move.first != -1 && move.second != -1) {
        m_engine.placePiece(move.first, move.second);
    }
    aiBusy = false;
}

QPair<int, int> GameController::getAIMoveEasy()
{
    QVector<QPair<int,int>> empty;
    for (int i=0; i<Board::SIZE; ++i)
        for (int j=0; j<Board::SIZE; ++j)
            if (m_engine.pieceAt(i, j) == 0)
                empty.append(qMakePair(i,j));

    if (empty.isEmpty()) return qMakePair(-1,-1);
    int idx = QRandomGenerator::global()->bounded(empty.size());
    return empty[idx];
}

QPair<int, int> GameController::getAIMoveMedium()
{
    QVector<QPair<int,int>> moves;
    QVector<int> scores;
    int total = 0;

    for (int i=0; i<Board::SIZE; ++i) {
        for (int j=0; j<Board::SIZE; ++j) {
            if (m_engine.pieceAt(i,j) != 0) continue;
            moves.append(qMakePair(i,j));
            int score = evaluatePosition(i, j, Board::White)
                        + evaluatePosition(i, j, Board::Black);
            int center = Board::SIZE/2;
            int dist = abs(i-center) + abs(j-center);
            score += (Board::SIZE - dist) * 5;
            scores.append(score);
            total += score;
        }
    }

    if (moves.isEmpty()) return qMakePair(-1,-1);
    if (total <= 0) total = 1;

    int rand = QRandomGenerator::global()->bounded(total);
    int accum = 0;
    for (int i=0; i<moves.size(); ++i) {
        accum += scores[i];
        if (rand < accum) return moves[i];
    }
    return moves.last();
}

QPair<int, int> GameController::getAIMoveHard()
{
    int bestScore = -1;
    int bestRow = -1, bestCol = -1;
    for (int i=0; i<Board::SIZE; ++i) {
        for (int j=0; j<Board::SIZE; ++j) {
            if (m_engine.pieceAt(i,j) != 0) continue;
            int score = evaluatePosition(i, j, Board::White)
                        + evaluatePosition(i, j, Board::Black) * 2;
            int center = Board::SIZE/2;
            int dist = abs(i-center) + abs(j-center);
            score += (Board::SIZE - dist) * 8;
            if (score > bestScore) {
                bestScore = score;
                bestRow = i;
                bestCol = j;
            }
        }
    }
    if (bestRow != -1) return qMakePair(bestRow, bestCol);
    return getAIMoveEasy();
}

int GameController::evaluatePosition(int row, int col, int pieceColor) const
{
    int total = 0;
    for (auto &d : DIRS) {
        int count = 1;
        for (int step=1; step<=5; ++step) {
            int nr = row + d[0]*step, nc = col + d[1]*step;
            if (nr<0 || nr>=Board::SIZE || nc<0 || nc>=Board::SIZE) break;
            int p = m_engine.pieceAt(nr, nc);
            if (p == pieceColor) count++;
            else if (p == 0) break;
            else break;
        }
        for (int step=1; step<=5; ++step) {
            int nr = row - d[0]*step, nc = col - d[1]*step;
            if (nr<0 || nr>=Board::SIZE || nc<0 || nc>=Board::SIZE) break;
            int p = m_engine.pieceAt(nr, nc);
            if (p == pieceColor) count++;
            else if (p == 0) break;
            else break;
        }
        if (count >= 5) total += 1000000;
        else if (count == 4) total += 100000;
        else if (count == 3) total += 5000;
        else if (count == 2) total += 100;
        else if (count == 1) total += 1;
    }
    return total;
}

bool GameController::isNearPiece(int row, int col, int distance) const
{
    for (int i = -distance; i <= distance; ++i)
        for (int j = -distance; j <= distance; ++j) {
            int nr = row + i, nc = col + j;
            if (nr>=0 && nr<Board::SIZE && nc>=0 && nc<Board::SIZE)
                if (m_engine.pieceAt(nr, nc) != 0) return true;
        }
    return false;
}

#include "game_controller.h"
#include "../nerwork/network_player.h"
#include <QDebug>
#include <QRandomGenerator>
#include <QVector>
#include <QTimer>

static const int DIRS[4][2] = {{0,1}, {1,0}, {1,1}, {1,-1}};

GameController::GameController(QObject *parent)
    : QObject(parent)
    , m_gameMode(LocalMode)
    , m_aiDifficulty(Medium)
    , m_peer(nullptr)
    , m_nfcPeer(new NfcPeer(this))   // 初始化
    , m_isHost(false)
    , m_processingRemote(false)
    , m_movesCount(0)
{
    connect(&m_engine, &GameEngine::turnChanged, this, &GameController::onEngineTurnChanged);
    connect(&m_engine, &GameEngine::gameOverChanged, this, &GameController::onEngineGameOverChanged);
    connect(&m_engine, &GameEngine::boardChanged, this, &GameController::onEngineBoardChanged);
    connect(&m_engine, &GameEngine::blackTimeChanged, this, &GameController::onEngineTimeChanged);
    connect(&m_engine, &GameEngine::whiteTimeChanged, this, &GameController::onEngineTimeChanged);

    // 连接 NFC 信号
    connect(m_nfcPeer, &NfcPeer::connected, this, &GameController::onNfcConnected);
    connect(m_nfcPeer, &NfcPeer::disconnected, this, &GameController::onNfcDisconnected);
    connect(m_nfcPeer, &NfcPeer::moveReceived, this, &GameController::onNfcMove);
    connect(m_nfcPeer, &NfcPeer::chatReceived, this, &GameController::onNfcChat);
    connect(m_nfcPeer, &NfcPeer::giveUpReceived, this, &GameController::onNfcGiveUp);
    connect(m_nfcPeer, &NfcPeer::restartReceived, this, &GameController::onNfcRestart);
    connect(m_nfcPeer, &NfcPeer::errorOccurred, this, &GameController::onNfcError);
}

bool GameController::startNfcHost()
{
    qDebug() << "[GameController] startNfcHost called";
    if (m_nfcPeer->startServer()) {
        m_gameMode = NfcHostMode;
        m_isHost = true;
        setNetworkStatus("NFC 主机已启动，请对方靠近");
        emit gameStateChanged();
        return true;
    }
    return false;
}

bool GameController::connectNfcClient()
{
    qDebug() << "[GameController] connectNfcClient called";
    if (m_nfcPeer->connectToTarget()) {
        m_gameMode = NfcClientMode;
        m_isHost = false;
        setNetworkStatus("正在等待 NFC 连接...");
        emit gameStateChanged();
        return true;
    }
    return false;
}


GameController::~GameController()
{
    if (m_peer) {
        m_peer->disconnect();
        delete m_peer;
        m_peer = nullptr;
    }
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
    } else if (m_gameMode == NfcHostMode || m_gameMode == NfcClientMode) {
        // NFC 模式回合判断与网络模式一致
        bool myTurn = (m_isHost && m_engine.currentPlayer() == 0) ||
                      (!m_isHost && m_engine.currentPlayer() == 1);
        canPlace = myTurn;
    }

    if (!canPlace) return;

    m_engine.placePiece(row, col);
    m_movesCount++;

    // 发送给对端（只发送一次）
    if (m_gameMode == NetworkHostMode || m_gameMode == NetworkClientMode) {
        if (m_peer) m_peer->sendMove(row, col);
    } else if (m_gameMode == NfcHostMode || m_gameMode == NfcClientMode) {
        if (m_nfcPeer) m_nfcPeer->sendMove(row, col);
    }

}

void GameController::startGame()
{
    m_engine.startGame();
    m_movesCount = 0;   // 重置步数
    if (m_gameMode == NetworkHostMode || m_gameMode == NetworkClientMode) {
        setNetworkStatus("游戏中");
    }
}

void GameController::setGameMode(int mode)
{
    m_gameMode = mode;
}

void GameController::setAIDifficulty(int difficulty)
{
    m_aiDifficulty = difficulty;
}

bool GameController::startHost(quint16 port)
{
    // 如果已有连接，先彻底清理
    if (m_peer) {
        m_peer->disconnect();
        delete m_peer;
        m_peer = nullptr;
    }
    m_peer = new NetworkPeer(this);
    // 连接统一信号
    connect(m_peer, &NetworkPeer::connected, this, &GameController::onPeerConnected);
    connect(m_peer, &NetworkPeer::disconnected, this, &GameController::onPeerDisconnected);
    connect(m_peer, &NetworkPeer::moveReceived, this, &GameController::onPeerMove);
    connect(m_peer, &NetworkPeer::chatReceived, this, &GameController::onPeerChat);
    connect(m_peer, &NetworkPeer::giveUpReceived, this, &GameController::onPeerGiveUp);
    connect(m_peer, &NetworkPeer::restartReceived, this, &GameController::onPeerRestart);
    // 本地引擎处理游戏是否结束操作

    if (!m_peer->startServer(port)) {
        delete m_peer;
        m_peer = nullptr;
        return false;
    }
    setNetworkStatus("等待客户端连接...");
    m_gameMode = NetworkHostMode;
    m_isHost = true;
    return true;
}


void GameController::onPeerRestart()
{
    // 重置游戏引擎
    m_engine.startGame();
    // 更新网络状态（可根据角色设置提示）
    if (m_isHost)
        setNetworkStatus("已重新开始，黑棋先走");
    else
        setNetworkStatus("已重新开始，您是白棋");
}


void GameController::requestRestart()
{
    if (m_gameMode == NetworkHostMode || m_gameMode == NetworkClientMode) {
        if (m_peer) m_peer->sendRestart();
    } else if (m_gameMode == NfcHostMode || m_gameMode == NfcClientMode) {
        if (m_nfcPeer) m_nfcPeer->sendRestart();  // 加上检查
    }
    // 本地立即重置
    m_engine.startGame();
    if (m_isHost)
        setNetworkStatus("已重新开始，黑棋先走");
    else
        setNetworkStatus("已重新开始，您是白棋");
}




void GameController::onNfcConnected()
{
    setNetworkStatus(m_isHost ? "NFC 已连接，黑棋先走" : "NFC 已连接，您是白棋");
    startGame();
}

void GameController::onNfcDisconnected()
{
    setNetworkStatus("NFC 连接断开");
    cancelNetwork();
}

void GameController::onNfcMove(int row, int col)
{
    applyRemoteMove(row, col);
}

void GameController::onNfcChat(const QString &name, const QString &msg)
{
    appendChat(name, msg);
}

void GameController::onNfcGiveUp()
{
    if (!m_engine.isGameOver()) {
        m_engine.endGame("对方认输，您获胜！");
    }
}

void GameController::onNfcRestart()
{
    m_engine.startGame();
    setNetworkStatus("对方请求重新开始");
}

void GameController::onNfcError(const QString &message)
{
    setNetworkStatus("NFC 错误：" + message);
    cancelNetwork();  // cancelNetwork 内部已包含 m_nfcPeer->disconnect()
}

bool GameController::connectToServer(const QString &ip, quint16 port)
{
    if (m_peer) return false;
    m_peer = new NetworkPeer(this);
    connect(m_peer, &NetworkPeer::connected, this, &GameController::onPeerConnected);
    connect(m_peer, &NetworkPeer::disconnected, this, &GameController::onPeerDisconnected);
    connect(m_peer, &NetworkPeer::moveReceived, this, &GameController::onPeerMove);
    connect(m_peer, &NetworkPeer::chatReceived, this, &GameController::onPeerChat);
    connect(m_peer, &NetworkPeer::giveUpReceived, this, &GameController::onPeerGiveUp);

     connect(m_peer, &NetworkPeer::restartReceived, this, &GameController::onPeerRestart);

    if (!m_peer->connectToHost(ip, port)) {
        delete m_peer;
        m_peer = nullptr;
        return false;
    }
    setNetworkStatus("正在连接...");
    m_gameMode = NetworkClientMode;
    m_isHost = false;
    return true;
}

void GameController::cancelNetwork()
{
    // 先断开 NFC 信号的连接，防止循环
    if (m_nfcPeer) {
        m_nfcPeer->disconnect();   // 断开所有连接到 NfcPeer 的槽
    }

    if (m_peer) {
        m_peer->disconnect();
        delete m_peer;
        m_peer = nullptr;
    }
    if (m_nfcPeer) {
        m_nfcPeer->disconnect();   // 调用 disconnect() 但信号已断开，不会触发槽
    }
    setNetworkStatus("");
    m_gameMode = LocalMode;
    m_isHost = false;
}

void GameController::sendChat(const QString &msg)
{
    if (msg.trimmed().isEmpty()) return;
    QString name = m_isHost ? "主机" : "客户端";
    if (m_gameMode == NetworkHostMode || m_gameMode == NetworkClientMode) {
        if (m_peer) m_peer->sendChat(name, msg);
    } else if (m_gameMode == NfcHostMode || m_gameMode == NfcClientMode) {
        if (m_nfcPeer) m_nfcPeer->sendChat(name, msg);
    } else {
        // 本地模式，不发送，只记录
        appendChat("我", msg);
        return;
    }
    appendChat("我", msg);
}

void GameController::giveUp()
{
    if (m_engine.isGameOver()) return;

    if (m_gameMode == NetworkHostMode || m_gameMode == NetworkClientMode) {
        if (m_peer) m_peer->sendGiveUp();
        QString winner = m_isHost ? "白方" : "黑方";
        m_engine.endGame(winner + "（对方认输）");
    } else if (m_gameMode == NfcHostMode || m_gameMode == NfcClientMode) {
        if (m_nfcPeer) m_nfcPeer->sendGiveUp();
        QString winner = m_isHost ? "白方" : "黑方";
        m_engine.endGame(winner + "（对方认输）");
    } else if (m_gameMode == AIMode) {
        m_engine.endGame("您认输了，AI 获胜！");
    } else if (m_gameMode == LocalMode) {
        QString winner = m_engine.currentPlayer() == 0 ? "白方" : "黑方";
        m_engine.endGame(winner + "（认输）");
    }
}

int GameController::currentPlayer() const { return m_engine.currentPlayer(); }
bool GameController::isGameOver() const { return m_engine.isGameOver(); }
QString GameController::winnerText() const { return m_engine.winnerText(); }
int GameController::blackTime() const { return m_engine.blackTime(); }
int GameController::whiteTime() const { return m_engine.whiteTime(); }


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
    if (m_engine.isGameOver()) {
        if (m_gameMode == NetworkHostMode || m_gameMode == NetworkClientMode) {
            if (m_peer) m_peer->sendGameOver(m_engine.winnerText());
        } else if (m_gameMode == NfcHostMode || m_gameMode == NfcClientMode) {
            if (m_nfcPeer) m_nfcPeer->sendGameOver(m_engine.winnerText());
        }
    }
}
void GameController::onEngineBoardChanged(int row, int col, int player)
{
    emit boardChanged(row, col, player);
}

void GameController::onEngineTimeChanged()
{
    emit gameStateChanged();
}

// ---- 统一的网络槽 ----辨识下角色身份操作
void GameController::onPeerConnected()
{
    if (m_isHost)
        setNetworkStatus("已连接，黑棋先走");
    else
        setNetworkStatus("已连接，您是白棋");
    startGame();
}

void GameController::onPeerDisconnected()
{
    setNetworkStatus(m_isHost ? "客户端断开连接" : "服务器断开连接");
    cancelNetwork(); // 返回到本地端
}

void GameController::onPeerMove(int row, int col)
{
    applyRemoteMove(row, col);
}

void GameController::onPeerChat(const QString &name, const QString &msg)
{
    appendChat(name, msg);
}

void GameController::onPeerGiveUp()
{
    if (!m_engine.isGameOver()) {
        m_engine.endGame("对方认输，您获胜！");
    }
}

// ---- 网络辅助函数 ----
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

void GameController::applyRemoteMove(int row, int col)
{
    if (m_engine.isGameOver()) return;
    if (m_processingRemote) return;

    m_processingRemote = true;
    m_engine.placePiece(row, col);
    m_movesCount++;
    m_processingRemote = false;
    // 发出 boardChanged 信号-----通知更新期盼
}

// ---- AI 函数
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
        m_movesCount++;
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

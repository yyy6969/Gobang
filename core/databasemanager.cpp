#include "databasemanager.h"
#include <QStandardPaths>
#include <QDir>
#include <QSqlError>
#include <QDebug>

DatabaseManager::DatabaseManager(QObject *parent) : QObject(parent)
{
    // 数据库文件路径：AppDataLocation 在 Android 上对应 /data/data/包名/files
    QString dbPath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation)
                     + QDir::separator() + "gobang.db";

    // 确保目录存在
    QDir dir(QStandardPaths::writableLocation(QStandardPaths::AppDataLocation));
    if (!dir.exists())
        dir.mkpath(".");

    m_db = QSqlDatabase::addDatabase("QSQLITE");
    m_db.setDatabaseName(dbPath);

    if (!m_db.open()) {
        qWarning() << "Failed to open database:" << m_db.lastError().text();
        return;
    }

    // 创建表
    if (!createTables()) {
        qWarning() << "Failed to create tables";
    }
}

DatabaseManager::~DatabaseManager()
{
    if (m_db.isOpen())
        m_db.close();
}

bool DatabaseManager::createTables()
{
    QSqlQuery query(m_db);

    // settings 表,目前记录名字
    QString createSettings = R"(
        CREATE TABLE IF NOT EXISTS settings (
            key TEXT PRIMARY KEY,
            value TEXT
        )
    )";
    if (!query.exec(createSettings)) {
        qWarning() << "Create settings table failed:" << query.lastError().text();
        return false;
    }

    // game_records 表
    QString createRecords = R"(
        CREATE TABLE IF NOT EXISTS game_records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            player_name TEXT,
            opponent_name TEXT,
            winner TEXT,
            moves_count INTEGER,
            game_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    )";
    if (!query.exec(createRecords)) {
        qWarning() << "Create game_records table failed:" << query.lastError().text();
        return false;
    }

    return true;
}

//用户名字
bool DatabaseManager::setUserName(const QString &name)
{
    qDebug() << "setUserName called with:" << name;
    QSqlQuery query(m_db);
    query.prepare("INSERT OR REPLACE INTO settings (key, value) VALUES ('user_name', :name)");
    query.bindValue(":name", name);
    if (!query.exec()) {
        qWarning() << "setUserName failed:" << query.lastError().text();
        return false;
    }
    return true;
}

QString DatabaseManager::getUserName() const
{
    qDebug() << "getUserName called";
    QSqlQuery query(m_db);
    query.prepare("SELECT value FROM settings WHERE key = 'user_name'");
    if (query.exec() && query.next()) {
        return query.value(0).toString();
    }
    return QString(); // 返回空表示未设置
}

// 保存记录

bool DatabaseManager::saveGameRecord(const QString &playerName,
                                     const QString &opponentName,
                                     const QString &winner,
                                     int movesCount)
{
    // 防重：使用静态变量缓存最近一次保存的玩家对和时间戳
    static QString lastPlayer;
    static QString lastOpponent;
    static qint64 lastTimestamp = 0; // 秒级时间戳

    qint64 now = QDateTime::currentSecsSinceEpoch();

    // 如果 10 秒内相同玩家对，直接跳过（防止重复插入）
    if (lastPlayer == playerName && lastOpponent == opponentName &&
        (now - lastTimestamp) < 10) {
        qDebug() << "Duplicate record ignored (same players within 10s)";
        return true; // 不插入，但返回成功
    }

    // 更新缓存
    lastPlayer = playerName;
    lastOpponent = opponentName;
    lastTimestamp = now;

    // 执行插入
    QSqlQuery query(m_db);
    query.prepare(R"(
        INSERT INTO game_records (player_name, opponent_name, winner, moves_count)
        VALUES (:player, :opponent, :winner, :moves)
    )");
    query.bindValue(":player", playerName);
    query.bindValue(":opponent", opponentName);
    query.bindValue(":winner", winner);
    query.bindValue(":moves", movesCount);

    if (!query.exec()) {
        qWarning() << "saveGameRecord failed:" << query.lastError().text();
        return false;
    }
    return true;
}

// 查询所有记录
QVariantList DatabaseManager::getAllRecords() const
{
    QVariantList records;
    QSqlQuery query(m_db);
    query.exec("SELECT id, player_name, opponent_name, winner, moves_count, game_time "
               "FROM game_records ORDER BY game_time DESC");

    while (query.next()) {
        QVariantMap map;
        map["id"] = query.value("id").toInt();
        map["playerName"] = query.value("player_name").toString();
        map["opponentName"] = query.value("opponent_name").toString();
        map["winner"] = query.value("winner").toString();
        map["movesCount"] = query.value("moves_count").toInt();
        QDateTime dt = query.value("game_time").toDateTime();
        dt = dt.toLocalTime();   // UTC → 本地时间
        map["gameTime"] = dt.toString("yyyy-MM-dd hh:mm:ss");
        records.append(map);
    }
    return records;
}

// 清空记录(后续实现)
bool DatabaseManager::clearAllRecords()
{
    QSqlQuery query(m_db);
    if (!query.exec("DELETE FROM game_records")) {
        qWarning() << "clearAllRecords failed:" << query.lastError().text();
        return false;
    }
    return true;
}
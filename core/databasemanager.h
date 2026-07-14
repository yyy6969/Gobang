#pragma once
// File: databasemanager.h
// Created: YuHaoRan   1730822455@qq.com   2026-06-26 00:26:51
// Description:数据库模块，使用Sqlite分布式存储，本地存储
#include <QObject>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QVariantList>
#include <QDateTime>
#include <QtQml>

class DatabaseManager: public QObject
{
    Q_OBJECT
    QML_ELEMENT

public:
    DatabaseManager(QObject *parent = nullptr);
    ~DatabaseManager();
    // 初始化数据库（创建表）
    bool initialize();
    //用户自定义名字
    Q_INVOKABLE bool setUserName(const QString &name);
    Q_INVOKABLE QString getUserName() const;
    //保存一局游戏记录
    Q_INVOKABLE bool saveGameRecord(const QString &playerName,
                                    const QString &opponentName,
                                    const QString &winner,
                                    int movesCount);
    // 查询所有历史记录（按时间降序），返回 QVariantList，每个元素是 QVariantMap
    Q_INVOKABLE QVariantList getAllRecords() const;
    // 清空所有记录
    Q_INVOKABLE bool clearAllRecords();

private:
    QSqlDatabase m_db;
    bool createTables();
};

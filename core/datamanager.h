#pragma once

#include <QObject>
#include<sqlite3.h>
#include <QVariantList>
class DataManager : public QObject
{
    Q_OBJECT
public:
    explicit DataManager(QObject *parent = nullptr);
    ~DataManager();
    Q_INVOKABLE bool initDataBase();
    void saveGameResult(const QString play1,QString );
signals:
};

//create by :唐晟庆2024051604041
//email: 2052448030@qq.com
//models:一个 15×15 的二维数组
// bool place(row, col, piece)：在指定位置落子，返回是否合法

//     Piece get(row, col)：查询某位置棋子

//     Piece checkWin(row, col)：从最新落子位置检查是否五连

//     一个供 QML 调用的 Q_INVOKABLE int pieceAt(row, col) 方法（返回 0/1/2）

//     胜负判定逻辑：在 checkWin 里对横、竖、两个对角线四个方向计数，连续相同颜色达到 5 即胜。

//create time : 2026-06-10 11:39:30


#pragma once

#include <QObject>
#include <array>

class Board : public QObject
{
    Q_OBJECT

public:
    // 棋子类型
    enum Piece {
        Empty = 0,
        Black = 1,
        White = 2
    };
    Q_ENUM(Piece)  // QML 中用字符串映射

    static const int SIZE = 15;

    explicit Board(QObject *parent = nullptr);

    void reset();

    // 尝试在 (row, col) 放置 piece，合法返回 true
    Q_INVOKABLE bool place(int row, int col, Piece piece);

    // 获取 (row, col) 位置的棋子
    Q_INVOKABLE Piece get(int row, int col) const;

    // 检查从 (row, col) 出发是否产生五连，返回胜方（Empty 表示无）
    Q_INVOKABLE Piece checkWin(int row, int col) const;

    // 供 QML 快速查询（返回 0/1/2）
    Q_INVOKABLE int pieceAt(int row, int col) const;

private:
    std::array<std::array<Piece, SIZE>, SIZE> m_grid;//棋盘   -- 棋盘里面的空格属于标识符号

    bool inBounds(int row, int col) const; //check是VS在15*15内
};

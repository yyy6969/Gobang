
#include "board.h"

Board::Board(QObject *parent)
    : QObject(parent)
{
    // 初始化棋盘全空
    for (int r = 0; r < SIZE; ++r)
        for (int c = 0; c < SIZE; ++c)
            m_grid[r][c] = Empty;
}

bool Board::place(int row, int col, Piece piece)
{
    if (!inBounds(row, col))
        return false;
    if (m_grid[row][col] != Empty)
        return false;
    m_grid[row][col] = piece;
    return true;
}

Board::Piece Board::get(int row, int col) const
{
    if (!inBounds(row, col))
        return Empty;
    return m_grid[row][col];
}

void Board::reset(){
    for (int r = 0; r < SIZE; ++r)
        for (int c = 0; c < SIZE; ++c)
            m_grid[r][c] = Empty;

}



int Board::pieceAt(int row, int col) const
{
    return static_cast<int>(get(row, col));
}

Board::Piece Board::checkWin(int row, int col) const
{
    Piece current = get(row, col);
    if (current == Empty)
        return Empty;

    // 四个方向：水平、垂直、对角线1、对角线2
    const int dirs[4][2] = {
        {0, 1},  // 水平
        {1, 0},  // 垂直
        {1, 1},  // 主对角线
        {1, -1}  // 副对角线
    };

    for (auto &d : dirs) {
        int count = 1;  // 当前位置算一个

        // 正方向延伸
        for (int i = 1; i < 5; ++i) {
            int nr = row + d[0] * i;
            int nc = col + d[1] * i;
            if (inBounds(nr, nc) && m_grid[nr][nc] == current)
                ++count;
            else
                break;
        }

        // 反方向延伸
        for (int i = 1; i < 5; ++i) {
            int nr = row - d[0] * i;
            int nc = col - d[1] * i;
            if (inBounds(nr, nc) && m_grid[nr][nc] == current)
                ++count;
            else
                break;
        }

        if (count >= 5)
            return current;
    }
    return Empty;
}

bool Board::inBounds(int row, int col) const
{
    return row >= 0 && row < SIZE && col >= 0 && col < SIZE;
}

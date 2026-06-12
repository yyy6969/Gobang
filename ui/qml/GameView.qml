import QtQuick 2.15

Rectangle {
    width: 600; height: 650
    color: "#F0F0F0"
    property int cellSize: 38
    property int boardSize: 15
    // 棋盘起点偏移，使其居中
    property int boardX: (width - (boardSize-1) * cellSize) / 2
    property int boardY: (height - (boardSize-1) * cellSize) / 2 + 20  // 预留顶部计时空间

    // 计时显示
    Text {
        id: timeDisplay
        anchors.horizontalCenter: parent.horizontalCenter
        y: 10
        text: "黑方: " + formatTime(game.blackTime) + "  白方: " + formatTime(game.whiteTime)
        font.pixelSize: 18
    }
    function formatTime(sec) {
        var m = Math.floor(sec/60)
        var s = sec % 60
        return m + ":" + (s<10?"0":"") + s
    }

    // 棋盘背景
    Rectangle {
        x: boardX - 1; y: boardY - 1
        width: (boardSize-1) * cellSize + 2
        height: (boardSize-1) * cellSize + 2
        color: "#DEB887"
        border.color: "black"
    }

    // 网格线（横）
    Repeater {
        model: boardSize
        Rectangle {
            x: boardX
            y: boardY + index * cellSize
            width: (boardSize-1) * cellSize
            height: 1
            color: "black"
        }
    }
    // 网格线（竖）
    Repeater {
        model: boardSize
        Rectangle {
            x: boardX + index * cellSize
            y: boardY
            width: 1
            height: (boardSize-1) * cellSize
            color: "black"
        }
    }



    // 预览棋子
        Rectangle {
            id: preview
            width: cellSize * 0.8
            height: width
            radius: width/2
            opacity: 0.5
            visible: false
        }


    // 棋子层
    Item {
        id: piecesLayer
        anchors.fill: parent
        Repeater {
            id: pieceRepeater
            model: boardSize * boardSize
            Rectangle {
                property int row: index / boardSize
                property int col: index % boardSize
                x: boardX + col * cellSize - width/2
                y: boardY + row * cellSize - height/2
                width: cellSize * 0.8
                height: width
                radius: width/2
                color: {
                    var p = game.pieceAt(row, col)
                    if (p === 1) return "black"
                    if (p === 2) return "white"
                    return "transparent"
                }
                visible: color !== "transparent"
            }
        }
    }

    // 鼠标点击区域----------与棋盘严格对齐

    Item {
        id: inputArea

        x: boardX - cellSize/2
        y: boardY - cellSize/2
        width: (boardSize-1) * cellSize + cellSize
        height: (boardSize-1) * cellSize + cellSize

        // 悬停处理器：驱动预览棋子
        HoverHandler {
            id: hoverHandler
            enabled: !game.gameOver
            // 当悬停点移动时
            onPointChanged: {
                if (point.position.x < 0 || point.position.y < 0) {
                    preview.visible = false
                    return
                }
                var crossX = point.position.x - cellSize/2
                var crossY = point.position.y - cellSize/2
                var col = Math.round(crossX / cellSize)
                var row = Math.round(crossY / cellSize)
                if (row >= 0 && row < boardSize && col >= 0 && col < boardSize) {
                    if (game.pieceAt(row, col) === 0) {
                        preview.x = boardX + col * cellSize - preview.width/2
                        preview.y = boardY + row * cellSize - preview.height/2
                        preview.color = game.currentPlayer === 0 ? "black" : "white"
                        preview.visible = true
                        return
                    }
                }
                preview.visible = false
            }
            // 离开区域时隐藏预览
            onHoveredChanged: {
                if (!hovered) preview.visible = false
            }
        }

        // 点击处理器：落子
        TapHandler {
            enabled: !game.gameOver
            acceptedButtons: Qt.LeftButton
            onTapped: {
                // 使用 point.position 获取点击坐标
                var crossX = point.position.x - cellSize/2
                var crossY = point.position.y - cellSize/2
                var col = Math.round(crossX / cellSize)
                var row = Math.round(crossY / cellSize)
                if (row >= 0 && row < boardSize && col >= 0 && col < boardSize) {
                    game.placePiece(row, col)
                    pieceRepeater.model = 0
                    pieceRepeater.model = boardSize * boardSize
                }
            }
        }
    }


    // 游戏结束遮罩
    Rectangle {
        visible: game.gameOver
        anchors.centerIn: parent
        color: "#AAFFFFFF"
        width: 200; height: 100
        radius: 10
        Text {
            anchors.centerIn: parent
            text: game.winnerText + "\n点击重新开始"
            horizontalAlignment: Text.AlignHCenter
        }
        TapHandler {
            enabled: game.gameOver
            onTapped: {
                game.startGame()
                // 强制刷新棋子显示，让棋盘变空!!!!
                pieceRepeater.model = 0
                pieceRepeater.model = boardSize * boardSize
            }
        }
    }


    Connections {
        target: game
        function onBoardChanged(row, col, player) {

        }
    }

}

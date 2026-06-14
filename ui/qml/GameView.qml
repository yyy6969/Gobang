import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id: root
    width: 600
    height: 650
    color: "#2c3e50"

    property string gameMode: "local"
    signal backToMenu()
    property int cellSize: 38
    property int boardSize: 15
    property int boardX: (width - (boardSize-1) * cellSize) / 2
    property int boardY: (height - (boardSize-1) * cellSize) / 2 + 20

    // 返回按钮（无图形效果）
    Button {
        id: backBtn
        text: "← 返回菜单"
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: 12
        font.pixelSize: 14
        font.bold: true
        background: Rectangle {
            color: backBtn.hovered ? "#c0392b" : "#e94560"
            radius: 20
            width: backBtn.width
            height: backBtn.height
        }
        contentItem: Text {
            text: backBtn.text
            color: "white"
            font.pixelSize: 14
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        onClicked: backToMenu()
    }

    // 计时卡片
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 8
        width: 280
        height: 36
        radius: 18
        color: "#34495e"
        Text {
            anchors.centerIn: parent
            id: timeDisplay
            text: "⚫ " + formatTime(game.blackTime) + "    ⚪ " + formatTime(game.whiteTime)
            font.pixelSize: 16
            font.family: "monospace"
            color: "#ecf0f1"
            font.bold: true
        }
    }

    // 模式提示胶囊
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 52
        width: modeText.width + 20
        height: 26
        radius: 13
        color: {
            if (gameMode === "local") return "#27ae60"
            if (gameMode === "lan") return "#2980b9"
            return "#8e44ad"
        }
        Text {
            id: modeText
            anchors.centerIn: parent
            text: {
                if (gameMode === "local") return "🏠 本地对战 · 双人轮流"
                if (gameMode === "lan") return "🌐 局域网对战 · 等待连接"
                return "🤖 人机对战 · 黑棋先行"
            }
            font.pixelSize: 12
            color: "white"
            font.bold: true
        }
    }

    // 棋盘底板（模拟阴影：两个矩形错位）
    Rectangle {
        x: boardX - 2; y: boardY - 2
        width: (boardSize-1) * cellSize + 4
        height: (boardSize-1) * cellSize + 4
        radius: 6
        color: "#00000030"
    }
    Rectangle {
        x: boardX - 1; y: boardY - 1
        width: (boardSize-1) * cellSize + 2
        height: (boardSize-1) * cellSize + 2
        radius: 4
        color: "#d4a373"
        border.color: "#7f5539"
        border.width: 1
    }

    // 棋盘内底色
    Rectangle {
        x: boardX - 1; y: boardY - 1
        width: (boardSize-1) * cellSize + 2
        height: (boardSize-1) * cellSize + 2
        color: "#e9c5a3"
        border.color: "#8b5a2b"
        border.width: 1
    }

    // 网格线
    Repeater {
        model: boardSize
        Rectangle {
            x: boardX
            y: boardY + index * cellSize
            width: (boardSize-1) * cellSize
            height: 1
            color: "#4a2e1e"
        }
    }
    Repeater {
        model: boardSize
        Rectangle {
            x: boardX + index * cellSize
            y: boardY
            width: 1
            height: (boardSize-1) * cellSize
            color: "#4a2e1e"
        }
    }

    // 星位（天元/小目）
    Repeater {
        model: [
            {x:3, y:3}, {x:7, y:7}, {x:11, y:11},
            {x:3, y:11}, {x:11, y:3}
        ]
        Rectangle {
            x: boardX + modelData.x * cellSize - 3
            y: boardY + modelData.y * cellSize - 3
            width: 6; height: 6
            radius: 3
            color: "#8b5a2b"
            visible: boardSize === 15 && (modelData.x === 3 || modelData.x === 7 || modelData.x === 11)
        }
    }

    // 预览棋子（无光晕）
    Rectangle {
        id: preview
        width: cellSize * 0.8
        height: width
        radius: width/2
        opacity: 0.6
        visible: false
        border.width: 1
        border.color: "gold"
    }

    // 棋子层（带缩放动画）
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
                    if (p === 1) return "#2c2c2c"
                    if (p === 2) return "#f8f9fa"
                    return "transparent"
                }
                border.width: color === "#f8f9fa" ? 1 : 0
                border.color: "#aaa"
                visible: color !== "transparent"
                scale: visible ? 1 : 0
                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutElastic } }
            }
        }
    }

    // 鼠标交互
    Item {
        id: inputArea
        x: boardX - cellSize/2
        y: boardY - cellSize/2
        width: (boardSize-1) * cellSize + cellSize
        height: (boardSize-1) * cellSize + cellSize

        HoverHandler {
            id: hoverHandler
            enabled: !game.gameOver
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
                        preview.color = game.currentPlayer === 0 ? "#2c2c2c" : "#f8f9fa"
                        preview.visible = true
                        return
                    }
                }
                preview.visible = false
            }
            onHoveredChanged: {
                if (!hovered) preview.visible = false
            }
        }

        TapHandler {
            enabled: !game.gameOver
            acceptedButtons: Qt.LeftButton
            onTapped: {
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

    Rectangle {
        visible: game.gameOver
        anchors.fill: parent
        color: "#80000000"
        z: 10
        Rectangle {
            anchors.centerIn: parent
            width: 280
            height: 160
            radius: 20
            color: "#f0f0f0"
            border.width: 2
            border.color: "#e94560"
            Column {
                spacing: 16
                anchors.centerIn: parent
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: game.winnerText
                    font.pixelSize: 20
                    font.bold: true
                    color: "#2c3e50"
                }
                Button {
                    text: "重新开始"
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.pixelSize: 14
                    implicitWidth: 140
                    implicitHeight: 40
                    background: Rectangle {
                        color: parent.hovered ? "#c0392b" : "#e94560"
                        radius: 20
                    }
                    contentItem: Text {
                        text: parent.text
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: {
                        game.startGame()
                        pieceRepeater.model = 0
                        pieceRepeater.model = boardSize * boardSize
                    }
                }
                Button {
                    text: "返回菜单"
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.pixelSize: 14
                    implicitWidth: 140
                    implicitHeight: 40
                    background: Rectangle {
                        color: parent.hovered ? "#7f8c8d" : "#95a5a6"
                        radius: 20
                    }
                    contentItem: Text {
                        text: parent.text
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: backToMenu()
                }
            }
        }
    }

    function formatTime(sec) {
        if (sec === undefined) return "0:00"
        var m = Math.floor(sec/60)
        var s = sec % 60
        return m + ":" + (s<10?"0":"") + s
    }

    // 关键：修复残留棋盘 bug
    Component.onCompleted: {
        if (gameMode === "local")
            game.setGameMode(0)
        else if (gameMode === "lan")
            game.setGameMode(2)
        else if (gameMode === "ai")
            game.setGameMode(1)

        game.startGame()
        pieceRepeater.model = 0
        pieceRepeater.model = boardSize * boardSize
    }
}
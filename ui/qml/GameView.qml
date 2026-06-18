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

    // ========== 网络状态栏 ==========
    Rectangle {
        id: networkStatusBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 30
        color: game.networkStatus !== "" ? "#2980b9" : "transparent"
        visible: game.networkStatus !== ""

        Text {
            anchors.centerIn: parent
            text: game.networkStatus
            color: "white"
            font.pixelSize: 13
            font.bold: true
        }
    }

    // 返回按钮
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
        onClicked: {
            backToMenu()
        }
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
                if (gameMode === "lan") return "🌐 局域网对战"
                return "🤖 人机对战 · 黑棋先行"
            }
            font.pixelSize: 12
            color: "white"
            font.bold: true
        }
    }

    // 棋盘底板已删除重复冗余的一层
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
            visible: boardSize === 15
        }
    }

    // 预览棋子（显示在交点上）
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

    //  使用 Canvas 绘制棋子
    Canvas {
        id: boardCanvas
        x: boardX - cellSize/2
        y: boardY - cellSize/2
        width: (boardSize-1) * cellSize + cellSize
        height: (boardSize-1) * cellSize + cellSize
        z: 5

        property int lastRow: -1
        property int lastCol: -1

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            // 绘制所有棋子 - 修正：圆心对齐网格交点
            for (var row = 0; row < boardSize; row++) {
                for (var col = 0; col < boardSize; col++) {
                    var piece = game.pieceAt(row, col)
                    if (piece !== 0) {
                        // 加上半个格子偏移，让圆心落在交点上
                        var x = cellSize / 2 + col * cellSize
                        var y = cellSize / 2 + row * cellSize
                        var radius = cellSize * 0.38

                        // 棋子阴影
                        ctx.shadowColor = "rgba(0,0,0,0.3)"
                        ctx.shadowBlur = 4
                        ctx.shadowOffsetX = 1
                        ctx.shadowOffsetY = 1

                        // 绘制棋子
                        ctx.beginPath()
                        ctx.arc(x, y, radius, 0, Math.PI * 2)
                        ctx.closePath()

                        if (piece === 1) { // 黑棋
                            var gradient = ctx.createRadialGradient(
                                x - radius*0.3, y - radius*0.3, radius*0.1,
                                x, y, radius
                            )
                            gradient.addColorStop(0, "#555555")
                            gradient.addColorStop(0.7, "#222222")
                            gradient.addColorStop(1, "#111111")
                            ctx.fillStyle = gradient
                        } else { // 白棋
                            var gradient = ctx.createRadialGradient(
                                x - radius*0.3, y - radius*0.3, radius*0.1,
                                x, y, radius
                            )
                            gradient.addColorStop(0, "#ffffff")
                            gradient.addColorStop(0.5, "#f0f0f0")
                            gradient.addColorStop(1, "#d0d0d0")
                            ctx.fillStyle = gradient
                        }

                        ctx.shadowColor = "rgba(0,0,0,0.2)"
                        ctx.shadowBlur = 3
                        ctx.fill()

                        // 取消阴影（用于高光）
                        ctx.shadowColor = "transparent"
                        ctx.shadowBlur = 0

                        // 高光效果
                        if (piece === 1) {
                            ctx.beginPath()
                            ctx.arc(x - radius*0.25, y - radius*0.25, radius*0.15, 0, Math.PI * 2)
                            ctx.closePath()
                            ctx.fillStyle = "rgba(255,255,255,0.15)"
                            ctx.fill()
                        } else {
                            ctx.beginPath()
                            ctx.arc(x - radius*0.25, y - radius*0.25, radius*0.2, 0, Math.PI * 2)
                            ctx.closePath()
                            ctx.fillStyle = "rgba(255,255,255,0.6)"
                            ctx.fill()
                        }
                    }
                }
            }

            // 最后落子标记 - 修正：对齐交点
            if (lastRow >= 0 && lastCol >= 0 && game.pieceAt(lastRow, lastCol) !== 0) {
                var lx = cellSize / 2 + lastCol * cellSize
                var ly = cellSize / 2 + lastRow * cellSize
                ctx.beginPath()
                ctx.arc(lx, ly, 4, 0, Math.PI * 2)
                ctx.closePath()
                ctx.fillStyle = "#e94560"
                ctx.fill()
            }
        }

        //  监听网络刷新信号
        Connections {
            target: game
            onBoardChanged: {
                boardCanvas.requestPaint()
            }
            onBoardRefreshNeeded: {
                boardCanvas.requestPaint()
            }
            onGameStateChanged: {
                boardCanvas.requestPaint()
            }
        }

        // 定时器作为后备刷新机制
        Timer {
            interval: 500
            running: gameMode === "lan"
            repeat: true
            onTriggered: {
                boardCanvas.requestPaint()
            }
        }
    }

    // 鼠标交互 - 修正点击坐标换算，对准网格交点
    Item {
        id: inputArea
        x: boardX - cellSize/2
        y: boardY - cellSize/2
        width: (boardSize-1) * cellSize + cellSize
        height: (boardSize-1) * cellSize + cellSize
        z: 6

        HoverHandler {
            id: hoverHandler
            enabled: !game.gameOver
            onPointChanged: {
                if (point.position.x < 0 || point.position.y < 0) {
                    preview.visible = false
                    return
                }
                // 修正先抵消边距偏移，再计算最近交点
                var localX = point.position.x - cellSize / 2
                var localY = point.position.y - cellSize / 2
                var col = Math.round(localX / cellSize)
                var row = Math.round(localY / cellSize)

                if (row >= 0 && row < boardSize && col >= 0 && col < boardSize) {
                    if (game.pieceAt(row, col) === 0) {
                        // 预览棋子圆心对齐交点
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
                // 修正点击坐标换算，和悬停逻辑保持一致
                var localX = point.position.x - cellSize / 2
                var localY = point.position.y - cellSize / 2
                var col = Math.round(localX / cellSize)
                var row = Math.round(localY / cellSize)

                if (row >= 0 && row < boardSize && col >= 0 && col < boardSize) {
                    if (game.pieceAt(row, col) === 0) {
                        boardCanvas.lastRow = row
                        boardCanvas.lastCol = col
                        game.placePiece(row, col)
                        boardCanvas.requestPaint()
                    }
                }
            }
        }
    }

    // 游戏结束遮罩
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
                        boardCanvas.lastRow = -1
                        boardCanvas.lastCol = -1
                        game.startGame()
                        boardCanvas.requestPaint()
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

    //  聊天区域
    Rectangle {
        id: chatPanel
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 10
        height: 120
        color: "#34495e"
        radius: 10
        visible: gameMode === "lan"
        z: 8

        Column {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 4

            ScrollView {
                width: parent.width
                height: 65
                clip: true
                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AlwaysOff
                }

                TextArea {
                    id: chatDisplay
                    text: game.chatHistory
                    color: "#ecf0f1"
                    font.pixelSize: 12
                    readOnly: true
                    wrapMode: Text.Wrap
                    background: Rectangle {
                        color: "transparent"
                    }
                }
            }

            Row {
                width: parent.width
                spacing: 6

                TextField {
                    id: chatInput
                    width: parent.width - 70
                    height: 30
                    placeholderText: "输入聊天消息..."
                    color: "white"
                    font.pixelSize: 12
                    background: Rectangle {
                        color: "#2c3e50"
                        radius: 5
                    }
                    onAccepted: sendChat()
                }

                Button {
                    text: "发送"
                    width: 60
                    height: 30
                    font.pixelSize: 12
                    background: Rectangle {
                        color: parent.hovered ? "#2980b9" : "#3498db"
                        radius: 5
                    }
                    contentItem: Text {
                        text: parent.text
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: sendChat()
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

    function sendChat() {
        if (chatInput.text.trim() !== "") {
            game.sendChat(chatInput.text)
            chatInput.text = ""
        }
    }

    // 初始化
    Component.onCompleted: {
        if (gameMode === "local")
            game.setGameMode(0)
        else if (gameMode === "lan")
            game.setGameMode(2)
        else if (gameMode === "ai")
            game.setGameMode(1)

        game.startGame()
        boardCanvas.requestPaint()

        if (gameMode === "lan") {
            refreshTimer.start()
        }
    }

    Timer {
        id: refreshTimer
        interval: 300
        repeat: true
        running: gameMode === "lan"
        onTriggered: {
            boardCanvas.requestPaint()
        }
    }
}

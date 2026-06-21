import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id: root
    color: "#2c3e50"

    property string gameMode: "local"
    signal backToMenu()
    property int cellSize: 38
    property int boardSize: 15

    // 动态顶部高度（网络状态栏可见时增加30px）
    property int topBarBaseHeight: 80
    property int topBarExtraHeight: game.networkStatus !== "" ? 30 : 0
    property int topBarHeight: topBarBaseHeight + topBarExtraHeight
    property int bottomBarHeight: 32

    //顶部栏
    Rectangle {
        id: topBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: topBarHeight
        color: "transparent"
        z: 10

        // 网络状态栏
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

        // 按钮行
        Row {
            id: topButtons
            anchors.top: networkStatusBar.visible ? networkStatusBar.bottom : parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 8
            height: 36
            spacing: 10
            z: 20

            Button {
                id: backBtn
                text: "← 返回菜单"
                font.pixelSize: 14
                font.bold: true
                implicitWidth: 110
                implicitHeight: 36
                background: Rectangle {
                    color: backBtn.hovered ? "#c0392b" : "#e94560"
                    radius: 20
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

            Button {
                id: giveUpBtn
                text: "🏳️ 认输"
                font.pixelSize: 14
                font.bold: true
                implicitWidth: 85
                implicitHeight: 36
                enabled: !game.gameOver
                visible: gameMode !== "local"
                background: Rectangle {
                    color: {
                        if (!giveUpBtn.enabled) return "#666666"
                        return giveUpBtn.hovered ? "#c0392b" : "#e67e22"
                    }
                    radius: 20
                }
                contentItem: Text {
                    text: giveUpBtn.text
                    color: "white"
                    font.pixelSize: 14
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: confirmDialog.visible = true
            }

            Item { width: parent.width - backBtn.width - giveUpBtn.width - 30; height: 1 }
        }

        // 计时和模式提示行
        Row {
            anchors.top: topButtons.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 20
            height: 36

            Rectangle {
                id: timerRect
                height: 30
                width: 280
                radius: 15
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

            Rectangle {
                id: modeRect
                height: 26
                width: modeText.width + 20
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
        }
    }

    //底部栏
    Rectangle {
        id: bottomBar
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: bottomBarHeight
        color: "transparent"
        z: 10

        // 回合提示
        Rectangle {
            anchors.centerIn: parent
            height: 24
            width: 200
            radius: 12
            color: game.gameOver ? "#95a5a6" : (game.currentPlayer === 0 ? "#2c2c2c" : "#ecf0f1")
            Text {
                anchors.centerIn: parent
                text: game.gameOver ? "游戏结束" : (game.currentPlayer === 0 ? "⚫ 黑棋回合" : "⚪ 白棋回合")
                color: game.currentPlayer === 0 ? "white" : "#2c3e50"
                font.pixelSize: 12
                font.bold: true
            }
        }
    }

    //中间内容区域
    Item {
        id: centerArea
        anchors.top: topBar.bottom
        anchors.bottom: bottomBar.top
        anchors.left: parent.left
        anchors.right: parent.right

        // 棋盘容器
        Item {
            id: boardContainer
            anchors.left: parent.left
            anchors.right: chatPanel.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.rightMargin: 10

            property int boardPixels: (boardSize-1) * cellSize
            property int boardX: (width - boardPixels) / 2
            property int boardY: (height - boardPixels) / 2

            // 棋盘底板
            Rectangle {
                x: boardContainer.boardX - 2
                y: boardContainer.boardY - 2
                width: boardContainer.boardPixels + 4
                height: boardContainer.boardPixels + 4
                radius: 6
                color: "#00000030"
            }
            Rectangle {
                x: boardContainer.boardX - 1
                y: boardContainer.boardY - 1
                width: boardContainer.boardPixels + 2
                height: boardContainer.boardPixels + 2
                radius: 4
                color: "#e9c5a3"
                border.color: "#8b5a2b"
                border.width: 1
            }

            // 预览棋子
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

            // Canvas网格线、星位、棋子
            Canvas {
                id: boardCanvas
                x: boardContainer.boardX - cellSize/2
                y: boardContainer.boardY - cellSize/2
                width: boardContainer.boardPixels + cellSize
                height: boardContainer.boardPixels + cellSize
                z: 5

                property int lastRow: -1
                property int lastCol: -1

                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)

                    //绘制网格线,偏移 cellSize/2以便对其棋子中心
                    ctx.strokeStyle = "#4a2e1e"
                    ctx.lineWidth = 1

                    // 横线
                    for (var row = 0; row < boardSize; row++) {
                        var y = cellSize / 2 + row * cellSize
                        ctx.beginPath()
                        ctx.moveTo(cellSize / 2, y)
                        ctx.lineTo(boardContainer.boardPixels + cellSize / 2, y)
                        ctx.stroke()
                    }

                    // 竖线
                    for (var col = 0; col < boardSize; col++) {
                        var x = cellSize / 2 + col * cellSize
                        ctx.beginPath()
                        ctx.moveTo(x, cellSize / 2)
                        ctx.lineTo(x, boardContainer.boardPixels + cellSize / 2)
                        ctx.stroke()
                    }

                    // 绘制星位
                    if (boardSize === 15) {
                        var starPoints = [
                            {x:3, y:3}, {x:7, y:7}, {x:11, y:11},
                            {x:3, y:11}, {x:11, y:3}
                        ]
                        ctx.fillStyle = "#8b5a2b"
                        for (var i = 0; i < starPoints.length; i++) {
                            var sx = cellSize / 2 + starPoints[i].x * cellSize
                            var sy = cellSize / 2 + starPoints[i].y * cellSize
                            ctx.beginPath()
                            ctx.arc(sx, sy, 3, 0, Math.PI * 2)
                            ctx.fill()
                        }
                    }

                    //绘制棋子
                    for (var row2 = 0; row2 < boardSize; row2++) {
                        for (var col2 = 0; col2 < boardSize; col2++) {
                            var piece = game.pieceAt(row2, col2)
                            if (piece !== 0) {
                                var px = cellSize / 2 + col2 * cellSize
                                var py = cellSize / 2 + row2 * cellSize
                                var radius = cellSize * 0.38

                                ctx.shadowColor = "rgba(0,0,0,0.3)"
                                ctx.shadowBlur = 4
                                ctx.shadowOffsetX = 1
                                ctx.shadowOffsetY = 1

                                ctx.beginPath()
                                ctx.arc(px, py, radius, 0, Math.PI * 2)
                                ctx.closePath()

                                if (piece === 1) {
                                    var gradient = ctx.createRadialGradient(
                                        px - radius*0.3, py - radius*0.3, radius*0.1,
                                        px, py, radius
                                    )
                                    gradient.addColorStop(0, "#555555")
                                    gradient.addColorStop(0.7, "#222222")
                                    gradient.addColorStop(1, "#111111")
                                    ctx.fillStyle = gradient
                                } else {
                                    var gradient = ctx.createRadialGradient(
                                        px - radius*0.3, py - radius*0.3, radius*0.1,
                                        px, py, radius
                                    )
                                    gradient.addColorStop(0, "#ffffff")
                                    gradient.addColorStop(0.5, "#f0f0f0")
                                    gradient.addColorStop(1, "#d0d0d0")
                                    ctx.fillStyle = gradient
                                }

                                ctx.shadowColor = "rgba(0,0,0,0.2)"
                                ctx.shadowBlur = 3
                                ctx.fill()

                                ctx.shadowColor = "transparent"
                                ctx.shadowBlur = 0

                                // 高光
                                if (piece === 1) {
                                    ctx.beginPath()
                                    ctx.arc(px - radius*0.25, py - radius*0.25, radius*0.15, 0, Math.PI * 2)
                                    ctx.closePath()
                                    ctx.fillStyle = "rgba(255,255,255,0.15)"
                                    ctx.fill()
                                } else {
                                    ctx.beginPath()
                                    ctx.arc(px - radius*0.25, py - radius*0.25, radius*0.2, 0, Math.PI * 2)
                                    ctx.closePath()
                                    ctx.fillStyle = "rgba(255,255,255,0.6)"
                                    ctx.fill()
                                }
                            }
                        }
                    }

                    // 最后落子标记
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

                Connections {
                    target: game
                    onBoardChanged: boardCanvas.requestPaint()
                    onBoardRefreshNeeded: boardCanvas.requestPaint()
                    onGameStateChanged: boardCanvas.requestPaint()
                }

                Timer {
                    interval: 500
                    running: gameMode === "lan"
                    repeat: true
                    onTriggered: boardCanvas.requestPaint()
                }
            }

            // 鼠标交互
            Item {
                id: inputArea
                x: boardContainer.boardX - cellSize/2
                y: boardContainer.boardY - cellSize/2
                width: boardContainer.boardPixels + cellSize
                height: boardContainer.boardPixels + cellSize
                z: 6

                HoverHandler {
                    id: hoverHandler
                    enabled: !game.gameOver
                    onPointChanged: {
                        if (point.position.x < 0 || point.position.y < 0) {
                            preview.visible = false
                            return
                        }
                        var localX = point.position.x - cellSize / 2
                        var localY = point.position.y - cellSize / 2
                        var col = Math.round(localX / cellSize)
                        var row = Math.round(localY / cellSize)

                        if (row >= 0 && row < boardSize && col >= 0 && col < boardSize) {
                            if (game.pieceAt(row, col) === 0) {
                                preview.x = boardContainer.boardX + col * cellSize - preview.width/2
                                preview.y = boardContainer.boardY + row * cellSize - preview.height/2
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
        }

        // 右侧聊天面板,只在联网模式下显示
        Rectangle {
            id: chatPanel
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 220
            color: "#34495e"
            radius: 8
            border.color: "#2c3e50"
            border.width: 1
            visible: gameMode === "lan"
            z: 25

            Column {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8

                Text {
                    text: "💬 聊天"
                    font.bold: true
                    color: "white"
                    font.pixelSize: 16
                }

                ScrollView {
                    id: chatScrollView
                    width: parent.width
                    height: parent.height - 80
                    clip: true
                    TextArea {
                        id: chatDisplay
                        width: chatScrollView.width - 10
                        readOnly: true
                        wrapMode: TextArea.Wrap
                        color: "#ecf0f1"
                        font.pixelSize: 13
                        background: Rectangle {
                            color: "#2c3e50"
                            radius: 4
                        }
                        text: game.chatHistory
                        onTextChanged: {
                            chatScrollView.contentItem.contentY = chatDisplay.height - chatScrollView.height
                        }
                    }
                }

                Row {
                    width: parent.width
                    spacing: 6
                    TextField {
                        id: chatInput
                        width: parent.width - 70
                        height: 32
                        color: "white"
                        font.pixelSize: 13
                        placeholderText: "输入消息..."
                        placeholderTextColor: "#888"
                        background: Rectangle {
                            color: "#2c3e50"
                            radius: 4
                        }
                        onAccepted: sendChat()
                    }
                    Button {
                        id: sendBtn
                        text: "发送"
                        width: 60
                        height: 32
                        font.pixelSize: 13
                        font.bold: true
                        background: Rectangle {
                            color: sendBtn.hovered ? "#27ae60" : "#2ecc71"
                            radius: 4
                        }
                        contentItem: Text {
                            text: sendBtn.text
                            color: "white"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        onClicked: sendChat()
                    }
                }
            }
        }
    }

    //确认认输对话框
    Rectangle {
        id: confirmDialog
        anchors.fill: parent
        color: "#80000000"
        z: 100
        visible: false

        MouseArea {
            anchors.fill: parent
            onClicked: confirmDialog.visible = false
        }

        Rectangle {
            anchors.centerIn: parent
            width: 280
            height: 150
            radius: 20
            color: "#f0f0f0"
            border.width: 2
            border.color: "#e94560"

            Column {
                spacing: 16
                anchors.centerIn: parent
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "确定要认输吗？"
                    font.pixelSize: 18
                    font.bold: true
                    color: "#2c3e50"
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "认输后本局将结束"
                    font.pixelSize: 13
                    color: "#7f8c8d"
                }
                Row {
                    spacing: 20
                    anchors.horizontalCenter: parent.horizontalCenter
                    Button {
                        text: "确定认输"
                        font.pixelSize: 14
                        implicitWidth: 100
                        implicitHeight: 36
                        background: Rectangle {
                            color: parent.hovered ? "#c0392b" : "#e94560"
                            radius: 10
                        }
                        contentItem: Text {
                            text: parent.text
                            color: "white"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        onClicked: {
                            game.giveUp()
                            confirmDialog.visible = false
                        }
                    }
                    Button {
                        text: "取消"
                        font.pixelSize: 14
                        implicitWidth: 80
                        implicitHeight: 36
                        background: Rectangle {
                            color: parent.hovered ? "#7f8c8d" : "#95a5a6"
                            radius: 10
                        }
                        contentItem: Text {
                            text: parent.text
                            color: "white"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        onClicked: {
                            confirmDialog.visible = false
                        }
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
        z: 150
        Rectangle {
            anchors.centerIn: parent
            width: 280
            height: 180
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
                Row {
                    spacing: 12
                    anchors.horizontalCenter: parent.horizontalCenter
                    Button {
                        text: "重新开始"
                        font.pixelSize: 14
                        implicitWidth: 120
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
                        font.pixelSize: 14
                        implicitWidth: 120
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
    }

    // 辅助函数
    function formatTime(sec) {
        if (sec === undefined) return "0:00"
        var m = Math.floor(sec/60)
        var s = sec % 60
        return m + ":" + (s<10?"0":"") + s
    }

    function sendChat() {
        var msg = chatInput.text.trim()
        if (msg !== "") {
            game.sendChat(msg)
            chatInput.text = ""
            chatInput.focus = true
        }
    }

    Component.onCompleted: {
        if (gameMode === "local")
            game.setGameMode(0)
        else if (gameMode === "lan")
            game.setGameMode(2)
        else if (gameMode === "ai")
            game.setGameMode(1)
        game.startGame()
        boardCanvas.requestPaint()
    }
}
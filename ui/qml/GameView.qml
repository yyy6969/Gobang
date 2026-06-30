import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: root
    color: "#2c3e50"

    property string gameMode: "local"
    signal backToMenu()

    // 尺寸属性
    property int topBarHeight: 40
    property int bottomBarHeight: 40
    property int chatBarHeight: 0
    property bool chatExpanded: false   // 聊天面板展开/收起

    property int cellSize: {
        var w = root.width - 20
        var h = root.height - topBarHeight - bottomBarHeight - 20
        var maxCell = Math.min((w - 40) / 14, (h - 40) / 14)
        var size = maxCell * 1.08//调整棋子大小
        return Math.max(20, size)
    }

    property int boardPixels: 14 * cellSize
    property int boardX: (parent.width - boardPixels) / 2
    property int boardY: {
        var availHeight = root.height - topBarHeight - bottomBarHeight
        return topBarHeight + (availHeight - boardPixels) / 2
    }

    // 背景
    Image {
        anchors.fill: parent
        source: "qrc:/image/background2.jpg"
        fillMode: Image.PreserveAspectCrop
        opacity: 0.5
    }

    //顶部栏
    Rectangle {
        id: topBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: topBarHeight
        color: "transparent"
        z: 10

        Column {
            anchors.fill: parent
            anchors.margins: 4
            spacing: 2

            // 第一行：返回、认输（左对齐）
            RowLayout {
                width: parent.width
                height: 28
                spacing: 8

                Button {
                    text: "← 返回"
                    font.pixelSize: 14
                    implicitWidth: 70
                    implicitHeight: 28
                    background: Rectangle {
                        color: parent.hovered ? "#696969" : "#a9a9a9"
                        radius: 14
                    }
                    contentItem: Text {
                        text: parent.text
                        color: "white"
                        font: parent.font
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: backToMenu()
                }

                Button {
                    text: "🏳️ 认输"
                    font.pixelSize: 14
                    implicitWidth: 65
                    implicitHeight: 28
                    enabled: !game.gameOver
                    visible: gameMode !== "local"
                    background: Rectangle {
                        color: parent.enabled ? (parent.hovered ? "#696969" : "#a9a9a9") : "#666666"
                        radius: 14
                    }
                    contentItem: Text {
                        text: parent.text
                        color: "white"
                        font: parent.font
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: confirmDialog.visible = true
                }

                // 占位，让按钮靠左
                Item { Layout.fillWidth: true }
            }

            // 第二行：时间胶囊居中，模式标签在其右侧（整体居中）
            RowLayout {
                width: parent.width
                height: 24
                spacing: 6

                // 左侧占位
                Item { Layout.fillWidth: true }

                // 时间胶囊
                Rectangle {
                    height: 22
                    implicitWidth: Math.min(parent.width - 100, 200)
                    radius: 11
                    color: "#a9a9a9"
                    Text {
                        anchors.centerIn: parent
                        text: "⚫ " + formatTime(game.blackTime) + "  ⚪ " + formatTime(game.whiteTime)
                        font.pixelSize: 12
                        font.family: "monospace"
                        color: "#ecf0f1"
                        font.bold: true
                        elide: Text.ElideRight
                    }
                }

                // 模式标签
                Rectangle {
                    height: 22
                    width: 50
                    radius: 11
                    color: gameMode === "local" ? "#27ae60" : (gameMode === "lan" ? "#2980b9" : "#8e44ad")
                    Text {
                        anchors.centerIn: parent
                        text: gameMode === "local" ? "本地" : (gameMode === "lan" ? "联网" : "人机")
                        font.pixelSize: 10
                        color: "white"
                        font.bold: true
                    }
                }

                // 右侧占位
                Item { Layout.fillWidth: true }
            }
        }
    }
    // 棋盘区域
    Item {
        id: boardContainer
        x: 0
        y: topBarHeight
        width: parent.width
        height: parent.height - topBarHeight - bottomBarHeight

        // 棋盘底板
        Rectangle {
            x: root.boardX - 2
            y: root.boardY - 2
            width: root.boardPixels + 4
            height: root.boardPixels + 4
            radius: 6
            color: "#00000030"
        }
        Rectangle {
            x: root.boardX - 1
            y: root.boardY - 1
            width: root.boardPixels + 2
            height: root.boardPixels + 2
            radius: 4
            color: "#e9c5a3"
            border.color: "#8b5a2b"
            border.width: 1
        }

        // 预览棋子
        Rectangle {
            id: preview
            width: root.cellSize * 0.8
            height: width
            radius: width/2
            opacity: 0.6
            visible: false
            border.width: 1
            border.color: "gold"
            z: 6
        }

        // Canvas 绘制
        Canvas {
            id: boardCanvas
            x: root.boardX - root.cellSize/2
            y: root.boardY - root.cellSize/2
            width: root.boardPixels + root.cellSize
            height: root.boardPixels + root.cellSize
            z: 5

            property int lastRow: -1
            property int lastCol: -1

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)

                var cell = root.cellSize
                var boardSize = 15
                var half = cell / 2
                var maxPix = (boardSize - 1) * cell

                // 网格
                ctx.strokeStyle = "#4a2e1e"
                ctx.lineWidth = 1
                for (var i = 0; i < boardSize; i++) {
                    var p = half + i * cell
                    ctx.beginPath()
                    ctx.moveTo(half, p)
                    ctx.lineTo(maxPix + half, p)
                    ctx.stroke()
                    ctx.beginPath()
                    ctx.moveTo(p, half)
                    ctx.lineTo(p, maxPix + half)
                    ctx.stroke()
                }

                // 星位
                var stars = [[3,3],[7,7],[11,11],[3,11],[11,3]]
                ctx.fillStyle = "#8b5a2b"
                for (var s = 0; s < stars.length; s++) {
                    var sx = half + stars[s][0] * cell
                    var sy = half + stars[s][1] * cell
                    ctx.beginPath()
                    ctx.arc(sx, sy, 3, 0, 2 * Math.PI)
                    ctx.fill()
                }

                // 棋子
                for (var row = 0; row < boardSize; row++) {
                    for (var col = 0; col < boardSize; col++) {
                        var piece = game.pieceAt(row, col)
                        if (piece === 0) continue
                        var px = half + col * cell
                        var py = half + row * cell
                        var radius = cell * 0.38

                        ctx.shadowColor = "rgba(0,0,0,0.3)"
                        ctx.shadowBlur = 4
                        ctx.shadowOffsetX = 1
                        ctx.shadowOffsetY = 1
                        ctx.beginPath()
                        ctx.arc(px, py, radius, 0, 2 * Math.PI)
                        ctx.closePath()
                        if (piece === 1) {
                            var grad = ctx.createRadialGradient(px-radius*0.3, py-radius*0.3, radius*0.1, px, py, radius)
                            grad.addColorStop(0, "#555")
                            grad.addColorStop(0.7, "#222")
                            grad.addColorStop(1, "#111")
                            ctx.fillStyle = grad
                        } else {
                            var grad = ctx.createRadialGradient(px-radius*0.3, py-radius*0.3, radius*0.1, px, py, radius)
                            grad.addColorStop(0, "#fff")
                            grad.addColorStop(0.5, "#f0f0f0")
                            grad.addColorStop(1, "#d0d0d0")
                            ctx.fillStyle = grad
                        }
                        ctx.fill()
                        // 高光
                        ctx.shadowColor = "transparent"
                        ctx.shadowBlur = 0
                        ctx.beginPath()
                        ctx.arc(px - radius*0.25, py - radius*0.25, radius*0.15, 0, 2 * Math.PI)
                        ctx.closePath()
                        ctx.fillStyle = piece === 1 ? "rgba(255,255,255,0.15)" : "rgba(255,255,255,0.6)"
                        ctx.fill()
                    }
                }

                // 最后落子标记
                if (lastRow >= 0 && lastCol >= 0 && game.pieceAt(lastRow, lastCol) !== 0) {
                    var lx = half + lastCol * cell
                    var ly = half + lastRow * cell
                    ctx.beginPath()
                    ctx.arc(lx, ly, 4, 0, 2 * Math.PI)
                    ctx.closePath()
                    ctx.fillStyle = "#e94560"
                    ctx.fill()
                }
            }

            Connections {
                target: game
                function onBoardChanged(){ boardCanvas.requestPaint() }
                function onGameStateChanged(){ boardCanvas.requestPaint() }
            }
            Timer {
                interval: 500
                running: gameMode === "lan"
                repeat: true
                onTriggered: boardCanvas.requestPaint()
            }
        }

        // 鼠标/触摸交互
        Item {
            id: inputArea
            x: root.boardX - root.cellSize/2
            y: root.boardY - root.cellSize/2
            width: root.boardPixels + root.cellSize
            height: root.boardPixels + root.cellSize
            z: 6

            HoverHandler {
                id: hoverHandler
                enabled: !game.gameOver
                onPointChanged: {
                    if (point.position.x < 0 || point.position.y < 0) {
                        preview.visible = false
                        return
                    }
                    var localX = point.position.x - root.cellSize / 2
                    var localY = point.position.y - root.cellSize / 2
                    var col = Math.round(localX / root.cellSize)
                    var row = Math.round(localY / root.cellSize)
                    if (row >= 0 && row < 15 && col >= 0 && col < 15 && game.pieceAt(row, col) === 0) {
                        preview.x = root.boardX + col * root.cellSize - preview.width/2
                        preview.y = root.boardY + row * root.cellSize - preview.height/2
                        preview.color = game.currentPlayer === 0 ? "#2c2c2c" : "#f8f9fa"
                        preview.visible = true
                    } else {
                        preview.visible = false
                    }
                }
                onHoveredChanged: { if (!hovered) preview.visible = false }
            }

            TapHandler {
                enabled: !game.gameOver
                acceptedButtons: Qt.LeftButton
                onTapped: {
                    var localX = point.position.x - root.cellSize / 2
                    var localY = point.position.y - root.cellSize / 2
                    var col = Math.round(localX / root.cellSize)
                    var row = Math.round(localY / root.cellSize)
                    if (row >= 0 && row < 15 && col >= 0 && col < 15 && game.pieceAt(row, col) === 0) {
                        boardCanvas.lastRow = row
                        boardCanvas.lastCol = col
                        game.placePiece(row, col)
                        boardCanvas.requestPaint()
                    }
                }
            }
        }
    }

    // 底部栏
    Rectangle {
        id: bottomBar
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: bottomBarHeight
        color: "transparent"
        z: 10

        Row {
            anchors.centerIn: parent
            spacing: 12
            Rectangle {
                height: 28
                width: 160
                radius: 14
                color: game.gameOver ? "#95a5a6" : (game.currentPlayer === 0 ? "#2c2c2c" : "#ecf0f1")
                Text {
                    anchors.centerIn: parent
                    text: game.gameOver ? "🏁 游戏结束" : (game.currentPlayer === 0 ? "⚫ 黑棋走" : "⚪ 白棋走")
                    color: game.currentPlayer === 0 ? "white" : "#2c3e50"
                    font.pixelSize: 13
                    font.bold: true
                }
            }
            Text {
                visible: gameMode === "lan" && game.networkStatus !== ""
                text: game.networkStatus
                color: "white"
                font.pixelSize: 12
            }
        }
    }

    // 聊天面板(聊天时展开)
    Rectangle {
        id: chatPanel
        anchors.bottom: bottomBar.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: chatExpanded ? 350 : 0
        visible: gameMode === "lan" && game.networkStatus !== "" && chatExpanded
        color: "#ffffff"
        clip: true
        z: 30
        radius: 12

        Behavior on height {
            NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
        }

        Column {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 8

            // 消息显示区域
            ScrollView {
                width: parent.width
                height: parent.height - 50
                TextArea {
                    id: chatDisplay
                    width: parent.width
                    readOnly: true
                    wrapMode: TextArea.Wrap
                    color: "#2c3e50"
                    font.pixelSize: 14
                    font.family: "Microsoft YaHei"
                    background: Rectangle {
                        color: "#f5f5f5"
                        radius: 8
                        border.color: "#ddd"
                        border.width: 1
                    }
                    text: game.chatHistory
                    onTextChanged: {
                        chatDisplay.cursorPosition = chatDisplay.length
                    }
                }
            }

            // 输入行
            Row {
                width: parent.width
                height: 40
                spacing: 8

                TextField {
                    id: chatInput
                    width: parent.width - 70
                    height: parent.height
                    placeholderText: "输入消息..."
                    color: "#2c3e50"
                    font.pixelSize: 14
                    background: Rectangle {
                        color: "#f5f5f5"
                        radius: 8
                        border.color: "#ddd"
                        border.width: 1
                    }
                    onAccepted: sendChat()
                }
                Button {
                    text: "发送"
                    font.pixelSize: 14
                    width: 60
                    height: parent.height
                    background: Rectangle {
                        color: "#2ecc71"
                        radius: 8
                    }
                    contentItem: Text {
                        text: "发送"
                        color: "white"
                        font: parent.font
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: sendChat()
                }
            }
        }

        // 关闭按钮
        Button {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 8
            width: 30
            height: 30
            visible: chatExpanded
            background: Rectangle {
                color: "#e74c3c"
                radius: 15
            }
            contentItem: Item {
                anchors.fill: parent
                Text {
                    text: "✕"
                    color: "white"
                    font.pixelSize: 18
                    font.bold: true
                    anchors.centerIn: parent
                }
            }
            onClicked: chatExpanded = false
        }
    }


    // 独立聊天展开按钮
    Button {
        id: toggleChatBtn
        anchors.right: parent.right
        anchors.bottom: bottomBar.top
        anchors.margins: 6
        width: 40
        height: 40
        visible: gameMode === "lan" && game.networkStatus !== "" && !chatExpanded
        background: Rectangle {
            color: "#3498db"
            radius: 20
        }
        contentItem: Text {
            text: "💬"
            color: "white"
            font.pixelSize: 20
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        onClicked: chatExpanded = true
    }

    // 认输确认对话框
    Rectangle {
        id: confirmDialog
        anchors.fill: parent
        color: "#80000000"
        z: 100
        visible: false

        MouseArea { anchors.fill: parent; onClicked: confirmDialog.visible = false }

        Rectangle {
            anchors.centerIn: parent
            width: 280
            height: 150
            radius: 20
            color: "#f0f0f0"
            Column {
                spacing: 16
                anchors.centerIn: parent
                Text { text: "确定要认输吗？"; font.pixelSize: 18; font.bold: true; color: "#2c3e50"; anchors.horizontalCenter: parent.horizontalCenter }
                Text { text: "认输后本局将结束"; font.pixelSize: 13; color: "#7f8c8d"; anchors.horizontalCenter: parent.horizontalCenter }
                Row {
                    spacing: 20
                    anchors.horizontalCenter: parent.horizontalCenter
                    Button {
                        text: "确定认输"
                        font.pixelSize: 14
                        implicitWidth: 100
                        implicitHeight: 36
                        background: Rectangle { color: parent.hovered ? "#7f8c8d" : "#95a5a6"; radius: 10 }
                        contentItem: Text { text: parent.text; color: "white"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        onClicked: { game.giveUp(); confirmDialog.visible = false }
                    }
                    Button {
                        text: "取消"
                        font.pixelSize: 14
                        implicitWidth: 80
                        implicitHeight: 36
                        background: Rectangle { color: parent.hovered ? "#7f8c8d" : "#95a5a6"; radius: 10 }
                        contentItem: Text { text: parent.text; color: "white"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        onClicked: confirmDialog.visible = false
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
            Column {
                spacing: 16
                anchors.centerIn: parent
                Text {
                    text: game.winnerText
                    font.pixelSize: 20
                    font.bold: true
                    color: "#2c3e50"
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                Row {
                    spacing: 12
                    anchors.horizontalCenter: parent.horizontalCenter
                    Button {
                        text: "重新开始"
                        font.pixelSize: 14
                        implicitWidth: 120
                        implicitHeight: 40
                        background: Rectangle { color: parent.hovered ? "#7f8c8d" : "#95a5a6"; radius: 20 }
                        contentItem: Text { text: parent.text; color: "white"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        onClicked: {
                            boardCanvas.lastRow = -1
                            boardCanvas.lastCol = -1
                            game.requestRestart()
                            boardCanvas.requestPaint()
                        }
                    }
                    Button {
                        text: "返回菜单"
                        font.pixelSize: 14
                        implicitWidth: 120
                        implicitHeight: 40
                        background: Rectangle { color: parent.hovered ? "#7f8c8d" : "#95a5a6"; radius: 20 }
                        contentItem: Text { text: parent.text; color: "white"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        onClicked: backToMenu()
                    }
                }
            }
        }
    }

    //辅助函数
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

    // 初始化
    Component.onCompleted: {
        if (gameMode === "local") game.setGameMode(0)
        else if (gameMode === "lan") game.setGameMode(2)
        else if (gameMode === "ai") game.setGameMode(1)
        game.startGame()
        boardCanvas.requestPaint()
    }

    //监听棋盘方便输入数据库
    Connections {
        target: game
        onGameOverChanged: {
            if (game.gameOver) {
                // 获取玩家名字
                var playerName = (typeof dbManager !== 'undefined' && dbManager) ? dbManager.getUserName() : "玩家"
                if (playerName === "") playerName = "玩家"

                // 确定对手名字
                var opponentName = ""
                if (gameMode === "local") opponentName = "本地对手"
                else if (gameMode === "ai") opponentName = "AI"
                else if (gameMode === "lan") opponentName = "网络对手"

                // 确定胜者
                var winner = "draw"
                if (game.winnerText) {
                    var wt = game.winnerText
                    if (wt.includes("黑") || wt.includes("黑棋")) {
                        // 如果当前模式是 AI 且玩家执黑，则玩家胜；否则对手胜
                        // 简单处理：如果是 AI 模式，玩家总是黑棋（因为黑先），所以黑胜=玩家胜
                        // 但其他模式可能不同，这里为了通用，我们直接保存 "黑胜" 或 "白胜" 更清晰
                        // 但数据库期望 "player"/"opponent"/"draw"，我们转化为相对胜者
                        // 我们假设在 AI 模式中玩家执黑，本地模式中可能有黑有白，我们更细致处理
                        if (gameMode === "ai") {
                            winner = "player"   // AI 模式黑棋是玩家
                        } else if (gameMode === "local") {
                            // 本地模式没有明确的玩家/对手，我们存为 "黑胜"
                            winner = "黑胜"
                        } else if (gameMode === "lan") {
                            // 局域网模式，根据 isHost 判断：host 执黑
                            // 但 game 对象没有 isHost，我们可以从网络状态推断，或直接存 "黑胜"
                            winner = "黑胜"
                        }
                    } else if (wt.includes("白") || wt.includes("白棋")) {
                        if (gameMode === "ai") {
                            winner = "opponent"   // AI 模式白棋是 AI
                        } else if (gameMode === "local") {
                            winner = "白胜"
                        } else if (gameMode === "lan") {
                            winner = "白胜"
                        }
                    } else if (wt.includes("平") || wt.includes("和")) {
                        winner = "draw"
                    }
                }

                // 步数
                var moves = game.movesCount ? game.movesCount : 0

                // 保存记录
                if (typeof dbManager !== 'undefined' && dbManager) {
                    var success = dbManager.saveGameRecord(playerName, opponentName, winner, moves)
                    console.log("保存记录结果:", success)
                }
            }
        }
    }
}
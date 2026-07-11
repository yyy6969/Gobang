import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: root

    //外部属性
    property int cellSize: 30
    property int boardX: 0
    property int boardY: 0
    property var gameController: null
    property bool myTurn: true
    property bool showScore: true
    property bool showForbidden: false

    //信号
    signal placeRequested(int row, int col)

    //内部状态
    property int previewRow: -1
    property int previewCol: -1

    //预览棋子
    Rectangle {
        id: preview
        width: root.cellSize * 0.8
        height: width
        radius: width / 2
        opacity: 0.0
        visible: false
        z: 10

        color: {
            if (!gameController) return "gray"
            return gameController.currentPlayer === 0 ? "#2c2c2c" : "#f8f9fa"
        }
        border.width: 2
        border.color: "gold"

        Rectangle {
            anchors.fill: parent
            anchors.margins: -4
            radius: parent.radius + 4
            color: "transparent"
            border.color: "gold"
            border.width: 1
            opacity: 0.3
            z: -1
        }

        Behavior on opacity {
            NumberAnimation { duration: 150; easing.type: Easing.InOutQuad }
        }
    }

    //评分信息标签
    Rectangle {
        id: scoreBg
        visible: false
        color: "#80000000"
        radius: 6
        opacity: 0.85
        z: 11
        width: scoreText.contentWidth + 18
        height: scoreText.contentHeight + 12
        x: preview.x + preview.width + 6
        y: preview.y - height / 2 + preview.height / 2

        Text {
            id: scoreText
            text: ""
            font.pixelSize: 14
            font.bold: true
            color: "white"
            anchors.centerIn: parent
            style: Text.Outline
            styleColor: "black"
        }
    }

    //禁手警告（预留）
    Rectangle {
        id: forbiddenIndicator
        visible: false
        width: root.cellSize * 0.9
        height: width
        radius: width / 2
        color: "transparent"
        border.width: 3
        border.color: "red"
        z: 12
        x: preview.x - (width - preview.width) / 2
        y: preview.y - (height - preview.height) / 2
        SequentialAnimation on opacity {
            id: forbiddenBlink
            running: false
            loops: Animation.Infinite
            NumberAnimation { from: 0.3; to: 1.0; duration: 300 }
            NumberAnimation { from: 1.0; to: 0.3; duration: 300 }
        }
    }

    //交互区域
    Item {
        id: inputArea
        x: root.boardX - root.cellSize / 2
        y: root.boardY - root.cellSize / 2
        width: 14 * root.cellSize + root.cellSize
        height: 14 * root.cellSize + root.cellSize

        enabled: gameController && !gameController.gameOver && (myTurn || gameController.gameMode === 0)

        //点击处理（两步操作）
        TapHandler {
            id: tapHandler
            acceptedButtons: Qt.LeftButton
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad | PointerDevice.TouchScreen
            enabled: inputArea.enabled
            onTapped: {
                var pos = getRowColFromPoint(point.position.x, point.position.y)
                if (!pos.valid) {
                    clearPreview()
                    return
                }

                var row = pos.row
                var col = pos.col

                //如果该位置已有棋子，则清除预览
                if (gameController.pieceAt(row, col) !== 0) {
                    clearPreview()
                    return
                }

                //如果当前没有预览，或者预览位置与点击位置不同，则更新预览（第一次点击）
                if (previewRow !== row || previewCol !== col) {
                    updatePreview(row, col)
                } else {
                    //第二次点击同一位置确认落子
                    placeRequested(row, col)
                    clearPreview()
                }
            }
        }
    }

    //坐标计算函数
    function getRowColFromPoint(mx, my) {
        var localX = mx - root.cellSize / 2
        var localY = my - root.cellSize / 2
        var col = Math.round(localX / root.cellSize)
        var row = Math.round(localY / root.cellSize)
        if (row < 0 || row >= 15 || col < 0 || col >= 15) {
            return { row: -1, col: -1, valid: false }
        }
        return { row: row, col: col, valid: true }
    }

    //更新预览
    function updatePreview(row, col) {
        if (row < 0 || row >= 15 || col < 0 || col >= 15 ||
            gameController.pieceAt(row, col) !== 0) {
            clearPreview()
            return
        }
        preview.x = root.boardX + col * root.cellSize - preview.width / 2
        preview.y = root.boardY + row * root.cellSize - preview.height / 2
        preview.visible = true
        preview.opacity = 0.7

        if (showScore) {
            var score = calculateScore(row, col, gameController.currentPlayer + 1)
            if (score > 0) {
                scoreText.text = "评分: " + score
                scoreBg.visible = true
                scoreBg.x = preview.x + preview.width + 6
                scoreBg.y = preview.y - scoreBg.height / 2 + preview.height / 2
            } else {
                scoreBg.visible = false
            }
        }

        if (showForbidden && checkForbidden(row, col)) {
            forbiddenIndicator.visible = true
            forbiddenBlink.restart()
        } else {
            forbiddenIndicator.visible = false
            forbiddenBlink.stop()
        }

        root.previewRow = row
        root.previewCol = col
    }

    function clearPreview() {
        preview.visible = false
        preview.opacity = 0.0
        scoreBg.visible = false
        forbiddenIndicator.visible = false
        forbiddenBlink.stop()
        root.previewRow = -1
        root.previewCol = -1
    }

    //评分计算
    function calculateScore(row, col, pieceColor) {
        if (!gameController) return 0
        if (typeof gameController.evaluatePosition === "function") {
            return gameController.evaluatePosition(row, col, pieceColor)
        }
        var dirs = [[0,1],[1,0],[1,1],[1,-1]]
        var total = 0
        for (var d = 0; d < dirs.length; d++) {
            var count = 1
            for (var step=1; step<5; step++) {
                var nr = row + dirs[d][0]*step
                var nc = col + dirs[d][1]*step
                if (nr<0||nr>=15||nc<0||nc>=15) break
                var p = gameController.pieceAt(nr, nc)
                if (p === pieceColor) count++
                else if (p === 0) break
                else break
            }
            for (step=1; step<5; step++) {
                nr = row - dirs[d][0]*step
                nc = col - dirs[d][1]*step
                if (nr<0||nr>=15||nc<0||nc>=15) break
                p = gameController.pieceAt(nr, nc)
                if (p === pieceColor) count++
                else if (p === 0) break
                else break
            }
            if (count >= 5) total += 1000000
            else if (count === 4) total += 100000
            else if (count === 3) total += 5000
            else if (count === 2) total += 100
            else if (count === 1) total += 1
        }
        return total
    }

    function checkForbidden(row, col) {
        if (!gameController || gameController.currentPlayer !== 0) return false
        return false
    }

    Connections {
        target: gameController
        function onGameOverChanged() {
            if (gameController.gameOver) clearPreview()
        }
        function onTurnChanged() {
            //当回合改变时，清除预览（因为轮到对方或AI）
            clearPreview()
        }
    }
}
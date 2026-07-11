// File: MainMenu.qml
// 游戏主页组件（优化版。设置 + 左上角名字 + 难度对话框）

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: menuRoot
    width: Screen.width
    height: Screen.height
    color: "#1a1a2e"

    signal localGame()
    signal aiGame(int difficulty)      // 0=简单, 1=一般, 2=困难
    signal lanGameStart()
    signal historyRequest()

    //玩家名字（左上角）
    property string userName: (typeof dbManager !== 'undefined' && dbManager) ? dbManager.getUserName() : ""

    Text {
        id: nameDisplay
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: 20
        text: userName !== "" ? "👤 " + userName : "👤 未命名"
        font.pixelSize: 18
        font.bold: true
        color: "#e0e0e0"
        visible: true
        z: 10
    }

    //设置对话框
    Dialog {
        id: settingsDialog
        modal: true
        title: "设置"
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        width: 360
        height: 280
        focus: true
        standardButtons: Dialog.Ok | Dialog.Cancel

        Column {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 20

            Label {
                text: "玩家名称"
                font.pixelSize: 16
                color: "#2c3e50"
            }

            TextField {
                id: settingNameInput
                width: parent.width
                placeholderText: "输入你的名字"
                text: userName
                font.pixelSize: 14
                color: "#2c3e50"
                background: Rectangle {
                    color: "#f5f5f5"
                    radius: 6
                    border.color: "#ddd"
                    border.width: 1
                }
            }

            Text {
                id: settingSaveStatus
                text: ""
                font.pixelSize: 12
                color: "green"
                visible: false
            }

            Item { height: 10 }

            RowLayout {
                width: parent.width
                spacing: 10
                Button {
                    text: "保存设置"
                    Layout.fillWidth: true
                    font.pixelSize: 14
                    background: Rectangle {
                        color: parent.hovered ? "#2980b9" : "#3498db"
                        radius: 6
                    }
                    contentItem: Text {
                        text: "保存设置"
                        color: "white"
                        font: parent.font
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: {
                        if (typeof dbManager !== 'undefined' && dbManager) {
                            var success = dbManager.setUserName(settingNameInput.text)
                            if (success) {
                                settingSaveStatus.text = "✅ 已保存"
                                settingSaveStatus.color = "lightgreen"
                                settingSaveStatus.visible = true
                                // 更新左上角名字
                                userName = settingNameInput.text
                            } else {
                                settingSaveStatus.text = "❌ 保存失败"
                                settingSaveStatus.color = "red"
                                settingSaveStatus.visible = true
                            }
                        } else {
                            settingSaveStatus.text = "❌ dbManager 未就绪"
                            settingSaveStatus.color = "red"
                            settingSaveStatus.visible = true
                        }
                    }
                }
                Button {
                    text: "取消"
                    Layout.fillWidth: true
                    font.pixelSize: 14
                    background: Rectangle {
                        color: parent.hovered ? "#7f8c8d" : "#95a5a6"
                        radius: 6
                    }
                    contentItem: Text {
                        text: "取消"
                        color: "white"
                        font: parent.font
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: settingsDialog.close()
                }
            }
        }

        onAccepted: {
            if (typeof dbManager !== 'undefined' && dbManager) {
                dbManager.setUserName(settingNameInput.text)
                userName = settingNameInput.text
            }
            settingsDialog.close()
        }
        onRejected: {
            settingsDialog.close()
        }
    }

    //人机对战难度选择对话框
    Dialog {
        id: aiDifficultyDialog
        modal: true
        title: "选择难度"
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        width: 360
        height: 280
        focus: true
        standardButtons: Dialog.Ok | Dialog.Cancel

        property int selectedDifficulty: 1   // 默认一般

        Column {
            anchors.fill: parent
            anchors.margins: 30
            spacing: 25

            Label {
                text: "请选择难度，越往右越难"
                font.pixelSize: 20
                font.bold: true
                color: "#2c3e50"
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Column {
                spacing: 20
                width: parent.width
                anchors.horizontalCenter: parent.horizontalCenter

                // 滑动条
                Slider {
                    id: difficultySlider
                    from: 0
                    to: 2
                    stepSize: 1
                    value: 1
                    width: parent.width
                    onValueChanged: {
                        // 更新显示文字
                        difficultyLabel.text = difficultyText(value)
                    }
                }

                // 显示当前难度文字
                Label {
                    id: difficultyLabel
                    text: difficultyText(difficultySlider.value)
                    font.pixelSize: 22
                    font.bold: true
                    color: "#2980b9"
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                // 刻度标记
                Row {
                    width: difficultySlider.width
                    spacing: (width - 40) / 2
                    anchors.horizontalCenter: parent.horizontalCenter

                    Text { text: "简单"; font.pixelSize: 14; color: "#7f8c8d" }
                    Text { text: "一般"; font.pixelSize: 14; color: "#7f8c8d" }
                    Text { text: "困难"; font.pixelSize: 14; color: "#7f8c8d" }
                }
            }
        }

        //辅助函数：根据数值返回文字
        function difficultyText(val) {
            if (val < 0.5) return "简单"
            if (val < 1.5) return "一般"
            return "困难"
        }

        onAccepted: {
            //传递选中难度（四舍五入）
            selectedDifficulty = Math.round(difficultySlider.value)
            aiGame(selectedDifficulty)
            close()
        }
        onRejected: {
            close()
        }
    }
    //背景
    Image {
        id: background
        anchors.fill: parent
        source: "qrc:/image/background.jpg"
        fillMode: Image.PreserveAspectCrop
        opacity: 0.7
    }

    //主标题
    Column {
        anchors.top: parent.top
        anchors.topMargin: 40
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 8

        Text {
            text: "五子棋"
            font.pixelSize: 56
            font.bold: true
            font.family: "FZSuXinShiLiuKaiS-R-GB"
            color: "#000000"
            anchors.horizontalCenter: parent.horizontalCenter
        }
        Text {
            text: "Gomoku · 五子连珠"
            font.pixelSize: 18
            font.italic: true
            color: "#f0fff0"
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    //游戏按钮
    Column {
        anchors.centerIn: parent
        spacing: 20
        width: 280

        component GameButton: Button {
            id: btn
            width: 280
            height: 60
            font.pixelSize: 20
            font.bold: true
            background: Rectangle {
                color: {
                    if (btn.down) return "#1f2a4e"
                    if (btn.hovered) return "#696969"
                    return "#a9a9a9"
                }
                radius: 30
                border.color: "#708090"
                border.width: 2
                Behavior on color { ColorAnimation { duration: 150 } }
            }
            contentItem: Text {
                text: btn.text
                font: btn.font
                color: btn.hovered ? "#000000" : "#e0e0e0"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }

        GameButton {
            text: "🏠 本地对战"
            onClicked: localGame()
        }

        GameButton {
            id: aiButton
            text: "🤖 人机对战"
            onClicked: aiDifficultyDialog.open()
        }

        GameButton {
            text: "🌐 局域网对战"
            onClicked: lanDialog.open()
        }

        GameButton {
            text: "📜 对战记录"
            onClicked: historyRequest()
        }
    }

    //右上角显眼设置图标
    Button {
        id: settingsButton
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 20
        width: 56
        height: 56
        background: Rectangle {
            color: parent.hovered ? "#7f8c8d" : "#a9a9a9"
            radius: 28
            border.color: "#ecf0f1"
            border.width: 2
            Behavior on color { ColorAnimation { duration: 150 } }
        }
        contentItem: Text {
            text: "⚙️"
            font.pixelSize: 32
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        onClicked: settingsDialog.open()
    }

    //底部版本信息
    Text {
        text: "v2.3 · 支持局域网对战 & 三档AI"
        font.pixelSize: 12
        color: "#f0ffff"
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 20
        anchors.horizontalCenter: parent.horizontalCenter
    }

    //局域网连接对话框
    Dialog {
        id: lanDialog
        modal: true
        focus: true
        title: "局域网对战"
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        width: 300
        height: 380

        property bool isHost: true
        property string serverIp: "127.0.0.1"
        property int port: 8888
        property string connectionMethod: "ip"
        property string nfcStatusText: ""

        Timer {
            id: nfcTimeoutTimer
            interval: 10000
            repeat: false
            onTriggered: {
                if (lanDialog.connectionMethod === "nfc" && nfcStatusText !== "连接成功") {
                    nfcStatusText = "连接超时，请重试"
                    nfcManager.stopNfc()
                    if (lanDialog.isHost) game.cancelNetwork()
                }
            }
        }

        Connections {
            target: nfcManager
            function onHostInfoReceived(ip, port) {
                nfcTimeoutTimer.stop()
                lanDialog.nfcStatusText = "连接成功！正在建立游戏..."
                game.connectToServer(ip, port)
            }
            function onErrorOccurred(message) {
                nfcTimeoutTimer.stop()
                nfcHintDialog.msgText = "NFC 错误：" + message
                nfcHintDialog.open()
                lanDialog.nfcStatusText = "连接失败，请重试"
            }
            function onTargetDetected() {
                lanDialog.nfcStatusText = "已检测到对方设备，正在传输信息..."
            }
        }

        Connections {
            target: game
            function onNetworkStatusChanged() {
                if (lanDialog.connectionMethod === "nfc" && game.networkStatus.includes("已连接")) {
                    nfcTimeoutTimer.stop()
                    lanDialog.close()
                    lanGameStart()
                }
            }
        }

        ButtonGroup { id: connectionGroup }
        ButtonGroup { id: roleGroup }

        ColumnLayout {
            anchors.fill: parent
            spacing: 10

            RowLayout {
                spacing: 20
                Layout.alignment: Qt.AlignHCenter
                RadioButton {
                    ButtonGroup.group: connectionGroup
                    text: "IP连接"
                    checked: true
                    onCheckedChanged: { if (checked) lanDialog.connectionMethod = "ip" }
                }
                RadioButton {
                    ButtonGroup.group: connectionGroup
                    text: "NFC连接"
                    onCheckedChanged: { if (checked) lanDialog.connectionMethod = "nfc" }
                }
            }

            RowLayout {
                spacing: 20
                Layout.alignment: Qt.AlignHCenter
                RadioButton {
                    ButtonGroup.group: roleGroup
                    text: "创建房间"
                    checked: true
                    onCheckedChanged: { if (checked) lanDialog.isHost = true }
                }
                RadioButton {
                    ButtonGroup.group: roleGroup
                    text: "加入房间"
                    onCheckedChanged: { if (checked) lanDialog.isHost = false }
                }
            }

            ColumnLayout {
                visible: lanDialog.connectionMethod === "ip"
                spacing: 10
                RowLayout {
                    visible: !lanDialog.isHost
                    Label { text: "服务器IP:" }
                    TextField {
                        text: lanDialog.serverIp
                        onTextChanged: lanDialog.serverIp = text
                    }
                }
                RowLayout {
                    Label { text: "端口:" }
                    TextField {
                        text: lanDialog.port.toString()
                        validator: IntValidator { bottom: 1024; top: 65535 }
                        onTextChanged: {
                            var val = parseInt(text)
                            if (!isNaN(val)) lanDialog.port = val
                        }
                    }
                }
            }

            ColumnLayout {
                visible: lanDialog.connectionMethod === "nfc"
                Label {
                    text: lanDialog.nfcStatusText !== "" ? lanDialog.nfcStatusText : "点击确定开始配对"
                    color: lanDialog.nfcStatusText.startsWith("等待") ? "green" : "gray"
                    font.italic: true
                    Layout.alignment: Qt.AlignHCenter
                }
            }

            RowLayout {
                spacing: 20
                Layout.alignment: Qt.AlignRight
                Button {
                    text: "确定"
                    onClicked: {
                        if (lanDialog.connectionMethod === "nfc") {
                            if (lanDialog.isHost) {
                                var ip = nfcManager.getLocalIp()
                                if (ip === "") {
                                    nfcHintDialog.msgText = "无法获取本机 IP，请检查网络连接"
                                    nfcHintDialog.open()
                                    return
                                }
                                if (!game.startHost(lanDialog.port)) {
                                    nfcHintDialog.msgText = "启动服务器失败，端口可能被占用"
                                    nfcHintDialog.open()
                                    return
                                }
                                if (!nfcManager.startNfc()) {
                                    nfcHintDialog.msgText = "NFC 启动失败"
                                    nfcHintDialog.open()
                                    return
                                }
                                nfcManager.sendHostInfo(ip, lanDialog.port)
                                lanDialog.nfcStatusText = "正在等待对方设备...（请将两部手机背部靠近）"
                            } else {
                                if (!nfcManager.startNfc()) {
                                    nfcHintDialog.msgText = "NFC 启动失败"
                                    nfcHintDialog.open()
                                    return
                                }
                                lanDialog.nfcStatusText = "正在等待主机信息...（请将两部手机背部靠近）"
                            }
                            nfcTimeoutTimer.start()
                        } else {
                            lanDialog.accept()
                        }
                    }
                }
                Button {
                    text: "取消"
                    onClicked: {
                        if (lanDialog.connectionMethod === "nfc") {
                            nfcTimeoutTimer.stop()
                            nfcManager.stopNfc()
                            if (lanDialog.isHost) game.cancelNetwork()
                            lanDialog.nfcStatusText = ""
                        }
                        lanDialog.close()
                    }
                }
            }
        }

        onAccepted: {
            if (isHost) game.startHost(port)
            else game.connectToServer(serverIp, port)
            lanGameStart()
            close()
        }

        onRejected: {
            if (lanDialog.connectionMethod === "nfc") {
                nfcManager.stopNfc()
                lanDialog.nfcStatusText = ""
            }
            close()
        }
    }

    // NFC 提示对话框
    Dialog {
        id: nfcHintDialog
        modal: true
        title: "提示"
        standardButtons: Dialog.Ok
        property string msgText: ""
        Label {
            text: nfcHintDialog.msgText
            anchors.centerIn: parent
        }
    }

    //初始化
    Component.onCompleted: {
        // 刷新名字显示
        if (typeof dbManager !== 'undefined' && dbManager) {
            userName = dbManager.getUserName()
        }
    }
}
// File: MainMenu.qml
// 游戏主页组件
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: menuRoot
    width: Screen.width
    height: Screen.height
    color: "#1a1a2e"

    signal localGame()
    signal aiGame(int difficulty)
    signal lanGameStart()
    signal historyRequest()

    Component.onCompleted: {
        console.log("dbManager exists?", typeof dbManager !== 'undefined')
        if (dbManager) console.log("getUserName returns:", dbManager.getUserName())
    }

    Image {
        id: background
        anchors.fill: parent
        source: "qrc:/image/background.jpg"
        fillMode: Image.PreserveAspectCrop
        opacity: 0.7
    }

    // 局域网连接对话框
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

        // 当客户端通过 NFC 收到主机信息后自动连接
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

        // 游戏网络状态变化（TCP 连接建立后自动开始游戏）
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

        ButtonGroup {
            id: connectionGroup
        }
        ButtonGroup {
            id: roleGroup
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 10

            // 连接方式选择
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

            // 角色选择（始终可见）
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

            // IP 设置区域（仅在 IP 模式下可见）
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

            // NFC 状态提示（仅在 NFC 模式下可见）
            ColumnLayout {
                visible: lanDialog.connectionMethod === "nfc"
                Label {
                    text: lanDialog.nfcStatusText !== "" ? lanDialog.nfcStatusText : "点击确定开始配对"
                    color: lanDialog.nfcStatusText.startsWith("等待") ? "green" : "gray"
                    font.italic: true
                    Layout.alignment: Qt.AlignHCenter
                }
            }

            // 确定 / 取消按钮
            RowLayout {
                spacing: 20
                Layout.alignment: Qt.AlignRight

                Button {
                    text: "确定"
                    onClicked: {
                        if (lanDialog.connectionMethod === "nfc") {
                            // ── NFC 模式 ──
                            if (lanDialog.isHost) {
                                // 主机：获取 IP，启动服务器，启动 NFC 并发送信息
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
                                // 客户端：仅启动 NFC 等待接收
                                if (!nfcManager.startNfc()) {
                                    nfcHintDialog.msgText = "NFC 启动失败"
                                    nfcHintDialog.open()
                                    return
                                }
                                lanDialog.nfcStatusText = "正在等待主机信息...（请将两部手机背部靠近）"
                            }
                            nfcTimeoutTimer.start()
                        } else {
                            // ── IP 模式 ──
                            lanDialog.accept()   // 触发 onAccepted
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

        // IP 模式下的 accept 逻辑
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

    // 主菜单界面
    Text {
        id: title
        text: "五子棋"
        font.pixelSize: 56
        font.bold: true
        font.family: "FZSuXinShiLiuKaiS-R-GB"
        color: "#000000"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 80
    }

    Text {
        id: title1
        text: "Gomoku · 五子连珠"
        font.pixelSize: 18
        font.italic: true
        color: "#f0fff0"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: title.bottom
        anchors.topMargin: 12
    }

    // 用户名输入和状态反馈
    Column {
        id: nameColumn
        anchors.top: title1.bottom
        anchors.topMargin: 10
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 4

        TextField {
            id: nameInput
            width: 200
            text: (typeof dbManager !== 'undefined' && dbManager) ? dbManager.getUserName() : ""
            placeholderText: "输入你的名字"
            color: "white"
            font.pixelSize: 16
            background: Rectangle {
                color: Qt.rgba(255, 255, 255, 0.1)
                border.color: "#aaa"
                border.width: 1
                radius: 6
            }
            onEditingFinished: {
                if (typeof dbManager !== 'undefined' && dbManager) {
                    var success = dbManager.setUserName(text)
                    if (success) {
                        saveStatus.text = "✅ 已保存"
                        saveStatus.color = "lightgreen"
                    } else {
                        saveStatus.text = "❌ 保存失败，请检查日志"
                        saveStatus.color = "red"
                    }
                    console.log("用户名已保存:", text)
                } else {
                    saveStatus.text = "❌ dbManager 未就绪"
                    saveStatus.color = "red"
                }
            }
        }

        Text {
            id: saveStatus
            font.pixelSize: 12
            color: "lightgreen"
            text: ""
        }
    }

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
            onClicked: aiGame(aiCombo.currentIndex)
        }

        RowLayout {
            spacing: 10
            Layout.alignment: Qt.AlignHCenter
            Label {
                text: "难度："
                color: "#e0e0e0"
                font.pixelSize: 16
            }
            ComboBox {
                id: aiCombo
                model: ["简单", "一般", "困难"]
                currentIndex: 1
                font.pixelSize: 14
                implicitWidth: 100
                background: Rectangle {
                    color: "#a9a9a9"
                    radius: 6
                }
                contentItem: Text {
                    text: aiCombo.displayText
                    color: "white"
                    font.pixelSize: 14
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                delegate: ItemDelegate {
                    id: delegate
                    width: aiCombo.width
                    contentItem: Text {
                        text: modelData
                        color: "#000000"
                        font.pixelSize: 14
                    }
                    background: Rectangle {
                        color: delegate.hovered ? "#708090" : "#a9a9a9"
                        Behavior on color { ColorAnimation { duration: 60 } }
                    }
                }
            }
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

    Text {
        text: "v2.0 · 支持局域网对战 & 三档AI"
        font.pixelSize: 12
        color: "#f0ffff"
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 20
        anchors.horizontalCenter: parent.horizontalCenter
    }
}

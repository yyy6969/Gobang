import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: menuRoot
    width: 800
    height: 650
    color: "#1a1a2e"

    signal localGame()
    signal aiGame(int difficulty)   // 难度: 0简单,1一般,2困难
    signal lanGameStart()

    // 局域网连接对话框（省略，同上）
    Dialog {
        id: lanDialog
        modal: true
        focus: true
        title: "局域网对战"
        standardButtons: Dialog.Ok | Dialog.Cancel
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        width: 300
        height: 200

        property bool isHost: true
        property string serverIp: "127.0.0.1"
        property int port: 8888

        ColumnLayout {
            anchors.fill: parent
            spacing: 10

            RowLayout {
                RadioButton {
                    text: "创建房间"
                    checked: true
                    onCheckedChanged: { if (checked) lanDialog.isHost = true }
                }
                RadioButton {
                    text: "加入房间"
                    onCheckedChanged: { if (checked) lanDialog.isHost = false }
                }
            }

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
                    text: "8888"
                    validator: IntValidator { bottom: 1024; top: 65535 }
                    onTextChanged: lanDialog.port = parseInt(text)
                }
            }
        }

        onAccepted: {
            if (isHost) game.startHost(port)
            else game.connectToServer(serverIp, port)
            lanGameStart()
        }
    }

    // 背景装饰
    Rectangle {
        anchors.centerIn: parent
        width: parent.width * 0.8
        height: parent.height * 0.6
        radius: 300
        color: "#0f3460"
        opacity: 0.4
    }

    Text {
        id: title
        text: "五子棋"
        font.pixelSize: 56
        font.bold: true
        font.family: "Microsoft YaHei"
        color: "#e94560"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 80
    }

    Text {
        text: "Gomoku · 五子连珠"
        font.pixelSize: 18
        font.italic: true
        color: "#a0a0c0"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: title.bottom
        anchors.topMargin: 12
    }

    Column {
        anchors.centerIn: parent
        spacing: 20
        width: 280

        // 通用按钮样式
        component GameButton: Button {
            id: btn
            width: 280
            height: 60
            font.pixelSize: 20
            font.bold: true
            background: Rectangle {
                color: btn.down ? "#1f2a4e" : (btn.hovered ? "#1f2a4e" : "#16213e")
                radius: 30
                border.color: "#e94560"
                border.width: 2
                Behavior on color { ColorAnimation { duration: 150 } }
            }
            contentItem: Text {
                text: btn.text
                font: btn.font
                color: btn.hovered ? "#ff6b6b" : "#e0e0e0"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }

        // 本地对战
        GameButton {
            text: "🏠 本地对战"
            onClicked: localGame()
        }

        // 人机对战按钮（上方）
        GameButton {
            id: aiButton
            text: "🤖 人机对战"
            onClicked: aiGame(aiCombo.currentIndex)
        }

        // 难度选择区域（紧跟在人机对战按钮下方）
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
                    color: "#2a2a4a"
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
                    width: aiCombo.width
                    contentItem: Text {
                        text: modelData
                        color: "white"
                        font.pixelSize: 14
                    }
                    background: Rectangle {
                        color: parent.highlighted ? "#e94560" : "#2a2a4a"
                    }
                }
            }
        }

        // 局域网对战
        GameButton {
            text: "🌐 局域网对战"
            onClicked: lanDialog.open()
        }
    }

    Text {
        text: "v1.0 · 支持局域网对战 & 三档AI"
        font.pixelSize: 12
        color: "#606080"
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 20
        anchors.horizontalCenter: parent.horizontalCenter
    }
}
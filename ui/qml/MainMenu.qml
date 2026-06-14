import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id: menuRoot
    width: 800
    height: 650
    color: "#1a1a2e"

    // 信号：三个按钮分别发出
    signal localGame()
    signal lanGame()
    signal aiGame()

    // 背景装饰 – 光晕
    Rectangle {
        anchors.centerIn: parent
        width: parent.width * 0.8
        height: parent.height * 0.6
        radius: 300
        color: "#0f3460"
        opacity: 0.4
        // 如果需要模糊，可以添加层效果（可选）
    }

    // 主标题
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

    // 副标题
    Text {
        text: "Gomoku · 五子连珠"
        font.pixelSize: 18
        font.italic: true
        color: "#a0a0c0"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: title.bottom
        anchors.topMargin: 12
    }

    // 按钮列
    Column {
        anchors.centerIn: parent
        spacing: 30
        width: 280

        // 按钮组件（复用）
        component GameButton: Button {
            id: btn
            width: 280
            height: 70
            text: ""
            font.pixelSize: 24
            font.bold: true

            background: Rectangle {
                color: btn.down ? "#1f2a4e" : (btn.hovered ? "#1f2a4e" : "#16213e")
                radius: 40
                border.color: "#e94560"
                border.width: 2

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
            }

            contentItem: Text {
                text: btn.text
                font: btn.font
                color: btn.hovered ? "#ff6b6b" : "#e0e0e0"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
            }
        }

        GameButton {
            text: "🏠 本地对战"
            onClicked: localGame()
        }

        GameButton {
            text: "🌐 局域网对战"
            onClicked: lanGame()
        }

        GameButton {
            text: "🤖 人机对战"
            onClicked: aiGame()
        }
    }

    // 底部信息
    Text {
        text: "v1.0 · 五子棋引擎"
        font.pixelSize: 12
        color: "#606080"
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 20
        anchors.horizontalCenter: parent.horizontalCenter
    }
}
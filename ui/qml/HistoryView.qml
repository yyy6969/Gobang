import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id: root
    color: "#1a1a2e"

    signal backToMenu()

    // 背景
    Image {
        anchors.fill: parent
        source: "qrc:/image/background.jpg"
        fillMode: Image.PreserveAspectCrop
        opacity: 0.6
    }

    // 标题栏（类似顶部栏）
    Rectangle {
        id: topBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 60
        color: "transparent"
        z: 10

        Row {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 10

            Button {
                text: "← 返回"
                font.pixelSize: 16
                implicitWidth: 80
                implicitHeight: 36
                background: Rectangle {
                    color: parent.hovered ? "#696969" : "#a9a9a9"
                    radius: 18
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

            Text {
                text: "对战记录"
                font.pixelSize: 20
                font.bold: true
                color: "white"
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    // 记录列表
    ListView {
        id: listView
        anchors.top: topBar.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 10
        spacing: 5
        clip: true
        model: []

        delegate: Rectangle {
            width: parent.width
            height: 60
            color: index % 2 === 0 ? "#f0f0f0" : "#e0e0e0"
            radius: 4
            Column {
                anchors.fill: parent
                anchors.margins: 6
                spacing: 2
                Text {
                    text: modelData.playerName + " vs " + modelData.opponentName
                    font.pixelSize: 14
                    font.bold: true
                }
                Text {
                    text: "胜者: " + modelData.winner + "  步数: " + modelData.movesCount + "  时间: " + modelData.gameTime
                    font.pixelSize: 12
                    color: "#555"
                }
            }
        }

        ScrollBar.vertical: ScrollBar {}

        // 空状态提示
        Text {
            anchors.centerIn: parent
            text: "暂无对战记录"
            color: "#888"
            font.pixelSize: 16
            visible: listView.count === 0
        }
    }

    // 加载数据
    Component.onCompleted: {
        if (typeof dbManager !== 'undefined' && dbManager) {
            listView.model = dbManager.getAllRecords()
        }
    }
}
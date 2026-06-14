import QtQuick 2.15
import QtQuick.Controls 2.15

ApplicationWindow {
    id: root
    visible: true
    width: 800
    height: 650
    title: "五子棋"

    // 页面栈
    StackView {
        id: stackView
        anchors.fill: parent
        initialItem: mainMenuPage
    }

    // 主菜单组件
    Component {
        id: mainMenuPage
        MainMenu {
            onLocalGame: {
                stackView.push(gamePage, { gameMode: "local" })
            }
            onLanGame: {
                stackView.push(gamePage, { gameMode: "lan" })
            }
            onAiGame: {
                stackView.push(gamePage, { gameMode: "ai" })
            }
        }
    }

    // 游戏界面组件
    Component {
        id: gamePage
        GameView {
            onBackToMenu: stackView.pop()
        }
    }
}
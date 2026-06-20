import QtQuick 2.15
import QtQuick.Controls 2.15

ApplicationWindow {
    id: root
    visible: true
    width: 1000
    height: 700
    title: "五子棋"
    minimumWidth: 1000
       maximumWidth: 1000
       minimumHeight: 700
       maximumHeight: 700

    StackView {
        id: stackView
        anchors.fill: parent
        initialItem: mainMenuPage
    }

    Component {
        id: mainMenuPage
        MainMenu {
            onLocalGame: {
                game.setGameMode(0)
                stackView.push(gamePage, { gameMode: "local" })
            }
            onAiGame: function(difficulty) {
                game.setGameMode(1)
                game.setAIDifficulty(difficulty)
                stackView.push(gamePage, { gameMode: "ai" })
            }
            onLanGameStart: {
                stackView.push(gamePage, { gameMode: "lan" })
            }
        }
    }

    Component {
        id: gamePage
        GameView {
            onBackToMenu: {
                game.cancelNetwork()
                stackView.pop()
            }
        }
    }
}

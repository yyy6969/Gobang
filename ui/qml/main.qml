import QtQuick 2.15
import QtQuick.Controls 2.15

ApplicationWindow {
    id: root
    visible: true
    width: Screen.width
    height: Screen.height
    minimumWidth: width
    maximumWidth: width
    minimumHeight: height
    maximumHeight: height
    title: "五子棋"

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

            onHistoryRequest: {
                stackView.push(historyPage)
            }
        }
    }

    Component {
        id: gamePage
        GameView {
            gameMode: typeof gameMode !== "undefined" ? gameMode : "local"
            onBackToMenu: {
                game.cancelNetwork()
                stackView.pop()
            }
        }
    }

    Component {
        id: historyPage
        HistoryView {
            onBackToMenu: {
                stackView.pop()
            }
        }
    }
}
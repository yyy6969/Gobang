import QtQuick 2.15
import QtQuick.Controls 2.15
import com.yourcompany.gobang 1.0

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


    // 创建实例，id 命名为 game 和 dbManager
    GameController {
        id: game
    }
    DatabaseManager {
        id: dbManager
    }

    StackView {
        id: stackView
        anchors.fill: parent
        initialItem: mainMenuPage
    }

    Component {
        id: mainMenuPage
        MainMenu {
            GameController: game
            dbManager: dbManager

            onLocalGame: {
                game.setGameMode(0)
                stackView.push(gamePage, { gameMode: "local", isHost: true })
            }
            onAiGame: function(difficulty) {
                game.setGameMode(1)
                game.setAIDifficulty(difficulty)
                stackView.push(gamePage, { gameMode: "ai", isHost: true })
            }
            onLanGameStart: {
                stackView.push(gamePage, { gameMode: "lan", isHost: game.isHost() })
            }
            onHistoryRequest: {
                stackView.push(historyPage)
            }
        }
    }

    Component {
        id: gamePage
        GameView {
            property var gameController: null
            property var dbManager: null

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
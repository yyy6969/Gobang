// File: game_controller.cpp
// Created: YuHaoRan   1730822455@qq.com   2026-06-22 11:09:07
// Description:游戏控制主页
import QtQuick 2.15
import QtQuick.Controls 2.15

ApplicationWindow {
    id: root
    visible: true
    // 改为根据屏幕动态计算
    width: Screen.width
    height: Screen.height
    minimumWidth: width
    maximumWidth: width
    minimumHeight: height
    maximumHeight: height
    title: "五子棋"

    property real scaleFactor: Math.min(Screen.width / 1080, Screen.height / 1920)

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
            scaleFactor: root.scaleFactor
            onBackToMenu: {
                game.cancelNetwork()
                stackView.pop()
            }
        }
    }
}

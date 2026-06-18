cmake_minimum_required(VERSION 3.19)
project(Gonbal_My_Game LANGUAGES CXX)

# 只需要 QML 相关模块，不再需要 Widgets 和 QuickWidgets
find_package(Qt6 6.5 REQUIRED COMPONENTS Core Qml Quick QuickControls2)

qt_standard_project_setup()

# 只包含真正的 C++ 源文件（删除文档、图片、QML 文件、UI 文件）
qt_add_executable(Gonbal_My_Game
    WIN32 MACOSX_BUNDLE
    main.cpp
    core/ai_player.cpp
    core/board.cpp
    core/gomoku_engine.cpp
    core/human_player.cpp
    core/timer_manager.cpp
    ui/game_controller.cpp
    # 如果你还有 network 模块且需要编译，取消注释下面三行
    nerwork/game_client.cpp
    nerwork/game_server.cpp
    nerwork/network_player.cpp
)

# 将 QML 文件编译为资源（qrc）
# 注意：你的 QML 文件路径是 ui/qml/BoardView.qml、GameView.qml、MainScreen.qml
# 但为了主菜单和入口，你需要创建 main.qml 和 MainMenu.qml（见后续说明）
# 如果你已有自己的 main.qml 和 MainMenu.qml，请替换为实际文件名
qt6_add_resources(Gonbal_My_Game "qml_resources"
    PREFIX "/"
    FILES
        ui/qml/main.qml          # 入口文件，需要新建
        ui/qml/MainMenu.qml      # 菜单界面，需要新建
        ui/qml/GameView.qml      # 你的棋盘界面
        # 如果你还有其他 QML 文件，继续添加
)

# 链接 Qt 库
target_link_libraries(Gonbal_My_Game
    PRIVATE
        Qt::Core
        Qt::Qml
        Qt::Quick
        Qt::QuickControls2
        Qt::Network
)

# 可选：将头文件添加到 IDE 中（方便查看）
target_sources(Gonbal_My_Game PRIVATE
    core/ai_player.h
    core/board.h
    core/gomoku_engine.h
    core/human_player.h
    core/player.h
    core/timer_manager.h
    ui/game_controller.h
    nerwork/game_client.h
    nerwork/game_server.h
    nerwork/network_player.h
)

# 部署设置
include(GNUInstallDirs)
install(TARGETS Gonbal_My_Game
    BUNDLE  DESTINATION .
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
qt_generate_deploy_app_script(TARGET Gonbal_My_Game OUTPUT_SCRIPT deploy_script)
install(SCRIPT ${deploy_script})
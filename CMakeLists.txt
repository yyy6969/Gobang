cmake_minimum_required(VERSION 3.19)
project(Gonbal_My_Game LANGUAGES CXX)

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
    nerwork/game_client.cpp
    nerwork/game_server.cpp
    nerwork/network_player.cpp
)

# 将 QML 文件编译为资源（qrc）
qt6_add_resources(Gonbal_My_Game "qml_resources"
    PREFIX "/"
    FILES
        ui/qml/main.qml          # 入口文件
        ui/qml/MainMenu.qml      # 菜单界面
        ui/qml/GameView.qml      # 棋盘界面
        image/background.jpg
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

# 头文件
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
cmake_minimum_required(VERSION 3.19)
project(Gonbal_My_Game LANGUAGES CXX)

find_package(Qt6 6.11 REQUIRED COMPONENTS Core Qml Quick QuickControls2)
# 查找系统 SQLite
find_package(SQLite3 REQUIRED)

qt_standard_project_setup()

#C++ 源文件
qt_add_executable(Gonbal_My_Game
    WIN32 MACOSX_BUNDLE
    main.cpp
    ui/game_controller.cpp
    core/ai_player.cpp
    core/board.cpp
    core/gomoku_engine.cpp
    core/human_player.cpp
    core/timer_manager.cpp
    nerwork/game_client.cpp
    nerwork/game_server.cpp
    nerwork/network_player.cpp
    core/datamanager.h core/datamanager.cpp
)

# 头文件
target_sources(Gonbal_My_Game PRIVATE
    ui/game_controller.h
    core/ai_player.h
    core/board.h
    core/gomoku_engine.h
    core/human_player.h
    core/player.h
    core/timer_manager.h
    nerwork/game_client.h
    nerwork/game_server.h
    nerwork/network_player.h
)

# QML 和图片资源
qt6_add_resources(Gonbal_My_Game "qml_resources"
    PREFIX "/"
    FILES
        ui/qml/main.qml
        ui/qml/MainMenu.qml
        ui/qml/GameView.qml
        image/background.jpg
        image/background2.jpg
        image/background3.jpg
        image/background4.jpg
)

# 链接库
target_link_libraries(Gonbal_My_Game
    PRIVATE
        Qt::Core
        Qt::Qml
        Qt::Quick
        Qt::QuickControls2
        Qt::Network
        SQLite::SQLite3   # 链接你的系统 SQLite 3.51
)

#部署设置
include(GNUInstallDirs)
install(TARGETS Gonbal_My_Game
    BUNDLE  DESTINATION .
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
qt_generate_deploy_app_script(TARGET Gonbal_My_Game OUTPUT_SCRIPT deploy_script)
install(SCRIPT ${deploy_script})
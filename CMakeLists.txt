cmake_minimum_required(VERSION 3.19)
project(Gonbal_My_Game LANGUAGES CXX)

find_package(Qt6 6.5 REQUIRED COMPONENTS Core Widgets)

qt_standard_project_setup()

qt_add_executable(Gonbal_My_Game
    WIN32 MACOSX_BUNDLE
    main.cpp


    core/ai_player.cpp core/ai_player.h core/board.cpp core/board.h core/gomoku_engine.cpp core/gomoku_engine.h core/human_player.cpp core/human_player.h core/player.h core/timer_manager.cpp core/timer_manager.h documents/绘图建模/uml类图.vsdx documents/绘图建模/状态机.vsdx documents/skloten_project.txt documents/Statues.png documents/uml.png nerwork/game_client.cpp nerwork/game_client.h nerwork/game_server.cpp nerwork/game_server.h nerwork/network_player.cpp nerwork/network_player.h ui/qml/BoardView.qml ui/qml/GameView.qml ui/qml/MainScreen.qml ui/game_controller.cpp ui/game_controller.h ui/mainwindow.cpp ui/mainwindow.h
    ui/mainwindow.ui

)

target_link_libraries(Gonbal_My_Game
    PRIVATE
        Qt::Core
        Qt::Widgets
)

include(GNUInstallDirs)

install(TARGETS Gonbal_My_Game
    BUNDLE  DESTINATION .
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
)

qt_generate_deploy_app_script(
    TARGET Gonbal_My_Game
    OUTPUT_SCRIPT deploy_script
    NO_UNSUPPORTED_PLATFORM_ERROR
)
install(SCRIPT ${deploy_script})

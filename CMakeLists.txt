cmake_minimum_required(VERSION 3.19)
project(Gonbal_My_Game)

find_package(Qt6 REQUIRED COMPONENTS Core Qml Quick QuickControls2 Network Sql)

qt_standard_project_setup()

if(ANDROID)
    set(QT_ANDROID_ABIS arm64-v8a armeabi-v7a)
endif()

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
    core/datamanager.cpp
    documents/skloten_project.txt
    documents/Statues.png
    documents/uml.png

    core/databasemanager.h core/databasemanager.cpp


    nerwork/nfcmanager.h nerwork/nfcmanager.cpp



)

set_target_properties(Gonbal_My_Game PROPERTIES
   QT_ANDROID_PACKAGE_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/android")

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

qt6_add_resources(Gonbal_My_Game "qml_resources"
    PREFIX "/"
    FILES
        ui/qml/main.qml
        ui/qml/MainMenu.qml
        ui/qml/GameView.qml
        ui/qml/HistoryView.qml
        ui/qml/BoardInputHandler.qml
        image/background.jpg
        image/background2.jpg
        image/background3.jpg
        image/background4.jpg
)

if(NOT ANDROID)
    target_link_libraries(Gonbal_My_Game PRIVATE SQLite::SQLite3)
endif()

find_package(Qt6 REQUIRED COMPONENTS Nfc CorePrivate)

# 关键：指向 android 子目录
set(QT_ANDROID_PACKAGE_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/android)

target_link_libraries(Gonbal_My_Game PRIVATE
    Qt::Core
    Qt::Qml
    Qt::Quick
    Qt::QuickControls2
    Qt::Network
    Qt6::Nfc
    Qt::Sql
    Qt6::CorePrivate
)


if(ANDROID)
    # 获取构建输出目录（androiddeployqt 的输出路径）
    set(ANDROID_DEPLOY_DIR "${CMAKE_BINARY_DIR}/android-build")

    # 在构建前，强制复制自定义资源到部署目录
    add_custom_command(TARGET Gonbal_My_Game PRE_BUILD
        COMMAND ${CMAKE_COMMAND} -E echo "Copying custom Android resources..."
        COMMAND ${CMAKE_COMMAND} -E copy_directory
            ${CMAKE_CURRENT_SOURCE_DIR}/android
            ${ANDROID_DEPLOY_DIR}
        COMMENT "Overriding default Android resources with custom ones"
    )
endif()

if(NOT ANDROID)
    include(GNUInstallDirs)
    install(TARGETS Gonbal_My_Game
        BUNDLE  DESTINATION .
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    )
    qt_generate_deploy_app_script(TARGET Gonbal_My_Game OUTPUT_SCRIPT deploy_script)
    install(SCRIPT ${deploy_script})
endif()

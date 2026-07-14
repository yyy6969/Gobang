cmake_minimum_required(VERSION 3.19)
project(Gonbal_My_Game)

set(ANDROID_MIN_SDK_VERSION 21)
set(ANDROID_TARGET_SDK_VERSION 34)

find_package(Qt6 REQUIRED COMPONENTS Core Qml Quick QuickControls2 Network Nfc Sql)

qt_standard_project_setup()

if(ANDROID)
    set(QT_ANDROID_ABIS arm64-v8a armeabi-v7a)
endif()

#1. QML 模块（自动处理 QML_ELEMENT 注册)
qt6_add_qml_module(Gonbal_My_Game
    URI com.yourcompany.gobang
    VERSION 1.0
    QML_FILES
        ui/qml/main.qml
        ui/qml/MainMenu.qml
        ui/qml/GameView.qml
        ui/qml/HistoryView.qml
        ui/qml/BoardInputHandler.qml
    SOURCES
        main.cpp
        ui/game_controller.cpp
        core/board.cpp
        core/gomoku_engine.cpp
        core/databasemanager.cpp
        nerwork/game_client.cpp
        nerwork/game_server.cpp
        nerwork/network_player.cpp
        nerwork/nfc_peer.cpp
        ui/game_controller.h
        core/board.h
        core/gomoku_engine.h
        core/databasemanager.h
        nerwork/game_client.h
        nerwork/game_server.h
        nerwork/network_player.h
        nerwork/nfc_peer.h
)

# 2. 图片资源
qt6_add_resources(Gonbal_My_Game "qml_resources"
    PREFIX "/"
    FILES
        image/background.jpg
        image/background2.jpg
        image/background3.jpg
        image/background4.jpg
)

# 3. Android 部署目录
set_target_properties(Gonbal_My_Game PROPERTIES
    QT_ANDROID_PACKAGE_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/android"
)

#4. 头文件搜索路径
target_include_directories(Gonbal_My_Game PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/ui
    ${CMAKE_CURRENT_SOURCE_DIR}/core
)

# 5. 链接库
target_link_libraries(Gonbal_My_Game PRIVATE
    Qt::Core
    Qt::Qml
    Qt::Quick
    Qt::QuickControls2
    Qt::Network
    Qt::Sql
)

if(ANDROID)
    target_link_libraries(Gonbal_My_Game PRIVATE Qt6::Nfc)
else()
    target_link_libraries(Gonbal_My_Game PRIVATE SQLite::SQLite3)
endif()

#6. Android 自定义资源复制
if(ANDROID)
    set(ANDROID_DEPLOY_DIR "${CMAKE_BINARY_DIR}/android-build")
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
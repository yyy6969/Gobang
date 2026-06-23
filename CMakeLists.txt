cmake_minimum_required(VERSION 3.19)

# ============ 查找 Qt6 模块 ============
find_package(Qt6 REQUIRED COMPONENTS Core Qml Quick QuickControls2 Network)

qt_standard_project_setup()

# ============ 平台特定设置 ============
if(ANDROID)
    # 指定要构建的 ABI（根据需要调整）
    set(QT_ANDROID_ABIS arm64-v8a armeabi-v7a)
    # 可选：设置最低 API 级别，默认 31
    # set(ANDROID_API_VERSION 31)
endif()
# =====================================

# ---------- 源文件 ----------
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

)

# ---------- 头文件 ----------
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

# ---------- QML 资源 ----------
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

# ---------- 链接库 ----------
# 桌面平台：使用系统 SQLite
# Android：暂不链接 SQLite
if(NOT ANDROID)
    target_link_libraries(Gonbal_My_Game PRIVATE SQLite::SQLite3)
endif()

target_link_libraries(Gonbal_My_Game PRIVATE
    Qt::Core
    Qt::Qml
    Qt::Quick
    Qt::QuickControls2
    Qt::Network
)

# ---------- 部署设置 ----------
# 桌面平台：使用标准安装和部署脚本
if(NOT ANDROID)
    include(GNUInstallDirs)
    install(TARGETS Gonbal_My_Game
        BUNDLE  DESTINATION .
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    )
    qt_generate_deploy_app_script(TARGET Gonbal_My_Game OUTPUT_SCRIPT deploy_script)
    install(SCRIPT ${deploy_script})
endif()


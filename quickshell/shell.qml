//@ pragma DefaultEnv QS_NO_RELOAD_POPUP=1
//@ pragma DefaultEnv QS_DROP_EXPENSIVE_FONTS=1
//@ pragma DefaultEnv QSG_RENDER_LOOP=threaded
//@ pragma DefaultEnv QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000
//@ pragma IconTheme Papirus-Dark

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.UPower
import Quickshell.Services.Pipewire
import Quickshell.Wayland
import Quickshell.Io
import Qt5Compat.GraphicalEffects
import qs.services

ShellRoot {
    id: root

    property bool taskbarPinned: false

    GlobalShortcut {
        name: "toggle_taskbar"
        onPressed: {
            root.taskbarPinned = !root.taskbarPinned;
        }
    }

    Component.onCompleted: {
        Quickshell.execDetached(["rm", "-f", "/tmp/caelestia_super_timer_pid"]);
    }

    Variants {
        model: Quickshell.screens
        
        Scope {
            id: scope
            required property ShellScreen modelData

            PwObjectTracker {
                objects: [Pipewire.defaultAudioSink]
            }

            property string customIconSource: "file:///home/inferno/.config/quickshell/custom_win_icon"

            // File Picker Process
            Process {
                id: filePickerProc
                command: ["zenity", "--file-selection", "--file-filter=Images | *.png *.jpg *.jpeg *.svg *.gif *.webp"]
                running: false
                
                stdout: StdioCollector {
                    id: fileCollector
                    onStreamFinished: {
                        var chosenPath = fileCollector.text.trim();
                        if (chosenPath !== "") {
                            copyProc.command = ["cp", chosenPath, "/home/inferno/.config/quickshell/custom_win_icon"];
                            copyProc.running = true;
                        }
                    }
                }
            }

            // Copy Process
            Process {
                id: copyProc
                running: false
                stdout: StdioCollector {}
                onRunningChanged: {
                    if (!running) {
                        scope.customIconSource = "file:///home/inferno/.config/quickshell/custom_win_icon?t=" + Date.now();
                    }
                }
            }

            // Reset Process
            Process {
                id: resetProc
                command: ["rm", "-f", "/home/inferno/.config/quickshell/custom_win_icon"]
                running: false
                stdout: StdioCollector {}
                onRunningChanged: {
                    if (!running) {
                        scope.customIconSource = "";
                    }
                }
            }

            property string wallpaperFolder: ""
            property var wallpaperList: []
            property string wallpaperSource: "file:///home/inferno/.config/quickshell/custom_wallpaper"

            Process {
                id: folderPickerProc
                command: ["zenity", "--file-selection", "--directory", "--title=Select Wallpaper Folder"]
                running: false
                stdout: StdioCollector {
                    id: folderCollector
                    onStreamFinished: {
                        var chosenPath = folderCollector.text.trim();
                        if (chosenPath !== "") {
                            scope.wallpaperFolder = chosenPath;
                            wallpaperScannerProc.command = ["find", chosenPath, "-maxdepth", "1", "-type", "f", "-name", "*.jpg", "-o", "-name", "*.png", "-o", "-name", "*.jpeg", "-o", "-name", "*.webp"];
                            wallpaperScannerProc.running = true;
                        }
                    }
                }
            }

            Process {
                id: wallpaperScannerProc
                running: false
                stdout: StdioCollector {
                    id: scannerCollector
                    onStreamFinished: {
                        var lines = scannerCollector.text.trim().split("\n");
                        scope.wallpaperList = lines.filter(function(l) { return l.length > 0; });
                    }
                }
            }

            Process {
                id: wallpaperCopyProc
                running: false
                stdout: StdioCollector {}
                onRunningChanged: {
                    if (!running) {
                        scope.wallpaperSource = "file:///home/inferno/.config/quickshell/custom_wallpaper?t=" + Date.now();
                    }
                }
            }

            LazyLoader {
                id: settingsWindowLoader
                active: false

                FloatingWindow {
                    id: settingsWindow
                    title: "Caelestia Settings"
                    implicitWidth: 800
                    implicitHeight: 600
                    visible: true

                    onClosed: {
                        settingsWindowLoader.active = false;
                    }

                    color: "#0a0a0a" // Super dark editorial theme

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 48
                        spacing: 48

                        Text {
                            text: "CAELESTIA"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pointSize: 28
                            font.weight: Font.Bold
                            font.letterSpacing: 8
                            color: "#ffffff"
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: 48

                            // Left Panel: Start Button Config
                            ColumnLayout {
                                Layout.preferredWidth: 200
                                Layout.alignment: Qt.AlignTop
                                spacing: 24

                                Text {
                                    text: "ICON"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pointSize: 10
                                    font.weight: Font.DemiBold
                                    font.letterSpacing: 2
                                    color: "#666666"
                                }

                                Rectangle {
                                    width: 100
                                    height: 100
                                    radius: 50
                                    color: "#111111"
                                    border.color: "#333333"
                                    border.width: 1

                                    Text {
                                        text: ""
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pointSize: 32
                                        color: "#ffffff"
                                        anchors.centerIn: parent
                                        visible: previewImage.status !== Image.Ready
                                    }

                                    Item {
                                        anchors.fill: parent
                                        anchors.margins: 2
                                        visible: previewImage.status === Image.Ready

                                        Image {
                                            id: previewImage
                                            source: scope.customIconSource
                                            anchors.fill: parent
                                            fillMode: Image.PreserveAspectCrop
                                            visible: false
                                        }

                                        Rectangle {
                                            id: previewMask
                                            anchors.fill: parent
                                            radius: width / 2
                                            color: "black"
                                            visible: false
                                        }

                                        OpacityMask {
                                            anchors.fill: parent
                                            source: previewImage
                                            maskSource: previewMask
                                        }
                                    }
                                }

                                Button {
                                    id: chooseBtn
                                    Layout.fillWidth: true
                                    text: "CHOOSE IMAGE"
                                    onClicked: filePickerProc.running = true
                                    
                                    contentItem: Text {
                                        text: chooseBtn.text
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pointSize: 9
                                        font.weight: Font.DemiBold
                                        font.letterSpacing: 1
                                        color: "#ffffff"
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    background: Rectangle {
                                        implicitHeight: 36
                                        color: chooseBtn.down ? "#222222" : (chooseBtn.hovered ? "#333333" : "#1a1a1a")
                                        radius: 4
                                    }
                                }

                                Button {
                                    id: resetBtn
                                    Layout.fillWidth: true
                                    text: "RESET"
                                    onClicked: resetProc.running = true
                                    
                                    contentItem: Text {
                                        text: resetBtn.text
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pointSize: 9
                                        font.weight: Font.DemiBold
                                        font.letterSpacing: 1
                                        color: "#ffffff"
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    background: Rectangle {
                                        implicitHeight: 36
                                        color: resetBtn.down ? "#441111" : (resetBtn.hovered ? "#552222" : "#331111")
                                        radius: 4
                                    }
                                }
                                
                                Item { Layout.fillHeight: true }
                            }

                            // Right Panel: Wallpaper Engine
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                spacing: 24

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        text: "WALLPAPER"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pointSize: 10
                                        font.weight: Font.DemiBold
                                        font.letterSpacing: 2
                                        color: "#666666"
                                    }
                                    Item { Layout.fillWidth: true }
                                    Button {
                                        id: folderBtn
                                        text: "SELECT FOLDER"
                                        onClicked: folderPickerProc.running = true
                                        
                                        contentItem: Text {
                                            text: folderBtn.text
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.pointSize: 9
                                            font.weight: Font.DemiBold
                                            font.letterSpacing: 1
                                            color: "#0a0a0a"
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                        background: Rectangle {
                                            implicitHeight: 32
                                            implicitWidth: 140
                                            color: folderBtn.down ? "#cccccc" : (folderBtn.hovered ? "#eeeeee" : "#ffffff")
                                            radius: 16
                                        }
                                    }
                                }

                                GridView {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    model: scope.wallpaperList
                                    cellWidth: 180
                                    cellHeight: 120
                                    clip: true
                                    
                                    delegate: Item {
                                        width: 160
                                        height: 100
                                        
                                        Rectangle {
                                            anchors.fill: parent
                                            radius: 8
                                            color: "#111111"
                                            clip: true
                                            
                                            border.color: mouseArea.containsMouse ? "#ffffff" : "transparent"
                                            border.width: 2
                                            
                                            Image {
                                                anchors.fill: parent
                                                anchors.margins: 2
                                                source: "file://" + modelData
                                                fillMode: Image.PreserveAspectCrop
                                                asynchronous: true
                                            }
                                        }
                                        
                                        MouseArea {
                                            id: mouseArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                wallpaperCopyProc.command = ["cp", modelData, "/home/inferno/.config/quickshell/custom_wallpaper"];
                                                wallpaperCopyProc.running = true;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

        LazyLoader {
            id: wifiConnectionsWindowLoader
            active: false

            FloatingWindow {
                id: wifiConnectionsWindow
                title: "Wi-Fi Networks"
                implicitWidth: 450
                implicitHeight: 500
                visible: true

                onClosed: {
                    wifiConnectionsWindowLoader.active = false;
                }

                color: "#1e1e2e" // Deep dark theme

                // State & Input properties stored on the FloatingWindow level
                property string selectedSsid: ""
                property string selectedBssid: ""
                property int selectedFrequency: 0
                property int selectedStrength: 0
                property string passwordValue: ""
                property string connectingStatus: ""
                property bool isConnecting: false
                property string overlayState: "" // "", "password", "details", "status"

                // Timer to auto-clean status messages
                Timer {
                    id: statusClearTimer
                    interval: 3000
                    onTriggered: {
                        wifiConnectionsWindow.connectingStatus = "";
                    }
                }

                // Timer to auto-close window on successful connection
                Timer {
                    id: successCloseTimer
                    interval: 1500
                    onTriggered: {
                        wifiConnectionsWindow.overlayState = "";
                        wifiConnectionsWindowLoader.active = false;
                    }
                }

                // Connect Flow function
                function startConnectFlow(ssid, isSecure, bssid) {
                    selectedSsid = ssid;
                    selectedBssid = bssid;
                    
                    // Check if a saved profile exists
                    if (Network.hasSavedProfile(ssid)) {
                        connectingStatus = "Connecting using saved profile...";
                        isConnecting = true;
                        overlayState = "status"; // Show a status overlay
                        
                        Network.connectToNetwork(ssid, "", bssid, (result) => {
                            isConnecting = false;
                            if (result && result.success) {
                                connectingStatus = "Connected successfully!";
                                successCloseTimer.start();
                            } else {
                                // Failed or needs password - open password input
                                connectingStatus = "";
                                overlayState = "password";
                                passwordValue = "";
                            }
                        });
                    } else if (isSecure) {
                        // No profile, is secure -> prompt for password
                        passwordValue = "";
                        connectingStatus = "";
                        overlayState = "password";
                    } else {
                        // Open network -> connect immediately
                        connectingStatus = "Connecting to " + ssid + "...";
                        isConnecting = true;
                        overlayState = "status";
                        
                        Network.connectToNetwork(ssid, "", bssid, (result) => {
                            isConnecting = false;
                            if (result && result.success) {
                                connectingStatus = "Connected successfully!";
                                successCloseTimer.start();
                            } else {
                                connectingStatus = "Connection failed: " + (result.error || "Unknown error");
                                statusClearTimer.start();
                            }
                        });
                    }
                }

                // Main Container
                Rectangle {
                    anchors.fill: parent
                    color: "#1e1e2e" // Deep dark theme matching Settings

                    // Subtle top highlight for glass look
                    Rectangle {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 1
                        color: "#16ffffff"
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 16

                        // Header Section
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            Text {
                                text: "Wi-Fi Networks"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pointSize: 16
                                font.weight: Font.Bold
                                color: "#ffffff"
                            }

                            Item { Layout.fillWidth: true }

                            // Wi-Fi Enabled Switch Pill
                            Rectangle {
                                width: 48
                                height: 24
                                radius: 12
                                color: Network.wifiEnabled ? "#3b82f6" : "#313244"

                                Behavior on color {
                                    ColorAnimation { duration: 150 }
                                }

                                Rectangle {
                                    width: 20
                                    height: 20
                                    radius: 10
                                    color: "#ffffff"
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: Network.wifiEnabled ? 26 : 2

                                    Behavior on x {
                                        NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Network.toggleWifi();
                                    }
                                }
                            }

                            // Rescan Button
                            ToolButton {
                                id: rescanBtn
                                background: Rectangle {
                                    implicitWidth: 32
                                    implicitHeight: 32
                                    radius: 16
                                    color: rescanBtn.hovered ? "#16ffffff" : "transparent"
                                }
                                contentItem: Text {
                                    id: rescanIcon
                                    text: "󰑐"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pointSize: 14
                                    color: "#ffffff"
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    transformOrigin: Item.Center

                                    RotationAnimation on rotation {
                                        running: Network.scanning
                                        loops: Animation.Infinite
                                        from: 0
                                        to: 360
                                        duration: 1000
                                    }
                                }
                                onClicked: {
                                    Network.rescanWifi();
                                }
                            }
                        }

                        // Divider line
                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: "#313244"
                        }

                        // Wi-Fi Off Banner
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 60
                            radius: 8
                            color: "#11111b"
                            border.color: "#313244"
                            border.width: 1
                            visible: !Network.wifiEnabled

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 12

                                Text {
                                    text: "󰤮"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pointSize: 20
                                    color: "#a6adc8"
                                }

                                Text {
                                    text: "Wi-Fi is currently turned off.\nEnable it to view networks."
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pointSize: 10
                                    color: "#a6adc8"
                                    Layout.fillWidth: true
                                }
                            }
                        }

                        // Network List Container (visible only when enabled)
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            visible: Network.wifiEnabled

                            ListView {
                                id: networkListView
                                anchors.fill: parent
                                clip: true
                                spacing: 8
                                model: Network.networks

                                delegate: Rectangle {
                                    id: netDelegate
                                    width: parent.width
                                    height: 52
                                    radius: 8
                                    color: modelData.active ? "#163b82f6" : (delegateMA.containsMouse ? "#11ffffff" : "#08ffffff")
                                    border.color: modelData.active ? "#3b82f6" : "transparent"
                                    border.width: modelData.active ? 1 : 0

                                    Behavior on color {
                                        ColorAnimation { duration: 150 }
                                    }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 12
                                        spacing: 12

                                        // Signal strength icon
                                        Text {
                                            text: {
                                                const strength = modelData.strength;
                                                if (strength >= 75) return "󰤨";
                                                if (strength >= 50) return "󰤥";
                                                if (strength >= 25) return "󰤢";
                                                if (strength > 0) return "󰤟";
                                                return "󰤯";
                                            }
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.pointSize: 14
                                            color: modelData.active ? "#3b82f6" : "#ffffff"
                                        }

                                        // SSID Name and connection state info
                                        ColumnLayout {
                                            spacing: 2
                                            Layout.fillWidth: true

                                            Text {
                                                text: modelData.ssid ? modelData.ssid : "Hidden Network"
                                                font.family: "JetBrainsMono Nerd Font"
                                                font.pointSize: 11
                                                font.weight: modelData.active ? Font.Bold : Font.Normal
                                                color: "#ffffff"
                                                elide: Text.ElideRight
                                            }

                                            Text {
                                                text: modelData.active ? "Connected" : (modelData.isSecure ? "Secured" : "Open")
                                                font.family: "JetBrainsMono Nerd Font"
                                                font.pointSize: 9
                                                color: modelData.active ? "#10b981" : "#a6adc8"
                                            }
                                        }

                                        // Icons on the right: lock icon if secure
                                        Text {
                                            text: modelData.isSecure ? "󰌾" : ""
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.pointSize: 12
                                            color: "#a6adc8"
                                            visible: modelData.isSecure
                                        }
                                    }

                                    MouseArea {
                                        id: delegateMA
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor

                                        onClicked: {
                                            if (modelData.active) {
                                                // Show details overlay
                                                wifiConnectionsWindow.selectedSsid = modelData.ssid;
                                                wifiConnectionsWindow.selectedBssid = modelData.bssid;
                                                wifiConnectionsWindow.selectedFrequency = modelData.frequency;
                                                wifiConnectionsWindow.selectedStrength = modelData.strength;
                                                wifiConnectionsWindow.overlayState = "details";
                                            } else {
                                                // Start connect flow
                                                wifiConnectionsWindow.startConnectFlow(modelData.ssid, modelData.isSecure, modelData.bssid);
                                            }
                                        }
                                    }
                                }

                                ScrollBar.vertical: ScrollBar {
                                    active: true
                                    policy: ScrollBar.AsNeeded
                                }
                            }
                        }
                    }

                    // Password Overlay
                    Rectangle {
                        anchors.fill: parent
                        color: "#f0181825"
                        visible: wifiConnectionsWindow.overlayState === "password"

                        MouseArea {
                            anchors.fill: parent // Consume clicks
                        }

                        ColumnLayout {
                            anchors.centerIn: parent
                            width: parent.width * 0.85
                            spacing: 20

                            Text {
                                text: "Connect to Network"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pointSize: 14
                                font.weight: Font.Bold
                                color: "#ffffff"
                                Layout.alignment: Qt.AlignHCenter
                            }

                            Text {
                                text: wifiConnectionsWindow.selectedSsid
                                font.family: "JetBrainsMono Nerd Font"
                                font.pointSize: 12
                                font.weight: Font.Medium
                                color: "#3b82f6"
                                Layout.alignment: Qt.AlignHCenter
                                elide: Text.ElideRight
                            }

                            TextField {
                                id: passwordInput
                                Layout.fillWidth: true
                                placeholderText: "Enter password..."
                                echoMode: TextField.Password
                                color: "#ffffff"
                                placeholderTextColor: "#a6adc8"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pointSize: 10
                                focus: wifiConnectionsWindow.overlayState === "password"
                                
                                background: Rectangle {
                                    color: "#11111b"
                                    border.color: passwordInput.activeFocus ? "#3b82f6" : "#313244"
                                    border.width: 1.5
                                    radius: 6
                                }
                                
                                leftPadding: 12
                                rightPadding: 12
                                topPadding: 8
                                bottomPadding: 8

                                onAccepted: {
                                    connectBtn.clicked();
                                }
                            }

                            Text {
                                text: wifiConnectionsWindow.connectingStatus
                                font.family: "JetBrainsMono Nerd Font"
                                font.pointSize: 9
                                color: wifiConnectionsWindow.connectingStatus.includes("failed") || wifiConnectionsWindow.connectingStatus.includes("Failed") ? "#ef4444" : "#a6adc8"
                                Layout.alignment: Qt.AlignHCenter
                                visible: wifiConnectionsWindow.connectingStatus !== ""
                                horizontalAlignment: Text.AlignHCenter
                                Layout.fillWidth: true
                                wrapMode: Text.Wrap
                            }

                            RowLayout {
                                spacing: 12
                                Layout.fillWidth: true

                                Button {
                                    id: connectBtn
                                    Layout.fillWidth: true
                                    text: wifiConnectionsWindow.isConnecting ? "Connecting..." : "Connect"
                                    enabled: !wifiConnectionsWindow.isConnecting && passwordInput.text.length > 0
                                    
                                    contentItem: Text {
                                        text: connectBtn.text
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pointSize: 10
                                        font.weight: Font.DemiBold
                                        color: connectBtn.enabled ? "#ffffff" : "#6c7086"
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }

                                    background: Rectangle {
                                        implicitHeight: 36
                                        color: connectBtn.down ? "#2563eb" : (connectBtn.hovered ? "#3b82f6" : "#1d4ed8")
                                        radius: 6
                                        opacity: connectBtn.enabled ? 1.0 : 0.5
                                    }

                                    onClicked: {
                                        wifiConnectionsWindow.connectingStatus = "Connecting to network...";
                                        wifiConnectionsWindow.isConnecting = true;
                                        Network.connectToNetwork(wifiConnectionsWindow.selectedSsid, passwordInput.text, wifiConnectionsWindow.selectedBssid, (result) => {
                                            wifiConnectionsWindow.isConnecting = false;
                                            if (result && result.success) {
                                                wifiConnectionsWindow.connectingStatus = "Connected successfully!";
                                                successCloseTimer.start();
                                            } else {
                                                wifiConnectionsWindow.connectingStatus = "Connection failed: " + (result.error || "Wrong password or timeout");
                                            }
                                        });
                                    }
                                }

                                Button {
                                    id: cancelBtn
                                    Layout.fillWidth: true
                                    text: "Cancel"
                                    enabled: !wifiConnectionsWindow.isConnecting

                                    contentItem: Text {
                                        text: cancelBtn.text
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pointSize: 10
                                        font.weight: Font.DemiBold
                                        color: "#ffffff"
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }

                                    background: Rectangle {
                                        implicitHeight: 36
                                        color: cancelBtn.down ? "#313244" : (cancelBtn.hovered ? "#45475a" : "#1e1e2e")
                                        border.color: "#313244"
                                        border.width: 1
                                        radius: 6
                                    }

                                    onClicked: {
                                        passwordInput.text = "";
                                        wifiConnectionsWindow.connectingStatus = "";
                                        wifiConnectionsWindow.overlayState = "";
                                    }
                                }
                            }
                        }
                    }

                    // Status Only Overlay
                    Rectangle {
                        anchors.fill: parent
                        color: "#f0181825"
                        visible: wifiConnectionsWindow.overlayState === "status"

                        MouseArea {
                            anchors.fill: parent
                        }

                        ColumnLayout {
                            anchors.centerIn: parent
                            width: parent.width * 0.85
                            spacing: 20

                            BusyIndicator {
                                Layout.alignment: Qt.AlignHCenter
                                running: wifiConnectionsWindow.isConnecting
                            }

                            Text {
                                text: wifiConnectionsWindow.connectingStatus
                                font.family: "JetBrainsMono Nerd Font"
                                font.pointSize: 11
                                color: "#ffffff"
                                horizontalAlignment: Text.AlignHCenter
                                Layout.fillWidth: true
                                wrapMode: Text.Wrap
                            }

                            Button {
                                id: statusCloseBtn
                                Layout.preferredWidth: 120
                                Layout.alignment: Qt.AlignHCenter
                                text: "Dismiss"
                                visible: !wifiConnectionsWindow.isConnecting
                                
                                contentItem: Text {
                                    text: statusCloseBtn.text
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pointSize: 10
                                    font.weight: Font.DemiBold
                                    color: "#ffffff"
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }

                                background: Rectangle {
                                    implicitHeight: 36
                                    color: statusCloseBtn.down ? "#313244" : (statusCloseBtn.hovered ? "#45475a" : "#1e1e2e")
                                    border.color: "#313244"
                                    border.width: 1
                                    radius: 6
                                }

                                onClicked: {
                                    wifiConnectionsWindow.overlayState = "";
                                    wifiConnectionsWindow.connectingStatus = "";
                                }
                            }
                        }
                    }

                    // Network Details / Disconnect Overlay
                    Rectangle {
                        anchors.fill: parent
                        color: "#f0181825"
                        visible: wifiConnectionsWindow.overlayState === "details"

                        MouseArea {
                            anchors.fill: parent
                        }

                        ColumnLayout {
                            anchors.centerIn: parent
                            width: parent.width * 0.85
                            spacing: 16

                            Text {
                                text: "Network Details"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pointSize: 14
                                font.weight: Font.Bold
                                color: "#ffffff"
                                Layout.alignment: Qt.AlignHCenter
                            }

                            Text {
                                text: wifiConnectionsWindow.selectedSsid
                                font.family: "JetBrainsMono Nerd Font"
                                font.pointSize: 16
                                font.weight: Font.Bold
                                color: "#3b82f6"
                                Layout.alignment: Qt.AlignHCenter
                                elide: Text.ElideRight
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 1
                                color: "#313244"
                            }

                            // Details Table
                            GridLayout {
                                columns: 2
                                rowSpacing: 8
                                columnSpacing: 16
                                Layout.fillWidth: true

                                Text {
                                    text: "Signal Strength:"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pointSize: 10
                                    color: "#a6adc8"
                                }
                                Text {
                                    text: wifiConnectionsWindow.selectedStrength + "%"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pointSize: 10
                                    color: "#ffffff"
                                    font.weight: Font.Bold
                                }

                                Text {
                                    text: "Frequency:"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pointSize: 10
                                    color: "#a6adc8"
                                }
                                Text {
                                    text: (wifiConnectionsWindow.selectedFrequency / 1000).toFixed(3) + " GHz"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pointSize: 10
                                    color: "#ffffff"
                                }

                                Text {
                                    text: "BSSID:"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pointSize: 10
                                    color: "#a6adc8"
                                }
                                Text {
                                    text: wifiConnectionsWindow.selectedBssid
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pointSize: 10
                                    color: "#ffffff"
                                    font.weight: Font.Light
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 1
                                color: "#313244"
                            }

                            RowLayout {
                                spacing: 12
                                Layout.fillWidth: true

                                Button {
                                    id: disconnectBtn
                                    Layout.fillWidth: true
                                    text: "Disconnect"
                                    
                                    contentItem: Text {
                                        text: disconnectBtn.text
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pointSize: 10
                                        font.weight: Font.DemiBold
                                        color: "#ffffff"
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }

                                    background: Rectangle {
                                        implicitHeight: 36
                                        color: disconnectBtn.down ? "#991b1b" : (disconnectBtn.hovered ? "#ef4444" : "#dc2626")
                                        radius: 6
                                    }

                                    onClicked: {
                                        Network.disconnectFromNetwork();
                                        wifiConnectionsWindow.overlayState = "";
                                    }
                                }

                                Button {
                                    id: forgetBtn
                                    Layout.fillWidth: true
                                    text: "Forget"
                                    
                                    contentItem: Text {
                                        text: forgetBtn.text
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pointSize: 10
                                        font.weight: Font.DemiBold
                                        color: "#ffffff"
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }

                                    background: Rectangle {
                                        implicitHeight: 36
                                        color: forgetBtn.down ? "#b2ffffff" : (forgetBtn.hovered ? "#16ffffff" : "transparent")
                                        border.color: "#ef4444"
                                        border.width: 1
                                        radius: 6
                                    }

                                    onClicked: {
                                        Network.forgetNetwork(wifiConnectionsWindow.selectedSsid);
                                        wifiConnectionsWindow.overlayState = "";
                                    }
                                }
                            }

                            Button {
                                id: closeDetailsBtn
                                Layout.fillWidth: true
                                text: "Close"
                                
                                contentItem: Text {
                                    text: closeDetailsBtn.text
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pointSize: 10
                                    font.weight: Font.DemiBold
                                    color: "#ffffff"
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }

                                background: Rectangle {
                                    implicitHeight: 36
                                    color: closeDetailsBtn.down ? "#313244" : (closeDetailsBtn.hovered ? "#45475a" : "#1e1e2e")
                                    border.color: "#313244"
                                    border.width: 1
                                    radius: 6
                                }

                                onClicked: {
                                    wifiConnectionsWindow.overlayState = "";
                                }
                            }
                        }
                    }
                }
            }
        }

            PanelWindow {
                id: backgroundWindow
                screen: scope.modelData
                anchors.top: true
                anchors.bottom: true
                anchors.left: true
                anchors.right: true
                exclusiveZone: -1

                WlrLayershell.layer: WlrLayer.Background
                WlrLayershell.namespace: "quickshell-wallpaper"

                Image {
                    anchors.fill: parent
                    source: scope.wallpaperSource
                    fillMode: Image.PreserveAspectCrop
                }
            }

            PanelWindow {
                id: brightnessScrollOverlay
                screen: scope.modelData

                anchors.top: true
                anchors.right: true
                implicitWidth: 150
                implicitHeight: 10
                exclusiveZone: -1

                WlrLayershell.layer: WlrLayer.Top
                WlrLayershell.namespace: "brightness-scroll-overlay"

                color: "transparent"

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.ArrowCursor

                    onWheel: event => {
                        if (event.angleDelta.y > 0) {
                            Quickshell.execDetached(["brightnessctl", "s", "+5%"]);
                        } else {
                            Quickshell.execDetached(["brightnessctl", "s", "5%-"]);
                        }
                    }
                }
            }

            PanelWindow {
                id: taskbar
                screen: scope.modelData

                property bool shouldShow: root.taskbarPinned

                anchors.bottom: true
                margins.bottom: shouldShow ? 0 : -48
                anchors.left: true
                margins.left: 0
                anchors.right: true
                margins.right: 0
                implicitHeight: 48
                exclusiveZone: shouldShow ? 48 : 0

                Behavior on margins.bottom {
                    NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
                }

                WlrLayershell.layer: WlrLayer.Top
                WlrLayershell.namespace: "quickshell-taskbar"
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

                color: "transparent"

                // Minimalist dark background
                Rectangle {
                    anchors.fill: parent
                    color: "#b3000000" // Deep elegant dark background with transparency
                    radius: 0
                }

                // LEFT: Start Button + Workspaces
                RowLayout {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 16
                    width: implicitWidth

                    // Start Button
                    Rectangle {
                        id: startBtn
                        implicitWidth: 36
                        implicitHeight: 36
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36
                        Layout.alignment: Qt.AlignVCenter
                        radius: 6
                        color: isHovered ? "#1affffff" : "transparent"
                        property bool isHovered: false

                        // Default Text Icon (when custom image is not ready/loaded)
                        Text {
                            id: defaultWinText
                            anchors.centerIn: parent
                            text: "" // Windows-like logo
                            font.family: "JetBrainsMono Nerd Font"
                            font.pointSize: 18
                            color: startBtn.isHovered ? "#3b82f6" : "#ffffff"
                            visible: winCustomImage.status !== Image.Ready

                            Behavior on color {
                                ColorAnimation { duration: 150 }
                            }
                        }

                        // Custom Round Image (when loaded successfully)
                        Item {
                            id: customWinImageContainer
                            anchors.fill: parent
                            anchors.margins: 4
                            visible: winCustomImage.status === Image.Ready

                            Image {
                                id: winCustomImage
                                source: scope.customIconSource
                                visible: false
                                anchors.fill: parent
                                fillMode: Image.PreserveAspectCrop
                            }

                            Rectangle {
                                id: winCustomMask
                                anchors.fill: parent
                                radius: width / 2
                                color: "black"
                                visible: false
                            }

                            OpacityMask {
                                anchors.fill: parent
                                source: winCustomImage
                                maskSource: winCustomMask
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                            onEntered: startBtn.isHovered = true
                            onExited: startBtn.isHovered = false
                            onClicked: mouse => {
                                if (mouse.button === Qt.MiddleButton) {
                                    settingsWindowLoader.active = !settingsWindowLoader.active;
                                } else {
                                    Quickshell.execDetached(["fuzzel"]);
                                }
                            }
                        }
                    }

                    // Workspaces pills
                    Row {
                        id: wsRow
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: implicitWidth
                        Layout.preferredHeight: implicitHeight
                        spacing: 8

                        Repeater {
                            model: 5
                            delegate: Rectangle {
                                id: wsButton
                                readonly property int wsId: index + 1
                                readonly property bool isActive: Hyprland.focusedWorkspace ? (Hyprland.focusedWorkspace.id === wsId) : false
                                readonly property bool isOccupied: {
                                    const ws = Hyprland.workspaces.values.find(w => w.id === wsId);
                                    if (!ws) return false;
                                    const windowsCount = (ws.lastIpcObject && ws.lastIpcObject.windows !== undefined) ? ws.lastIpcObject.windows : 0;
                                    const toplevelsCount = (ws.toplevels && ws.toplevels.values !== undefined) ? ws.toplevels.values.length : 0;
                                    return windowsCount > 0 || toplevelsCount > 0;
                                }

                                width: isActive ? 16 : 6
                                height: 6
                                radius: 3
                                color: isActive ? "#ffffff" : (isOccupied ? "#66ffffff" : "#22ffffff")

                                Behavior on width {
                                    NumberAnimation { duration: 200; easing.type: Easing.OutQuad }
                                }
                                Behavior on color {
                                    ColorAnimation { duration: 200 }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Hyprland.dispatch("workspace " + wsId);
                                    }
                                }
                            }
                        }
                    }
                }

                // CENTER: Running applications/tasks
                RowLayout {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    width: implicitWidth
                    
                    Row {
                        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                        spacing: 6

                        Repeater {
                            model: {
                                const vals = Hyprland.toplevels.values;
                                return [...vals].sort((a, b) => {
                                    const aWs = a.workspace ? a.workspace.id : 9999;
                                    const bWs = b.workspace ? b.workspace.id : 9999;
                                    if (aWs !== bWs) return aWs - bWs;
                                    
                                    // If same workspace, keep order stable by sorting by address
                                    return a.address.localeCompare(b.address);
                                });
                            }
                            delegate: Rectangle {
                                id: taskItem
                                width: 44
                                height: 44
                                radius: 12
                                color: "transparent"
                                border.width: 0
                                
                                readonly property var toplevel: modelData
                                readonly property bool isFocused: Hyprland.activeToplevel?.address === toplevel.address
                                readonly property bool isCurrentWorkspace: toplevel.workspace && Hyprland.focusedWorkspace && toplevel.workspace.id === Hyprland.focusedWorkspace.id
                                property bool isHovered: false

                                Image {
                                    id: appIcon
                                    anchors.centerIn: parent
                                    
                                    property int retryCounter: 0
                                    Timer {
                                        interval: 2000
                                        running: (appIcon.source.toString() === "" || appIcon.source.toString().indexOf("preferences-system-windows") !== -1 || appIcon.source.toString().indexOf("window-new") !== -1) && appIcon.retryCounter < 10
                                        repeat: true
                                        onTriggered: {
                                            appIcon.retryCounter++;
                                        }
                                    }

                                    source: {
                                        // Ensure source re-evaluates if icon lookup fails initially
                                        var _dummy = appIcon.retryCounter;
                                        var _dummy2 = DesktopEntries.applications.count;
                                        // The class lives inside lastIpcObject (hyprctl clients data)
                                        // or on the wayland toplevel's appId
                                        var appClass = "";
                                        if (toplevel.lastIpcObject) {
                                            appClass = toplevel.lastIpcObject["class"] || toplevel.lastIpcObject.initialClass || "";
                                        }
                                        if (!appClass && toplevel.wayland) {
                                            appClass = toplevel.wayland.appId || "";
                                        }
                                        if (!appClass) {
                                            appClass = toplevel.appId || toplevel["class"] || toplevel.windowClass || "";
                                        }
                                        return getAppIconPath(appClass);
                                    }
                                    width: 28
                                    height: 28
                                    sourceSize.width: 28
                                    sourceSize.height: 28
                                    fillMode: Image.PreserveAspectFit
                                    opacity: isCurrentWorkspace ? (isFocused ? 1.0 : (isHovered ? 0.95 : 0.7)) : 0.4

                                    Behavior on opacity {
                                        NumberAnimation { duration: 150 }
                                    }
                                }

                                // Small minimal indicator bar at the bottom
                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: 4
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: isFocused ? 16 : 4
                                    height: isFocused ? 2 : 4
                                    radius: isFocused ? 1 : 2
                                    color: isFocused ? "#ffffff" : (isCurrentWorkspace ? "#4cffffff" : "transparent")

                                    Behavior on width {
                                        NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
                                    }
                                    Behavior on color {
                                        ColorAnimation { duration: 150 }
                                    }
                                }


                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: taskItem.isHovered = true
                                    onExited: taskItem.isHovered = false
                                    onClicked: {
                                        Hyprland.dispatch("focuswindow address:0x" + toplevel.address);
                                    }
                                }
                            }
                        }
                    }
                }

                // RIGHT: System tray / status area + Clock & Date
                RowLayout {
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 12
                    width: implicitWidth

                    // Status Area (Volume and Battery)
                    RowLayout {
                        spacing: 8
                        Layout.preferredWidth: implicitWidth
                        Layout.preferredHeight: implicitHeight
                        Layout.alignment: Qt.AlignVCenter
                        
                        // Wifi widget
                        Rectangle {
                            id: wifiWidget
                            implicitHeight: 32
                            implicitWidth: wifiLayout.implicitWidth + 12
                            Layout.preferredHeight: 32
                            Layout.preferredWidth: implicitWidth
                            Layout.alignment: Qt.AlignVCenter
                            color: "transparent"
                            radius: 16

                            RowLayout {
                                id: wifiLayout
                                anchors.centerIn: parent
                                spacing: 4

                                Text {
                                    text: {
                                        if (Network.activeEthernet) return "󰈀";
                                        if (!Network.wifiEnabled) return "󰤮";
                                        const activeAp = Network.active;
                                        if (!activeAp) return "󰤯";
                                        const strength = activeAp.strength;
                                        if (strength >= 75) return "󰤨";
                                        if (strength >= 50) return "󰤥";
                                        if (strength >= 25) return "󰤢";
                                        if (strength > 0) return "󰤟";
                                        return "󰤯";
                                    }
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pointSize: 12
                                    color: "#ffffff"
                                }

                                Text {
                                    text: {
                                        if (Network.activeEthernet) return "Ethernet";
                                        if (!Network.wifiEnabled) return "WiFi Off";
                                        const activeAp = Network.active;
                                        return activeAp ? activeAp.ssid : "Disconnected";
                                    }
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pointSize: 10
                                    color: "#ffffff"
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                                onClicked: mouse => {
                                    if (mouse.button === Qt.MiddleButton) {
                                        wifiConnectionsWindowLoader.active = !wifiConnectionsWindowLoader.active;
                                    } else if (mouse.button === Qt.LeftButton) {
                                        Network.toggleWifi();
                                    }
                                }
                            }
                        }

                        // Volume widget
                        Rectangle {
                            id: volWidget
                            implicitHeight: 32
                            implicitWidth: volLayout.implicitWidth + 12
                            Layout.preferredHeight: 32
                            Layout.preferredWidth: implicitWidth
                            Layout.alignment: Qt.AlignVCenter
                            color: "transparent"
                            radius: 16

                            RowLayout {
                                id: volLayout
                                anchors.centerIn: parent
                                spacing: 4

                                Text {
                                    text: {
                                        const muted = Pipewire.defaultAudioSink?.audio?.muted ?? false;
                                        if (muted) return "󰝟";
                                        const vol = Pipewire.defaultAudioSink?.audio?.volume ?? 0;
                                        if (vol === 0) return "󰕿";
                                        if (vol < 0.3) return "󰕿";
                                        if (vol < 0.7) return "󰖀";
                                        return "󰕾";
                                    }
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pointSize: 12
                                    color: "#ffffff"
                                }

                                Text {
                                    text: {
                                        const muted = Pipewire.defaultAudioSink?.audio?.muted ?? false;
                                        if (muted) return "Muted";
                                        const vol = Pipewire.defaultAudioSink?.audio?.volume ?? 0;
                                        return Math.round(vol * 100) + "%";
                                    }
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pointSize: 10
                                    color: "#ffffff"
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                
                                onClicked: {
                                    if (Pipewire.defaultAudioSink?.audio) {
                                        Pipewire.defaultAudioSink.audio.muted = !Pipewire.defaultAudioSink.audio.muted;
                                    }
                                }

                                onWheel: event => {
                                    if (Pipewire.defaultAudioSink?.audio) {
                                        const step = 0.05;
                                        const currentVol = Pipewire.defaultAudioSink.audio.volume;
                                        if (event.angleDelta.y > 0) {
                                            Pipewire.defaultAudioSink.audio.volume = Math.min(1.0, currentVol + step);
                                        } else {
                                            Pipewire.defaultAudioSink.audio.volume = Math.max(0.0, currentVol - step);
                                        }
                                    }
                                }
                            }
                        }

                        // Battery widget
                        Rectangle {
                            id: batWidget
                            implicitHeight: 32
                            implicitWidth: batLayout.implicitWidth + 12
                            Layout.preferredHeight: 32
                            Layout.preferredWidth: implicitWidth
                            Layout.alignment: Qt.AlignVCenter
                            color: "transparent"
                            radius: 16
                            visible: UPower.displayDevice && UPower.displayDevice.percentage !== undefined && UPower.displayDevice.percentage >= 0

                            RowLayout {
                                id: batLayout
                                anchors.centerIn: parent
                                spacing: 4

                                Text {
                                    text: {
                                        if (!UPower.displayDevice) return "󰂎";
                                        const state = UPower.displayDevice.state;
                                        const isCharging = state === 1 || state === 4 || state === 5;
                                        const perc = UPower.displayDevice.percentage ?? 0.5;
                                        if (isCharging) return "󰂄";
                                        if (perc < 0.15) return "󰂎";
                                        if (perc < 0.3) return "󰁻";
                                        if (perc < 0.5) return "󰁽";
                                        if (perc < 0.7) return "󰁿";
                                        if (perc < 0.9) return "󰂁";
                                        return "󰁹";
                                    }
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pointSize: 12
                                    color: "#ffffff"
                                }

                                Text {
                                    text: {
                                        const perc = UPower.displayDevice?.percentage ?? 0;
                                        return Math.round(perc * 100) + "%";
                                    }
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pointSize: 10
                                    color: "#ffffff"
                                }
                            }
                        }
                    }

                        // Clock and Date widget
                        Rectangle {
                            id: clockWidget
                            implicitHeight: 36
                            implicitWidth: clockLayout.implicitWidth + 16
                            Layout.preferredHeight: 36
                            Layout.preferredWidth: implicitWidth
                            Layout.alignment: Qt.AlignVCenter
                            color: "transparent"
                            radius: 6

                        ColumnLayout {
                            id: clockLayout
                            anchors.centerIn: parent
                            spacing: 0

                            Text {
                                id: timeText
                                Layout.alignment: Qt.AlignHCenter
                                text: ""
                                font.family: "JetBrainsMono Nerd Font"
                                font.pointSize: 10
                                font.weight: Font.DemiBold
                                color: "#ffffff"
                            }

                            Text {
                                id: dateText
                                Layout.alignment: Qt.AlignHCenter
                                text: ""
                                font.family: "JetBrainsMono Nerd Font"
                                font.pointSize: 8
                                color: "#9ca3af"
                            }

                            Timer {
                                interval: 1000
                                running: true
                                repeat: true
                                triggeredOnStart: true
                                onTriggered: {
                                    var date = new Date();
                                    timeText.text = date.toLocaleTimeString(Qt.locale(), Locale.ShortFormat);
                                    dateText.text = date.toLocaleDateString(Qt.locale(), "dd/MM/yyyy");
                                }
                            }
                        }
                    }
                } // close RIGHT RowLayout
            } // close PanelWindow

            // AppIcon mapping helper to resolve absolute system paths from the theme
            function getAppIconPath(appClass) {
                // Establish a reactive dependency on the DesktopEntries index loading state
                var _dummy = DesktopEntries.applications.count;

                if (!appClass) return Quickshell.iconPath("preferences-system-windows", true) || Quickshell.iconPath("window-new", true) || "";

                let iconNames = [];
                
                // 1. Try to look up the icon name via Quickshell's DesktopEntries service
                try {
                    const lookupIcon = DesktopEntries.heuristicLookup(appClass)?.icon;
                    if (lookupIcon) {
                        iconNames.push(lookupIcon);
                    }
                } catch (e) {
                    // Ignore lookup errors
                }

                const lower = appClass.toLowerCase();

                
                if (lower.includes("foot") || lower.includes("terminal")) {
                    iconNames.push("utilities-terminal", "terminal", "foot");
                } else if (lower.includes("chrome")) {
                    iconNames.push("google-chrome", "chrome");
                } else if (lower.includes("firefox")) {
                    iconNames.push("firefox", "firefox-esr");
                } else if (lower.includes("zen")) {
                    iconNames.push("zen", "firefox");
                } else if (lower.includes("dolphin") || lower.includes("thunar") || lower.includes("explorer") || lower.includes("pcmanfm")) {
                    iconNames.push("system-file-manager", "dolphin", "thunar", "folder");
                } else if (lower.includes("code") || lower.includes("vscode") || lower.includes("zed") || lower.includes("kate") || lower.includes("micro")) {
                    iconNames.push("com.visualstudio.code", "visual-studio-code", "code", "kate");
                } else if (lower.includes("spotify")) {
                    iconNames.push("spotify");
                } else if (lower.includes("discord") || lower.includes("vesktop") || lower.includes("equibop")) {
                    iconNames.push("discord", "vesktop");
                } else if (lower.includes("btop") || lower.includes("monitor")) {
                    iconNames.push("system-monitor", "btop", "utilities-system-monitor");
                } else {
                    // Try the lower-case appClass as-is
                    iconNames.push(lower, appClass);
                }

                // Check each candidate icon in the theme
                for (let i = 0; i < iconNames.length; i++) {
                    if (!iconNames[i]) continue;
                    const path = Quickshell.iconPath(iconNames[i], true);
                    if (path && path.toString() !== "") {
                        return path;
                    }
                }

                // Fallback to a window icon instead of executable (which looks like settings)
                return Quickshell.iconPath("preferences-system-windows", true) || Quickshell.iconPath("window-new", true) || "";
            }
        }
    }
}

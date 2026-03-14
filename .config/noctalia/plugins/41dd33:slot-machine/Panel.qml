import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import qs.Services.UI

Item {
    id: root

    property var pluginApi: null

    readonly property var geometryPlaceholder: panelContainer
    readonly property bool allowAttach: true

    // Height adapts per tab: Spin tab is compact, Paytable tab is taller
    property real contentPreferredWidth: 400 * Style.uiScaleRatio
    property real contentPreferredHeight: activeTab === 0 ? 430 * Style.uiScaleRatio : 620 * Style.uiScaleRatio

    anchors.fill: parent

    readonly property var machine: pluginApi?.mainInstance ?? null

    readonly property var symbols: machine?.symbols ?? []
    readonly property int reel0: machine?.reel0 ?? 0
    readonly property int reel1: machine?.reel1 ?? 0
    readonly property int reel2: machine?.reel2 ?? 0
    readonly property bool spinning: machine?.spinning ?? false
    readonly property string lastResult: machine?.lastResult ?? ""
    readonly property int spinSerial: machine?.spinSerial ?? 0
    readonly property int credits: machine?.credits ?? 0

    // 0 = Spin, 1 = Paytable
    property int activeTab: 0

    property bool reel0Spinning: false
    property bool reel1Spinning: false
    property bool reel2Spinning: false

    onSpinningChanged: {
        if (spinning) {
            reel0Spinning = true;
            reel1Spinning = true;
            reel2Spinning = true;
            r0Stop.restart();
        }
    }

    Timer {
        id: r0Stop
        interval: 600
        onTriggered: {
            reel0Spinning = false;
            r1Stop.restart();
        }
    }
    Timer {
        id: r1Stop
        interval: 400
        onTriggered: {
            reel1Spinning = false;
            r2Stop.restart();
        }
    }
    Timer {
        id: r2Stop
        interval: 300
        onTriggered: {
            reel2Spinning = false;
        }
    }

    property bool flashActive: false
    property int flashCount: 0
    property bool jackpotActive: false

    onSpinSerialChanged: {
        if (lastResult === "win" || lastResult === "jackpot" || lastResult === "smallwin") {
            flashCount = 0;
            flashActive = true;
            flashTimer.restart();
        } else {
            flashActive = false;
        }
        if (lastResult === "jackpot") {
            jackpotActive = true;
            jackpotEndTimer.restart();
        } else {
            jackpotActive = false;
        }
    }

    Timer {
        id: flashTimer
        interval: 120
        repeat: true
        onTriggered: {
            root.flashActive = !root.flashActive;
            root.flashCount++;
            if (root.flashCount >= (root.lastResult === "jackpot" ? 16 : 8)) {
                stop();
                root.flashActive = false;
            }
        }
    }

    Timer {
        id: jackpotEndTimer
        interval: 3200
        onTriggered: {
            root.jackpotActive = false;
        }
    }

    // Tab button component
    component TabButton: Rectangle {
        id: tabBtn

        property string icon: ""
        property string label: ""
        property bool isActive: false

        signal clicked

        implicitWidth: tabBtnContent.implicitWidth + Style.marginM * 2
        implicitHeight: tabBtnContent.implicitHeight + Style.marginS * 2

        color: isActive ? Color.mPrimary : (tabBtnMouse.containsMouse ? Color.mHover : "transparent")
        radius: Style.radiusS

        Behavior on color {
            ColorAnimation {
                duration: 120
            }
        }

        RowLayout {
            id: tabBtnContent
            anchors.centerIn: parent
            spacing: Style.marginS

            NIcon {
                icon: tabBtn.icon
                color: tabBtn.isActive ? Color.mOnPrimary : Color.mOnSurfaceVariant
                pointSize: Style.fontSizeM
            }

            NText {
                text: tabBtn.label
                color: tabBtn.isActive ? Color.mOnPrimary : Color.mOnSurfaceVariant
                pointSize: Style.fontSizeS
                font.weight: tabBtn.isActive ? Font.Medium : Font.Normal
            }
        }

        MouseArea {
            id: tabBtnMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: tabBtn.clicked()
        }
    }

    // Panel
    Rectangle {
        id: panelContainer
        anchors.fill: parent
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            color: Color.mSurface
            radius: Style.radiusL
            border.color: Style.capsuleBorderColor
            border.width: Style.capsuleBorderWidth
            clip: true

            ColumnLayout {
                anchors {
                    fill: parent
                    margins: 10
                }
                spacing: 10

                // Header
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 2

                    NIcon {
                        icon: "brand-mastercard"
                        color: Color.mPrimary
                        pointSize: Style.fontSizeL
                    }

                    NText {
                        text: "Slot Machine"
                        pointSize: Style.fontSizeL
                        font.weight: Font.Bold
                        color: Color.mOnSurface
                        Layout.fillWidth: true
                        leftPadding: Style.marginS
                    }

                    NIconButton {
                        icon: "x"
                        onClicked: {
                            if (pluginApi)
                                pluginApi.closePanel(pluginApi.panelOpenScreen);
                        }
                    }
                }

                // Credits bar
                Rectangle {
                    Layout.fillWidth: true
                    height: 40 * Style.uiScaleRatio
                    color: Color.mSurfaceVariant
                    radius: Style.radiusM

                    RowLayout {
                        anchors {
                            fill: parent
                            margins: Style.marginM
                        }
                        spacing: Style.marginS

                        NIcon {
                            icon: "coin"
                            color: Color.mPrimary
                        }

                        NText {
                            text: "Credits: " + root.credits
                            color: Color.mOnSurface
                            pointSize: Style.fontSizeM
                            font.weight: Font.Medium
                            Layout.fillWidth: true
                        }

                        NText {
                            text: (root.machine?.totalSpins ?? 0) + " spins"
                            color: Color.mOnSurfaceVariant
                            pointSize: Style.fontSizeS
                        }
                    }
                }

                // Tab bar
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: tabRow.implicitHeight + Style.marginS * 2
                    color: Color.mSurfaceVariant
                    radius: Style.radiusM

                    RowLayout {
                        id: tabRow
                        anchors.centerIn: parent
                        spacing: Style.marginS

                        TabButton {
                            icon: "play-card-7"
                            label: "Spin"
                            isActive: root.activeTab === 0
                            onClicked: root.activeTab = 0
                        }

                        TabButton {
                            icon: "list"
                            label: "Paytable"
                            isActive: root.activeTab === 1
                            onClicked: root.activeTab = 1
                        }
                    }
                }

                // Tab content
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    // Spin tab
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 6
                        visible: root.activeTab === 0

                        Rectangle {
                            Layout.fillWidth: true
                            height: 170 * Style.uiScaleRatio
                            radius: Style.radiusL
                            clip: true

                            color: {
                                if (!root.flashActive)
                                    return Color.mSurfaceVariant;
                                if (root.lastResult === "jackpot")
                                    return "#FFD700";
                                if (root.lastResult === "win" || root.lastResult === "smallwin")
                                    return Color.mPrimary;
                                return Color.mSurfaceVariant;
                            }
                            Behavior on color {
                                ColorAnimation {
                                    duration: 60
                                }
                            }

                            border.color: root.jackpotActive ? "#FFD700" : Style.capsuleBorderColor
                            border.width: root.jackpotActive ? 3 : Style.capsuleBorderWidth

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: Style.marginL

                                ReelColumn {
                                    reelIndex: 0
                                    symbolIndex: root.reel0
                                    symbols: root.symbols
                                    isSpinning: root.reel0Spinning
                                    isWin: root.lastResult === "win" || root.lastResult === "jackpot" || root.lastResult === "smallwin"
                                    flashActive: root.flashActive
                                }
                                ReelColumn {
                                    reelIndex: 1
                                    symbolIndex: root.reel1
                                    symbols: root.symbols
                                    isSpinning: root.reel1Spinning
                                    isWin: root.lastResult === "win" || root.lastResult === "jackpot" || root.lastResult === "smallwin"
                                    flashActive: root.flashActive
                                }
                                ReelColumn {
                                    reelIndex: 2
                                    symbolIndex: root.reel2
                                    symbols: root.symbols
                                    isSpinning: root.reel2Spinning
                                    isWin: root.lastResult === "win" || root.lastResult === "jackpot" || root.lastResult === "smallwin"
                                    flashActive: root.flashActive
                                }
                            }
                        }

                        NText {
                            Layout.alignment: Qt.AlignHCenter
                            text: {
                                if (root.spinning)
                                    return "Spinning...";
                                if (root.lastResult === "jackpot")
                                    return "JACKPOT! +77 credits!";
                                if (root.lastResult === "win")
                                    return "Winner! +5 credits!";
                                if (root.lastResult === "smallwin")
                                    return "Two of a kind! +2 credits!";
                                if (root.lastResult === "loss")
                                    return "No match. Try again!";
                                return "Press SPIN to play";
                            }
                            color: {
                                if (root.lastResult === "jackpot")
                                    return "#FFD700";
                                if (root.lastResult === "win" || root.lastResult === "smallwin")
                                    return Color.mPrimary;
                                return Color.mOnSurfaceVariant;
                            }
                            pointSize: root.lastResult === "jackpot" ? Style.fontSizeL : Style.fontSizeM
                            font.weight: root.lastResult === "jackpot" ? Font.Bold : Font.Normal
                        }

                        NButton {
                            Layout.fillWidth: true
                            text: {
                                if (root.credits <= 0)
                                    return "No credits - hit Reset Credits to keep playing!";
                                if (root.spinning)
                                    return "Spinning...";
                                return "SPIN  (-1 credit)";
                            }
                            backgroundColor: (!root.spinning && root.credits > 0) ? Color.mPrimary : Color.mSurfaceVariant
                            textColor: (!root.spinning && root.credits > 0) ? Color.mOnPrimary : Color.mOnSurfaceVariant
                            enabled: !root.spinning && root.credits > 0
                            onClicked: {
                                if (root.machine)
                                    root.machine.spin();
                            }
                        }

                        NButton {
                            Layout.fillWidth: true
                            text: "Reset Credits"
                            enabled: root.credits <= 0
                            backgroundColor: root.credits <= 0 ? Color.mPrimary : Color.mSurfaceVariant
                            textColor: root.credits <= 0 ? Color.mOnPrimary : Color.mOnSurfaceVariant
                            onClicked: {
                                if (root.machine)
                                    root.machine.resetCredits();
                            }
                        }
                    }

                    // Paytable tab
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 10
                        visible: root.activeTab === 1

                        // Payout rules
                        Rectangle {
                            Layout.fillWidth: true
                            color: Color.mSurfaceVariant
                            radius: Style.radiusM
                            implicitHeight: payoutRules.implicitHeight + 16

                            ColumnLayout {
                                id: payoutRules
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    top: parent.top
                                    margins: 8
                                }
                                spacing: 4

                                NText {
                                    text: "Payouts"
                                    pointSize: Style.fontSizeS
                                    font.weight: Font.Bold
                                    color: Color.mOnSurface
                                    bottomPadding: 2
                                }
                                NText {
                                    text: "777 triple  =  JACKPOT (+77 credits)"
                                    color: "#FFD700"
                                    pointSize: Style.fontSizeS
                                    font.weight: Font.Bold
                                }
                                NText {
                                    text: "Any triple  =  Win (+5 credits)"
                                    color: Color.mPrimary
                                    pointSize: Style.fontSizeS
                                }
                                NText {
                                    text: "Two match   =  Small win (+2 credits)"
                                    color: Color.mOnSurface
                                    pointSize: Style.fontSizeS
                                }
                                NText {
                                    text: "No match    =  Lose (-1 credit)"
                                    color: Color.mOnSurfaceVariant
                                    pointSize: Style.fontSizeS
                                }
                            }
                        }

                        // Symbol list (scrollable)
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: Color.mSurfaceVariant
                            radius: Style.radiusM
                            clip: true

                            Flickable {
                                anchors {
                                    fill: parent
                                    margins: 8
                                }
                                contentHeight: symbolList.implicitHeight
                                clip: true

                                ColumnLayout {
                                    id: symbolList
                                    width: parent.width
                                    spacing: 4

                                    NText {
                                        text: "All symbols"
                                        pointSize: Style.fontSizeS
                                        font.weight: Font.Bold
                                        color: Color.mOnSurface
                                        bottomPadding: 2
                                    }

                                    Repeater {
                                        model: root.symbols

                                        RowLayout {
                                            width: symbolList.width
                                            spacing: Style.marginS

                                            NIcon {
                                                icon: modelData.icon
                                                pointSize: Style.fontSizeM
                                                color: modelData.label === "7" ? "#FFD700" : Color.mOnSurface
                                            }

                                            NText {
                                                text: modelData.label
                                                pointSize: Style.fontSizeS
                                                color: modelData.label === "7" ? "#FFD700" : Color.mOnSurface
                                                font.weight: modelData.label === "7" ? Font.Bold : Font.Normal
                                                Layout.fillWidth: true
                                            }

                                            Rectangle {
                                                width: 150 * Style.uiScaleRatio
                                                height: 5 * Style.uiScaleRatio
                                                radius: 3
                                                color: Color.mSurface

                                                Rectangle {
                                                    width: parent.width * (modelData.weight / 385)
                                                    height: parent.height
                                                    radius: parent.radius
                                                    color: modelData.label === "7" ? "#FFD700" : Color.mPrimary
                                                }
                                            }

                                            NText {
                                                text: (modelData.weight / 385 * 100).toFixed(1) + "%"
                                                pointSize: Style.fontSizeXS
                                                color: Color.mOnSurfaceVariant

                                                Layout.preferredWidth: 30 * Style.uiScaleRatio
                                                horizontalAlignment: Text.AlignRight
                                                font.family: "monospace"
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Jackpot coin rain
        Item {
            anchors.fill: parent
            z: 10
            visible: root.jackpotActive
            clip: true

            Repeater {
                model: 30
                CoinParticle {
                    parentWidth: parent.width
                    parentHeight: parent.height
                }
            }
        }
    }
}

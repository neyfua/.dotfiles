import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

Rectangle {
    id: reel

    property int reelIndex: 0
    property int symbolIndex: 0
    property var symbols: []
    property bool isSpinning: false
    property bool isWin: false
    property bool flashActive: false

    width: 100 * Style.uiScaleRatio
    height: 140 * Style.uiScaleRatio
    color: Color.mSurface
    radius: Style.radiusM
    clip: true

    border.color: isWin && flashActive ? Color.mPrimary : Style.capsuleBorderColor
    border.width: isWin && flashActive ? 2 : Style.capsuleBorderWidth

    Behavior on border.color {
        ColorAnimation {
            duration: 80
        }
    }

    // Spinning ticker
    property int tickerIdx: 0
    property int displayIdx: symbolIndex

    // When symbolIndex is updated from outside (after landing), sync displayIdx
    onSymbolIndexChanged: {
        if (!isSpinning)
            displayIdx = symbolIndex;
    }

    Timer {
        running: reel.isSpinning
        interval: 60
        repeat: true
        onTriggered: {
            reel.tickerIdx = Math.floor(Math.random() * Math.max(1, reel.symbols.length));
        }
        onRunningChanged: {
            if (!running)
                reel.displayIdx = reel.symbolIndex;
        }
    }

    readonly property int shown: isSpinning ? tickerIdx : displayIdx

    // Content
    ColumnLayout {
        anchors.centerIn: parent
        spacing: Style.marginXS

        NIcon {
            Layout.alignment: Qt.AlignHCenter
            icon: {
                var syms = reel.symbols;
                if (!syms || syms.length === 0)
                    return "question-mark";
                return syms[reel.shown]?.icon ?? "question-mark";
            }
            color: {
                var syms = reel.symbols;
                if (!syms || syms.length === 0)
                    return Color.mOnSurface;
                var lbl = syms[reel.shown]?.label ?? "";
                if (lbl === "7")
                    return "#FFD700";
                if (reel.isWin && reel.flashActive)
                    return Color.mPrimary;
                return Color.mOnSurface;
            }
            pointSize: Style.fontSizeXL

            Behavior on color {
                ColorAnimation {
                    duration: 80
                }
            }
        }

        NText {
            Layout.alignment: Qt.AlignHCenter
            text: {
                var syms = reel.symbols;
                if (!syms || syms.length === 0)
                    return "";
                return syms[reel.shown]?.label ?? "";
            }
            color: {
                var syms = reel.symbols;
                if (!syms || syms.length === 0)
                    return Color.mOnSurfaceVariant;
                return syms[reel.shown]?.label === "7" ? "#FFD700" : Color.mOnSurfaceVariant;
            }
            pointSize: Style.fontSizeXS
            font.weight: {
                var syms = reel.symbols;
                if (!syms || syms.length === 0)
                    return Font.Normal;
                return syms[reel.shown]?.label === "7" ? Font.Bold : Font.Normal;
            }
        }
    }
}

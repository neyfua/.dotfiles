import QtQuick
import qs.Commons
import qs.Widgets

Item {
    id: coin

    property real parentWidth: 400
    property real parentHeight: 600

    // Each coin starts at a random x, above the top edge
    readonly property real startX: Math.random() * parentWidth
    readonly property real startY: -(20 + Math.random() * 80)   // staggered above top
    readonly property real endY: parentHeight + 20
    readonly property real driftX: (Math.random() - 0.5) * 120  // -60..+60 px drift
    readonly property real fallDur: 900 + Math.random() * 900     // 0.9 – 1.8 s
    readonly property real coinSize: Style.fontSizeL * (1.0 + Math.random() * 0.8) // varied sizes

    x: startX
    y: startY

    NIcon {
        anchors.centerIn: parent
        icon: "coin"
        color: "#FFD700"
        pointSize: coin.coinSize
        applyUiScale: true
    }

    // Fall downward
    NumberAnimation on y {
        from: coin.startY
        to: coin.endY
        duration: coin.fallDur
        running: true
        loops: Animation.Infinite
    }

    // Drift sideways
    NumberAnimation on x {
        from: coin.startX
        to: coin.startX + coin.driftX
        duration: coin.fallDur
        running: true
        loops: Animation.Infinite
    }

    // Spin the coin
    RotationAnimation on rotation {
        from: 0
        to: 360
        duration: 600 + Math.random() * 400
        direction: RotationAnimation.Clockwise
        running: true
        loops: Animation.Infinite
    }
}

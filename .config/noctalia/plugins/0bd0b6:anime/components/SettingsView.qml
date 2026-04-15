import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons

Item {
    id: settingsView

    property var pluginApi: null
    readonly property var anime: pluginApi?.mainInstance || null

    signal backRequested()

    component SettingChoiceButton: Button {
        id: choiceButton

        property bool active: false

        flat: true
        hoverEnabled: true
        implicitWidth: 92
        implicitHeight: 38

        background: Rectangle {
            radius: 19
            color: choiceButton.active
                ? Color.mPrimary
                : (choiceButton.hovered ? Color.mPrimaryContainer : Color.mSurface)
            border.width: 1
            border.color: choiceButton.active
                ? Color.mPrimary
                : (choiceButton.hovered
                    ? Color.mPrimary
                    : Qt.rgba(Color.mOutlineVariant.r, Color.mOutlineVariant.g, Color.mOutlineVariant.b, 0.55))
            opacity: !choiceButton.enabled ? 0.45 : (choiceButton.active || choiceButton.hovered ? 1 : 0.92)
            Behavior on color { ColorAnimation { duration: 160 } }
            Behavior on border.color { ColorAnimation { duration: 160 } }
            Behavior on opacity { NumberAnimation { duration: 160 } }
        }

        contentItem: Text {
            text: choiceButton.text
            color: choiceButton.active
                ? Color.mOnPrimary
                : (choiceButton.hovered ? Color.mOnPrimaryContainer : Color.mOnSurface)
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 12
            font.bold: choiceButton.active
            font.letterSpacing: 0.3
            opacity: choiceButton.enabled ? (choiceButton.hovered || choiceButton.active ? 1 : 0.86) : 0.5
            Behavior on opacity { NumberAnimation { duration: 160 } }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(Color.mSurfaceVariant.r, Color.mSurfaceVariant.g, Color.mSurfaceVariant.b, 0.08) }
            GradientStop { position: 1.0; color: Qt.rgba(Color.mSurface.r, Color.mSurface.g, Color.mSurface.b, 0.12) }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── Header ────────────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 68
            color: "transparent"
            z: 2

            Rectangle {
                anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                height: 1
                color: Color.mOutlineVariant
                opacity: 0.35
            }

            RowLayout {
                anchors {
                    fill: parent
                    leftMargin: 10
                    rightMargin: 16
                    topMargin: 8
                    bottomMargin: 8
                }
                spacing: 10

                Item {
                    width: 40
                    height: 40

                    Rectangle {
                        anchors.fill: parent
                        radius: 20
                        color: backArea.containsMouse ? Color.mSurface : "transparent"
                        border.width: 1
                        border.color: Qt.rgba(Color.mOutlineVariant.r, Color.mOutlineVariant.g, Color.mOutlineVariant.b, 0.45)
                        scale: backArea.containsMouse ? 1.06 : 1.0
                        Behavior on color { ColorAnimation { duration: 180 } }
                        Behavior on border.color { ColorAnimation { duration: 180 } }
                        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "←"
                        font.pixelSize: 18
                        color: Color.mOnSurfaceVariant
                        opacity: backArea.containsMouse ? 1 : 0.82
                        Behavior on opacity { NumberAnimation { duration: 180 } }
                    }

                    MouseArea {
                        id: backArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: settingsView.backRequested()
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 40
                    radius: 20
                    color: Qt.rgba(Color.mSurface.r, Color.mSurface.g, Color.mSurface.b, 0.88)
                    border.width: 1
                    border.color: Qt.rgba(Color.mOutlineVariant.r, Color.mOutlineVariant.g, Color.mOutlineVariant.b, 0.45)

                    Row {
                        anchors {
                            left: parent.left
                            verticalCenter: parent.verticalCenter
                            leftMargin: 14
                        }
                        spacing: 8

                        Rectangle {
                            width: 24
                            height: 24
                            radius: 12
                            color: Qt.rgba(Color.mPrimary.r, Color.mPrimary.g, Color.mPrimary.b, 0.14)

                            Text {
                                anchors.centerIn: parent
                                text: "⚙"
                                font.pixelSize: 12
                                color: Color.mPrimary
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1

                            Text {
                                text: "Settings"
                                font.pixelSize: 14
                                font.bold: true
                                color: Color.mOnSurface
                            }

                            Text {
                                text: "Layout and browsing preferences"
                                font.pixelSize: 10
                                color: Color.mOnSurfaceVariant
                                opacity: 0.72
                            }
                        }
                    }
                }
            }
        }

        // ── Content ───────────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "transparent"

            ScrollView {
                id: settingsScroll
                anchors.fill: parent
                anchors.margins: 14
                contentWidth: availableWidth
                clip: true

                Column {
                    width: settingsScroll.availableWidth
                    spacing: 14

                    Rectangle {
                        width: parent.width
                        radius: 18
                        color: Qt.rgba(Color.mSurfaceVariant.r, Color.mSurfaceVariant.g, Color.mSurfaceVariant.b, 0.7)
                        border.width: 1
                        border.color: Qt.rgba(Color.mOutlineVariant.r, Color.mOutlineVariant.g, Color.mOutlineVariant.b, 0.38)
                        implicitHeight: heroColumn.implicitHeight + 28

                        Column {
                            id: heroColumn
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 8

                            Text {
                                text: "Tune the panel"
                                font.pixelSize: 17
                                font.bold: true
                                color: Color.mOnSurface
                            }

                            Text {
                                width: parent.width
                                text: "Adjust the drawer width, poster density, and playback provider so browsing feels right on your screen."
                                wrapMode: Text.Wrap
                                lineHeight: 1.35
                                font.pixelSize: 11
                                color: Color.mOnSurfaceVariant
                                opacity: 0.82
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        radius: 20
                        color: Qt.rgba(Color.mSurface.r, Color.mSurface.g, Color.mSurface.b, 0.86)
                        border.width: 1
                        border.color: Qt.rgba(Color.mOutlineVariant.r, Color.mOutlineVariant.g, Color.mOutlineVariant.b, 0.4)
                        implicitHeight: panelSection.implicitHeight + 32

                        Column {
                            id: panelSection
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 12

                            Row {
                                spacing: 10

                                Rectangle {
                                    width: 28
                                    height: 28
                                    radius: 14
                                    color: Qt.rgba(Color.mPrimary.r, Color.mPrimary.g, Color.mPrimary.b, 0.12)

                                    Text {
                                        anchors.centerIn: parent
                                        text: "▣"
                                        font.pixelSize: 12
                                        color: Color.mPrimary
                                    }
                                }

                                Column {
                                    spacing: 2

                                    Text {
                                        text: "Panel Size"
                                        font.pixelSize: 14
                                        font.bold: true
                                        color: Color.mOnSurface
                                    }

                                    Text {
                                        text: "Controls how wide the plugin drawer appears"
                                        font.pixelSize: 11
                                        color: Color.mOnSurfaceVariant
                                        opacity: 0.72
                                    }
                                }
                            }

                            Flow {
                                width: parent.width
                                spacing: 10

                                Repeater {
                                    model: [
                                        { label: "Small",  value: "small" },
                                        { label: "Medium", value: "medium" },
                                        { label: "Large",  value: "large" }
                                    ]

                                    delegate: SettingChoiceButton {
                                        text: modelData.label
                                        active: anime?.panelSize === modelData.value
                                        onClicked: if (anime) anime.setSetting("panelSize", modelData.value)
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        radius: 20
                        color: Qt.rgba(Color.mSurface.r, Color.mSurface.g, Color.mSurface.b, 0.86)
                        border.width: 1
                        border.color: Qt.rgba(Color.mOutlineVariant.r, Color.mOutlineVariant.g, Color.mOutlineVariant.b, 0.4)
                        implicitHeight: posterSection.implicitHeight + 32

                        Column {
                            id: posterSection
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 12

                            Row {
                                spacing: 10

                                Rectangle {
                                    width: 28
                                    height: 28
                                    radius: 14
                                    color: Qt.rgba(Color.mPrimary.r, Color.mPrimary.g, Color.mPrimary.b, 0.12)

                                    Text {
                                        anchors.centerIn: parent
                                        text: "◫"
                                        font.pixelSize: 12
                                        color: Color.mPrimary
                                    }
                                }

                                Column {
                                    spacing: 2

                                    Text {
                                        text: "Poster Size"
                                        font.pixelSize: 14
                                        font.bold: true
                                        color: Color.mOnSurface
                                    }

                                    Text {
                                        text: "Adjust the size of anime covers in the grid"
                                        font.pixelSize: 11
                                        color: Color.mOnSurfaceVariant
                                        opacity: 0.72
                                    }
                                }
                            }

                            Flow {
                                width: parent.width
                                spacing: 10

                                Repeater {
                                    model: [
                                        { label: "Small",  value: "small" },
                                        { label: "Medium", value: "medium" },
                                        { label: "Large",  value: "large" }
                                    ]

                                    delegate: SettingChoiceButton {
                                        text: modelData.label
                                        active: anime?.posterSize === modelData.value
                                        enabled: !(anime?.panelSize === "small" && modelData.value === "small")
                                        onClicked: if (anime) anime.setSetting("posterSize", modelData.value)
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        radius: 20
                        color: Qt.rgba(Color.mSurface.r, Color.mSurface.g, Color.mSurface.b, 0.86)
                        border.width: 1
                        border.color: Qt.rgba(Color.mOutlineVariant.r, Color.mOutlineVariant.g, Color.mOutlineVariant.b, 0.4)
                        implicitHeight: providerSection.implicitHeight + 32

                        Column {
                            id: providerSection
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 12

                            Row {
                                spacing: 10

                                Rectangle {
                                    width: 28
                                    height: 28
                                    radius: 14
                                    color: Qt.rgba(Color.mPrimary.r, Color.mPrimary.g, Color.mPrimary.b, 0.12)

                                    Text {
                                        anchors.centerIn: parent
                                        text: "↺"
                                        font.pixelSize: 12
                                        color: Color.mPrimary
                                    }
                                }

                                Column {
                                    spacing: 2

                                    Text {
                                        text: "Preferred Provider"
                                        font.pixelSize: 14
                                        font.bold: true
                                        color: Color.mOnSurface
                                    }

                                    Text {
                                        text: "Prioritize a stream source, while still falling back if it fails"
                                        font.pixelSize: 11
                                        color: Color.mOnSurfaceVariant
                                        opacity: 0.72
                                    }
                                }
                            }

                            Flow {
                                width: parent.width
                                spacing: 10

                                Repeater {
                                    model: [
                                        { label: "Auto", value: "auto" },
                                        { label: "Default", value: "default" },
                                        { label: "SharePoint", value: "sharepoint" },
                                        { label: "HiAnime", value: "hianime" },
                                        { label: "YouTube", value: "youtube" }
                                    ]

                                    delegate: SettingChoiceButton {
                                        text: modelData.label
                                        active: anime?.preferredProvider === modelData.value
                                        onClicked: if (anime) anime.setSetting("preferredProvider", modelData.value)
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

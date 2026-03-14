import QtQuick
import Quickshell
import qs.Services.UI
import qs.Widgets

NIconButtonHot {
    property ShellScreen screen
    property var pluginApi: null

    icon: "brand-mastercard"
    tooltipText: "Slot Machine"

    onClicked: {
        if (pluginApi) {
            pluginApi.togglePanel(screen);
        }
    }

    onRightClicked: {
        if (pluginApi && pluginApi.manifest) {
            BarService.openPluginSettings(screen, pluginApi.manifest);
        }
    }
}

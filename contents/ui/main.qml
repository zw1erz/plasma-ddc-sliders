import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    property int display: 1
    property int brightness: 50
    property int contrast: 50
    property int maxBrightness: 100
    property int maxContrast: 100
    property bool loading: false
    property string errorText: ""

    Plasmoid.icon: "video-display-brightness"
    toolTipMainText: "Brightness & Contrast"
    toolTipSubText: "Brightness " + pct(brightness, maxBrightness) + "%, contrast " + pct(contrast, maxContrast) + "%"

    function pct(v, m) {
        return m > 0 ? Math.round(v * 100 / m) : v
    }

    function ddc(args) {
        return "LC_ALL=C ddcutil --display " + display + " " + args
    }

    function refresh() {
        loading = true
        errorText = ""
        exec.connectSource(ddc("getvcp 10 12"))
    }

    function setVcp(code, value) {
        exec.connectSource(ddc("--noverify setvcp " + code + " " + value))
    }

    function parseOutput(text) {
        var found = 0
        var lines = text.split("\n")
        for (var i = 0; i < lines.length; i++) {
            var m = /VCP code 0x(10|12).*current value\s*=\s*(\d+),\s*max value\s*=\s*(\d+)/.exec(lines[i])
            if (!m) {
                m = /^VCP\s+(10|12)\s+C\s+(\d+)\s+(\d+)/.exec(lines[i])
            }
            if (m) {
                found++
                if (m[1] === "10") {
                    brightness = parseInt(m[2])
                    maxBrightness = parseInt(m[3])
                } else {
                    contrast = parseInt(m[2])
                    maxContrast = parseInt(m[3])
                }
            }
        }
        return found
    }

    P5Support.DataSource {
        id: exec
        engine: "executable"
        connectedSources: []
        onNewData: (sourceName, data) => {
            exec.disconnectSource(sourceName)
            if (sourceName.indexOf("getvcp") !== -1) {
                root.loading = false
                var ok = root.parseOutput(data["stdout"] || "")
                if (ok === 0) {
                    root.errorText = "Could not read the monitor. Check in a terminal: ddcutil detect"
                }
            }
        }
    }

    Timer {
        id: brightnessTimer
        interval: 400
        onTriggered: root.setVcp(10, root.brightness)
    }

    Timer {
        id: contrastTimer
        interval: 400
        onTriggered: root.setVcp(12, root.contrast)
    }

    Component.onCompleted: refresh()
    onExpandedChanged: if (expanded) refresh()

    compactRepresentation: MouseArea {
        activeFocusOnTab: true
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        onClicked: root.expanded = !root.expanded

        Kirigami.Icon {
            anchors.fill: parent
            source: Qt.resolvedUrl("../icons/brightness-contrast.svg")
            isMask: true
            color: Kirigami.Theme.textColor
            active: parent.containsMouse
        }
    }

    fullRepresentation: Item {
        id: full
        implicitWidth: Kirigami.Units.gridUnit * 20
        implicitHeight: col.implicitHeight + Kirigami.Units.largeSpacing * 2

        Layout.minimumWidth: implicitWidth
        Layout.preferredWidth: implicitWidth
        Layout.minimumHeight: implicitHeight
        Layout.preferredHeight: implicitHeight

        ColumnLayout {
            id: col
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: Kirigami.Units.largeSpacing
            }
            spacing: Kirigami.Units.largeSpacing * 2

            // --- Brightness ---
            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.largeSpacing

                Kirigami.Icon {
                    source: Qt.resolvedUrl("../icons/brightness.svg")
                    isMask: true
                    color: Kirigami.Theme.textColor
                    Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                    Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                    Layout.alignment: Qt.AlignVCenter
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    RowLayout {
                        Layout.fillWidth: true
                        PlasmaComponents.Label {
                            text: "Brightness"
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                        PlasmaComponents.Label {
                            text: root.pct(root.brightness, root.maxBrightness) + "%"
                        }
                    }

                    PlasmaComponents.Slider {
                        Layout.fillWidth: true
                        from: 0
                        to: root.maxBrightness
                        stepSize: 1
                        value: root.brightness
                        onMoved: {
                            root.brightness = Math.round(value)
                            brightnessTimer.restart()
                        }
                    }
                }
            }

            // --- Contrast ---
            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.largeSpacing

                Kirigami.Icon {
                    source: Qt.resolvedUrl("../icons/contrast.svg")
                    isMask: true
                    color: Kirigami.Theme.textColor
                    Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                    Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                    Layout.alignment: Qt.AlignVCenter
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    RowLayout {
                        Layout.fillWidth: true
                        PlasmaComponents.Label {
                            text: "Contrast"
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                        PlasmaComponents.Label {
                            text: root.pct(root.contrast, root.maxContrast) + "%"
                        }
                    }

                    PlasmaComponents.Slider {
                        Layout.fillWidth: true
                        from: 0
                        to: root.maxContrast
                        stepSize: 1
                        value: root.contrast
                        onMoved: {
                            root.contrast = Math.round(value)
                            contrastTimer.restart()
                        }
                    }
                }
            }

            PlasmaComponents.Label {
                Layout.fillWidth: true
                visible: root.errorText !== ""
                text: root.errorText
                wrapMode: Text.WordWrap
                color: Kirigami.Theme.negativeTextColor
            }
        }
    }
}

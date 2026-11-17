import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import org.kde.kirigami as Kirigami

// Based on the stock Horizontal Bars face (org.kde.ksysguard.horizontalbars),
// but with square ends: a track tinted 10% toward the text color, with a fill on top.
ProgressBar {
    id: bar

    Layout.fillWidth: true

    property color color
    // Where the refresh "scan" band is, from 0 (entering at the left edge) to
    // 1 (gone past the right edge); below 0 means no scan is showing.
    property real scanPosition: -1

    from: 0
    to: 100

    topPadding: topInset
    bottomPadding: bottomInset

    contentItem: Item {
        Rectangle {
            width: bar.visualPosition * parent.width
            height: parent.height
            color: bar.color
            radius: 0
        }

        // A soft light band sweeping across track and fill alike, clipped to
        // the bar. Drawn under the section gaps so it passes "behind" them.
        Item {
            anchors.fill: parent
            clip: true
            visible: bar.scanPosition >= 0

            Rectangle {
                readonly property real bandWidth: Math.max(parent.width * 0.35, Kirigami.Units.gridUnit)
                width: bandWidth
                height: parent.height
                x: -bandWidth + bar.scanPosition * (parent.width + bandWidth)
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 0.5; color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.55) }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }
        }

        // Four gaps split the bar into five 20% sections so the level can be
        // read at a glance. Drawn in the panel color, over track and fill alike.
        Repeater {
            model: 4

            Rectangle {
                width: Kirigami.Units.smallSpacing / 2
                height: parent.height
                x: parent.width * (index + 1) / 5 - width / 2
                color: Kirigami.Theme.backgroundColor
            }
        }
    }

    background: Rectangle {
        implicitWidth: 100
        implicitHeight: Kirigami.Units.largeSpacing
        color: Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, 0.1)
        radius: 0
    }
}

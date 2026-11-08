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

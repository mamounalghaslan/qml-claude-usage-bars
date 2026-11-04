import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import org.kde.kirigami as Kirigami

// Same look as the stock Horizontal Bars face (org.kde.ksysguard.horizontalbars):
// a pill track tinted 10% toward the text color, with a pill fill on top.
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
            radius: height / 2
        }
    }

    background: Rectangle {
        implicitWidth: 100
        implicitHeight: Kirigami.Units.largeSpacing
        color: Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, 0.1)
        radius: height / 2
    }
}

import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import org.kde.plasma.plasmoid
import org.kde.quickcharts.controls as ChartsControls

PlasmoidItem {
    id: root

    // Written by scripts/claude-usage-fetch on a systemd timer.
    readonly property string usageFile: "$HOME/.cache/claude-usage/usage.json"
    readonly property int staleAfterSeconds: 15 * 60
    readonly property real warnAbove: 90

    readonly property string fetchCommand: "$HOME/.local/bin/claude-usage-fetch; cat \"" + usageFile + "\" 2>/dev/null"

    property var usage: null
    property bool refreshing: false
    property real now: Date.now() / 1000

    readonly property bool stale: usage === null || !usage.ok
                                  || (now - (usage.fetched_at ?? 0)) > staleAfterSeconds

    readonly property var rows: [
        { label: i18n("Weekly"), entry: usage?.weekly ?? null },
        { label: i18n("Fable"), entry: usage?.fable ?? null }
    ]

    function percentOf(entry) {
        return entry ? Math.max(0, Math.min(100, entry.percent)) : 0
    }

    function colorOf(entry) {
        return percentOf(entry) > warnAbove ? Kirigami.Theme.neutralTextColor : Kirigami.Theme.highlightColor
    }

    function valueText(entry) {
        return entry ? Math.round(entry.percent) + "%" : "–"
    }

    function resetTime(entry) {
        return entry && entry.resets_at
               ? Qt.formatDateTime(new Date(entry.resets_at), Locale.ShortFormat)
               : ""
    }

    // The two limits normally reset together; show that time once, not per bar.
    readonly property string sharedReset: {
        const times = rows.map(r => resetTime(r.entry))
        return times.every(t => t !== "" && t === times[0]) ? times[0] : ""
    }

    preferredRepresentation: compactRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground | PlasmaCore.Types.ConfigurableBackground

    toolTipMainText: i18n("Claude usage")
    toolTipSubText: {
        const lines = rows.map(r => r.label + ": " + valueText(r.entry))
        if (stale) {
            lines.push(usage && usage.error ? i18n("Stale: %1", usage.error) : i18n("Stale"))
        }
        return lines.join("\n")
    }

    // Runs the fetch script right now, then reads what it wrote. The timer keeps
    // polling in the background; this is the "refresh on click" path.
    function refresh() {
        if (refreshing) {
            return
        }
        refreshing = true
        source.connectSource(fetchCommand)
    }

    P5Support.DataSource {
        id: source
        engine: "executable"
        interval: 30000
        connectedSources: ["cat \"" + root.usageFile + "\" 2>/dev/null"]
        onNewData: function (sourceName, data) {
            root.now = Date.now() / 1000
            try {
                root.usage = JSON.parse(data["stdout"])
            } catch (e) {
                root.usage = null
            }
            if (sourceName === root.fetchCommand) {
                disconnectSource(sourceName)
                root.refreshing = false
            }
        }
    }

    // Keeps the staleness check honest when the file stops changing.
    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: root.now = Date.now() / 1000
    }

    compactRepresentation: MouseArea {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 4.5
        Layout.preferredWidth: Kirigami.Units.gridUnit * 6
        Layout.minimumHeight: Kirigami.Units.smallSpacing * 2 + 1

        opacity: root.stale ? 0.5 : (root.refreshing ? 0.7 : 1)
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: function (mouse) {
            if (mouse.button === Qt.MiddleButton) {
                root.expanded = !root.expanded
            } else {
                root.refresh()
            }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 1

            Item { Layout.fillWidth: true }

            Repeater {
                model: root.rows

                Bar {
                    Layout.fillHeight: true
                    Layout.minimumHeight: Kirigami.Units.smallSpacing
                    Layout.maximumHeight: Kirigami.Units.largeSpacing

                    topInset: 0
                    bottomInset: 0

                    value: root.percentOf(modelData.entry)
                    color: root.colorOf(modelData.entry)
                }
            }

            Item { Layout.fillWidth: true }
        }
    }

    fullRepresentation: ColumnLayout {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 12
        Layout.preferredWidth: Kirigami.Units.gridUnit * 14
        spacing: Kirigami.Units.smallSpacing
        opacity: root.stale ? 0.5 : 1

        Kirigami.Heading {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: i18n("Claude usage")
            level: 2
        }

        Repeater {
            model: root.rows

            ColumnLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: Kirigami.Units.smallSpacing
                spacing: 0

                Bar {
                    value: root.percentOf(modelData.entry)
                    color: root.colorOf(modelData.entry)
                }

                ChartsControls.LegendDelegate {
                    Layout.fillWidth: true

                    name: modelData.label
                    shortName: modelData.label
                    value: root.valueText(modelData.entry)
                    indicator: Item {}

                    maximumValueWidth: Kirigami.Units.gridUnit * 2
                }

                Kirigami.Heading {
                    Layout.fillWidth: true
                    level: 5
                    opacity: 0.7
                    text: i18n("Resets %1", root.resetTime(modelData.entry))
                    visible: root.sharedReset === "" && root.resetTime(modelData.entry) !== ""
                }
            }
        }

        Kirigami.Heading {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            level: 5
            opacity: 0.7
            text: i18n("Resets %1", root.sharedReset)
            visible: root.sharedReset !== ""
        }

        Kirigami.Heading {
            Layout.fillWidth: true
            level: 5
            wrapMode: Text.Wrap
            color: Kirigami.Theme.neutralTextColor
            text: root.usage && root.usage.error ? i18n("Stale: %1", root.usage.error) : i18n("Waiting for data")
            visible: root.stale
        }
    }
}

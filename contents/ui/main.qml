/*
 * SPDX-FileCopyrightText: 2026 Zayed Al-Saidi <zayed.alsaidi@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.core as PlasmaCore

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground

    implicitWidth: 280
    implicitHeight: 140

    readonly property bool isArabic: Qt.locale().name.startsWith("ar") || Qt.application.layoutDirection === Qt.RightToLeft

    property bool isPeak: false
    property bool isWeekday: true
    property string statusText: ""
    property string timeRemainingText: ""
    property color statusColor: "#2ecc71"
    property real dayProgressFraction: 0.0

    property real peak1StartFrac: 0
    property real peak1EndFrac: 0
    property real peak2StartFrac: 0
    property real peak2EndFrac: 0

    function updateStatus() {
        var now = new Date();
        var utcDay = now.getUTCDay(); // 0 = Sun, 1 = Mon, ..., 6 = Sat
        var utcHours = now.getUTCHours();
        var utcMinutes = now.getUTCMinutes();
        var utcSeconds = now.getUTCSeconds();

        var totalUtcSeconds = utcHours * 3600 + utcMinutes * 60 + utcSeconds;

        var localHours = now.getHours();
        var localMinutes = now.getMinutes();
        var localSeconds = now.getSeconds();
        var totalLocalSeconds = localHours * 3600 + localMinutes * 60 + localSeconds;
        root.dayProgressFraction = totalLocalSeconds / 86400.0;

        var localOffsetSec = (now.getTimezoneOffset() * -60);
        
        var p1StartLocalSec = (3600 + localOffsetSec + 86400) % 86400;
        var p1EndLocalSec = (14400 + localOffsetSec + 86400) % 86400;
        var p2StartLocalSec = (21600 + localOffsetSec + 86400) % 86400;
        var p2EndLocalSec = (36000 + localOffsetSec + 86400) % 86400;

        root.peak1StartFrac = p1StartLocalSec / 86400.0;
        root.peak1EndFrac = p1EndLocalSec / 86400.0;
        root.peak2StartFrac = p2StartLocalSec / 86400.0;
        root.peak2EndFrac = p2EndLocalSec / 86400.0;

        root.isWeekday = (utcDay >= 1 && utcDay <= 5);

        var inWindow1 = (totalUtcSeconds >= 3600 && totalUtcSeconds < 14400);
        var inWindow2 = (totalUtcSeconds >= 21600 && totalUtcSeconds < 36000);

        root.isPeak = root.isWeekday && (inWindow1 || inWindow2);

        if (root.isPeak) {
            root.statusText = root.isArabic ? "ذروة" : "PEAK";
            root.statusColor = "#e74c3c";

            var nextChangeSeconds = inWindow1 ? 14400 : 36000;
            var diff = nextChangeSeconds - totalUtcSeconds;
            root.timeRemainingText = (root.isArabic ? "متبقي " : "") + formatDiff(diff) + (root.isArabic ? "" : " left");
        } else {
            root.statusText = root.isArabic ? "خارج الذروة" : "OFF-PEAK";
            root.statusColor = "#2ecc71";

            var secondsUntilPeak = 0;
            if (root.isWeekday && totalUtcSeconds < 3600) {
                secondsUntilPeak = 3600 - totalUtcSeconds;
            } else if (root.isWeekday && totalUtcSeconds >= 14400 && totalUtcSeconds < 21600) {
                secondsUntilPeak = 21600 - totalUtcSeconds;
            } else {
                var secondsToEndOfDay = 86400 - totalUtcSeconds;
                if (utcDay === 5) { // Friday
                    secondsUntilPeak = secondsToEndOfDay + (2 * 86400) + 3600;
                } else if (utcDay === 6) { // Saturday
                    secondsUntilPeak = secondsToEndOfDay + (1 * 86400) + 3600;
                } else if (utcDay === 0) { // Sunday
                    secondsUntilPeak = secondsToEndOfDay + 3600;
                } else {
                    secondsUntilPeak = secondsToEndOfDay + 3600;
                }
            }
            root.timeRemainingText = (root.isArabic ? "متبقي " : "") + formatDiff(secondsUntilPeak) + (root.isArabic ? "" : " left");
        }
    }

    function formatDiff(totalSec) {
        var hrs = Math.floor(totalSec / 3600);
        var mins = Math.floor((totalSec % 3600) / 60);
        var secs = totalSec % 60;

        if (root.isArabic) {
            if (hrs > 0) {
                return hrs + " س " + mins + " د";
            }
            return mins + " د " + secs + " ث";
        } else {
            if (hrs > 0) {
                return hrs + "h " + mins + "m";
            }
            return mins + "m " + secs + "s";
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.updateStatus()
    }

    // --- Compact Representation ---
    compactRepresentation: Item {
        Layout.minimumWidth: labelLayout.implicitWidth + 8

        ColumnLayout {
            id: labelLayout
            anchors.centerIn: parent
            spacing: 2

            PlasmaComponents.Label {
                text: root.isArabic ? "توقيت ديب سيك" : "DeepSeek Timing"
                font.pixelSize: 10
                font.bold: true
                opacity: 0.8
                Layout.alignment: Qt.AlignLeft
            }

            RowLayout {
                spacing: 5
                Layout.alignment: Qt.AlignLeft

                Rectangle {
                    width: 8
                    height: 8
                    radius: 4
                    color: root.statusColor
                }

                PlasmaComponents.Label {
                    text: root.statusText
                    font.bold: true
                    font.pixelSize: 11
                }
            }

            PlasmaComponents.Label {
                text: root.timeRemainingText
                font.pixelSize: 9
                opacity: 0.7
                Layout.alignment: Qt.AlignLeft
            }
        }

        PlasmaComponents.ToolTip {
            text: (root.isArabic ? "توقيت ديب سيك\nالحالة: " : "DeepSeek Timing\nStatus: ") + root.statusText + (root.isArabic ? "\nالوقت المتبقي: " : "\nTime Left: ") + root.timeRemainingText
        }
    }

    // --- Full Representation ---
    fullRepresentation: Item {
        Layout.minimumWidth: 260
        Layout.minimumHeight: 130
        Layout.preferredWidth: 280
        Layout.preferredHeight: 140

        ColumnLayout {
            anchors.fill: parent
            spacing: 6

            PlasmaComponents.Label {
                text: root.isArabic ? "توقيت ديب سيك" : "DeepSeek Timing"
                font.pixelSize: 14
                font.bold: true
                opacity: 0.9
                Layout.alignment: Qt.AlignLeft
            }

            RowLayout {
                spacing: 8
                Layout.alignment: Qt.AlignLeft

                Rectangle {
                    width: 10
                    height: 10
                    radius: 5
                    color: root.statusColor
                }

                PlasmaComponents.Label {
                    text: root.statusText
                    font.pixelSize: 16
                    font.bold: true
                }
            }

            PlasmaComponents.Label {
                text: root.timeRemainingText
                font.pixelSize: 12
                opacity: 0.8
                Layout.alignment: Qt.AlignLeft
            }

            Item {
                Layout.fillHeight: true
            }

            // Timeline Container Block
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                LayoutMirroring.enabled: false
                LayoutMirroring.childrenInherit: true

                // 1. Timeline Track Bar
                Rectangle {
                    id: timelineTrack
                    Layout.fillWidth: true
                    implicitHeight: 14
                    radius: 4
                    color: "#2ecc71"
                    clip: true

                    // Peak Window 1
                    Rectangle {
                        x: {
                            var start = root.isArabic ? (1.0 - root.peak1EndFrac) : root.peak1StartFrac;
                            return parent.width * start;
                        }
                        width: parent.width * Math.abs(root.peak1EndFrac - root.peak1StartFrac)
                        height: parent.height
                        color: "#e74c3c"
                        visible: root.isWeekday && width > 0
                    }

                    // Peak Window 2
                    Rectangle {
                        x: {
                            var start = root.isArabic ? (1.0 - root.peak2EndFrac) : root.peak2StartFrac;
                            return parent.width * start;
                        }
                        width: parent.width * Math.abs(root.peak2EndFrac - root.peak2StartFrac)
                        height: parent.height
                        color: "#e74c3c"
                        visible: root.isWeekday && width > 0
                    }

                    // Tick 1 (Peak 1 Start)
                    Rectangle {
                        x: Math.max(0, Math.min(parent.width - 1, parent.width * (root.isArabic ? (1.0 - root.peak1StartFrac) : root.peak1StartFrac)))
                        width: 1
                        height: parent.height
                        color: "#ffffff"
                        opacity: 0.9
                        visible: root.isWeekday
                    }

                    // Tick 2 (Peak 1 End)
                    Rectangle {
                        x: Math.max(0, Math.min(parent.width - 1, parent.width * (root.isArabic ? (1.0 - root.peak1EndFrac) : root.peak1EndFrac)))
                        width: 1
                        height: parent.height
                        color: "#ffffff"
                        opacity: 0.9
                        visible: root.isWeekday
                    }

                    // Tick 3 (Peak 2 Start)
                    Rectangle {
                        x: Math.max(0, Math.min(parent.width - 1, parent.width * (root.isArabic ? (1.0 - root.peak2StartFrac) : root.peak2StartFrac)))
                        width: 1
                        height: parent.height
                        color: "#ffffff"
                        opacity: 0.9
                        visible: root.isWeekday
                    }

                    // Tick 4 (Peak 2 End)
                    Rectangle {
                        x: Math.max(0, Math.min(parent.width - 1, parent.width * (root.isArabic ? (1.0 - root.peak2EndFrac) : root.peak2EndFrac)))
                        width: 1
                        height: parent.height
                        color: "#ffffff"
                        opacity: 0.9
                        visible: root.isWeekday
                    }

                    // Needle Indicator
                    Rectangle {
                        x: {
                            var frac = root.isArabic ? (1.0 - root.dayProgressFraction) : root.dayProgressFraction;
                            return Math.max(0, Math.min(parent.width - 2, (parent.width * frac) - 1));
                        }
                        width: 2
                        height: parent.height
                        color: "#ffffff"
                        z: 2
                    }
                }

                // 2. Overlay Labels Container for Peak Hours
                Item {
                    id: labelsContainer
                    Layout.fillWidth: true
                    implicitHeight: 14
                    visible: root.isWeekday

                    function getLocalHour(frac) {
                        var localSec = Math.round(frac * 86400);
                        return (Math.floor(localSec / 3600) % 24).toString();
                    }

                    // Peak 1 Start Label
                    PlasmaComponents.Label {
                        text: labelsContainer.getLocalHour(root.peak1StartFrac)
                        font.pixelSize: 9
                        font.bold: true
                        x: {
                            var frac = root.isArabic ? (1.0 - root.peak1StartFrac) : root.peak1StartFrac;
                            return Math.max(0, Math.min(parent.width - implicitWidth, (parent.width * frac) - (implicitWidth / 2)));
                        }
                    }

                    // Peak 1 End Label
                    PlasmaComponents.Label {
                        text: labelsContainer.getLocalHour(root.peak1EndFrac)
                        font.pixelSize: 9
                        font.bold: true
                        x: {
                            var frac = root.isArabic ? (1.0 - root.peak1EndFrac) : root.peak1EndFrac;
                            return Math.max(0, Math.min(parent.width - implicitWidth, (parent.width * frac) - (implicitWidth / 2)));
                        }
                    }

                    // Peak 2 Start Label
                    PlasmaComponents.Label {
                        text: labelsContainer.getLocalHour(root.peak2StartFrac)
                        font.pixelSize: 9
                        font.bold: true
                        x: {
                            var frac = root.isArabic ? (1.0 - root.peak2StartFrac) : root.peak2StartFrac;
                            return Math.max(0, Math.min(parent.width - implicitWidth, (parent.width * frac) - (implicitWidth / 2)));
                        }
                    }

                    // Peak 2 End Label
                    PlasmaComponents.Label {
                        text: labelsContainer.getLocalHour(root.peak2EndFrac)
                        font.pixelSize: 9
                        font.bold: true
                        x: {
                            var frac = root.isArabic ? (1.0 - root.peak2EndFrac) : root.peak2EndFrac;
                            return Math.max(0, Math.min(parent.width - implicitWidth, (parent.width * frac) - (implicitWidth / 2)));
                        }
                    }
                }

                // 3. Base Time Scale Labels
                RowLayout {
                    Layout.fillWidth: true

                    PlasmaComponents.Label { text: root.isArabic ? "24:00" : "00:00"; font.pixelSize: 8; opacity: 0.5 }
                    Item { Layout.fillWidth: true }
                    PlasmaComponents.Label { text: root.isArabic ? "18:00" : "06:00"; font.pixelSize: 8; opacity: 0.5 }
                    Item { Layout.fillWidth: true }
                    PlasmaComponents.Label { text: "12:00"; font.pixelSize: 8; opacity: 0.5 }
                    Item { Layout.fillWidth: true }
                    PlasmaComponents.Label { text: root.isArabic ? "06:00" : "18:00"; font.pixelSize: 8; opacity: 0.5 }
                    Item { Layout.fillWidth: true }
                    PlasmaComponents.Label { text: root.isArabic ? "00:00" : "24:00"; font.pixelSize: 8; opacity: 0.5 }
                }
            }
        }
    }
}

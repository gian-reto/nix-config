/*
Adapted from: https://github.com/denonmaryland/omarchy-softly
Revision: a28ee6a550b8ed5e959b485fd94e06c1716b06ab.

MIT License

Copyright (c) 2026 DeNon Maryland

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

import QtQuick

Item {
    id: root
    readonly property real scaleFactor: 1.5
    readonly property real backgroundOpacity: 0.65
    readonly property real borderWidth: 1 / scaleFactor
    implicitWidth: 189 * scaleFactor
    implicitHeight: 64 * scaleFactor

    // Voxtype v1.1.1 injects these properties into its fullscreen custom loader.
    property string daemonState: "idle"
    property var audio: null
    property var theme: null
    // This renderer is self-contained: no declarative recipe layers or assets are needed.
    property var recipe: null
    property string assetRoot: ""

    readonly property bool recording: daemonState === "recording" || daemonState === "streaming"
    readonly property bool active: recording || daemonState === "transcribing"
    property bool sessionActive: false
    readonly property bool animating: sessionActive && visible
    property real rms: 0
    property real envelope: 0
    property var levels: Array(19).fill(0)
    property var shown: Array(19).fill(0)
    property real phase: 0
    property real presence: 0
    property real surfaceOpacity: 0
    property real contentPresence: 0
    property double startedAt: 0
    property int elapsed: 0

    readonly property color background: theme ? theme.color("background", "#12151c") : "#12151c"
    readonly property color foreground: theme ? theme.color("foreground", "#e6e8ee") : "#e6e8ee"
    readonly property color accent: theme ? theme.color("accent", "#3b82f6") : "#3b82f6"
    readonly property bool lightTheme: background.hslLightness > 0.5
    readonly property color floor: lightTheme ? Qt.darker(background, 1.12) : Qt.darker(background, 1.5)

    property real processingMix: daemonState === "transcribing" ? 1 : 0
    Behavior on processingMix { enabled: root.animating; NumberAnimation { duration: 180; easing.type: Easing.InOutCubic } }
    property real glow: daemonState === "transcribing" ? 0 : 1
    Behavior on glow { enabled: root.animating; NumberAnimation { duration: 220; easing.type: Easing.InOutCubic } }

    readonly property var glyphShapes: ({
        none: [[7, 7, 7, 7, 0], [7, 7, 7, 7, 0], [7, 7, 7, 7, 0]],
        more: [[2.5, 7, 2.5, 7, 1], [7, 7, 7, 7, 1], [11.5, 7, 11.5, 7, 1]]
    })
    component Morph: NumberAnimation { duration: 400; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.19, 1, 0.22, 1, 1, 1] }

    function syncState() {
        // Derived bindings may not have updated when daemonStateChanged runs.
        const recordingNow = daemonState === "recording" || daemonState === "streaming"
        const activeNow = recordingNow || daemonState === "transcribing"
        if (activeNow && !sessionActive) {
            startedAt = Date.now()
            elapsed = 0
            envelope = 0
            rms = 0
            levels = Array(19).fill(0)
            shown = Array(19).fill(0)
            arrival.restart()
        } else if (!activeNow) {
            // Native visibility ends at idle; idle is not an output-success acknowledgement.
            arrival.stop()
            presence = 0
            surfaceOpacity = 0
            contentPresence = 0
        }
        if (!recordingNow) rms = 0
        sessionActive = activeNow
    }
    onDaemonStateChanged: syncState()
    onAudioChanged: rms = 0
    Component.onCompleted: syncState()

    ParallelAnimation {
        id: arrival
        NumberAnimation { target: root; property: "presence"; to: 1; duration: 260; easing.type: Easing.OutCubic }
        NumberAnimation { target: root; property: "surfaceOpacity"; to: 1; duration: 160; easing.type: Easing.OutCubic }
        SequentialAnimation {
            PauseAnimation { duration: 40 }
            NumberAnimation { target: root; property: "contentPresence"; to: 1; duration: 180; easing.type: Easing.OutCubic }
        }
    }

    Connections {
        target: root.audio
        function onFrameReceived(peak, rms, vad, tsMs) {
            // The native bridge supplies a peak-derived RMS approximation, not measured RMS.
            root.rms = root.recording && Number.isFinite(rms) ? Math.max(0, Math.min(1, rms)) : 0
        }
        function onDisconnected() { root.rms = 0 }
    }

    Timer {
        interval: 40; repeat: true; running: root.animating
        onTriggered: {
            const target = Math.min(1, Math.sqrt(root.rms) * 2.2)
            root.envelope += (target - root.envelope) * (target > root.envelope ? 0.5 : 0.2)
            const live = root.daemonState === "transcribing" ? 0 : root.envelope * (0.55 + 0.45 * Math.random())
            root.levels = [live].concat(root.levels.slice(0, root.levels.length - 1))
            if (root.recording) root.elapsed = Math.floor((Date.now() - root.startedAt) / 1000)
        }
    }
    FrameAnimation {
        running: root.animating
        onTriggered: {
            root.phase += frameTime
            const k = 1 - Math.exp(-frameTime * 22)
            root.shown = root.shown.map((v, i) => v + (root.levels[i] - v) * k)
        }
    }

    function clock(s) { return Math.floor(s / 60) + ":" + (s % 60).toString().padStart(2, "0") }

    // Position at the bottom-center (with padding) in the fullscreen host.
    Item {
        width: 189; height: 64
        scale: root.scaleFactor
        transformOrigin: Item.Bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 14 * root.scaleFactor
        Item {
            id: motionSurface
            width: 189; height: 64
            anchors.centerIn: parent
            anchors.verticalCenterOffset: 4 * (1 - root.presence)
            // Composite the padded surface so arrival opacity applies uniformly.
            opacity: root.surfaceOpacity
            layer.enabled: true
            layer.smooth: true
            // Match the scaled size so compositing does not blur the enlarged content.
            layer.textureSize: Qt.size(width * root.scaleFactor, height * root.scaleFactor)
            transform: Scale {
                origin.x: 94.5; origin.y: 32
                xScale: 0.96 + 0.04 * root.presence
                yScale: xScale
            }
            Item {
                anchors.fill: parent
                // Composite the background once so overlapping details stay translucent.
                opacity: root.backgroundOpacity
                layer.enabled: true
                layer.smooth: true
                layer.textureSize: Qt.size(width * root.scaleFactor, height * root.scaleFactor)
                Item {
                    width: pebble.width; height: pebble.height
                    anchors.centerIn: parent
                    Rectangle {
                        anchors.fill: parent; anchors.margins: -root.borderWidth
                        radius: height / 2
                        color: Qt.rgba(0, 0, 0, root.lightTheme ? 0.14 : 0.55)
                    }
                    // Keep the bevel thin independently of the pill's overall scale.
                    Rectangle {
                        anchors.fill: parent; radius: height / 2
                        color: Qt.tint(Qt.darker(root.background, 1.1), Qt.rgba(0, 0, 0, root.lightTheme ? 0.12 : 0.45))
                    }
                    Rectangle {
                        width: parent.width; height: parent.height - root.borderWidth; radius: height / 2
                        color: Qt.tint(Qt.lighter(root.background, 1.13), Qt.rgba(1, 0.98, 0.92, root.lightTheme ? 0.6 : 0.18))
                    }
                    Rectangle {
                        y: root.borderWidth; width: parent.width; height: parent.height - 2 * root.borderWidth; radius: height / 2
                        gradient: Gradient {
                            GradientStop { position: 0; color: Qt.lighter(root.background, root.lightTheme ? 1.03 : 1.13) }
                            GradientStop { position: 0.5; color: root.background }
                            GradientStop { position: 1; color: Qt.darker(root.background, 1.1) }
                        }
                    }
                    Item {
                        x: groove.x; y: groove.y
                        width: groove.width; height: groove.height
                        opacity: groove.opacity
                        // Lower lip catches the backlight; the upper edge falls into shadow.
                        Rectangle {
                            anchors.fill: parent; radius: height / 2
                            color: Qt.tint(root.floor, Qt.alpha(root.accent, 0.12 + 0.1 * root.glow))
                        }
                        Rectangle {
                            width: parent.width; height: parent.height - root.borderWidth; radius: height / 2
                            color: Qt.darker(root.floor, root.lightTheme ? 1.15 : 1.6)
                        }
                        Rectangle {
                            id: grooveFloor
                            y: 1.25 * root.borderWidth; width: parent.width; height: parent.height - 2.25 * root.borderWidth; radius: height / 2
                            color: root.floor
                        }
                        Rectangle {
                            anchors.fill: grooveFloor; radius: height / 2
                            opacity: root.glow * (0.82 + 0.18 * root.envelope)
                            // The backlight blooms from the centre as the content arrives.
                            transform: Scale {
                                origin.x: grooveFloor.width / 2
                                xScale: 0.55 + 0.45 * root.contentPresence
                            }
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0; color: Qt.alpha(root.accent, 0) }
                                GradientStop { position: 0.22; color: Qt.alpha(root.accent, 0.08) }
                                GradientStop { position: 0.5; color: Qt.alpha(root.accent, 0.3) }
                                GradientStop { position: 0.78; color: Qt.alpha(root.accent, 0.08) }
                                GradientStop { position: 1; color: Qt.alpha(root.accent, 0) }
                            }
                        }
                        // Inner shadow under the top edge keeps the glow low in the cut.
                        Rectangle {
                            anchors.fill: grooveFloor; radius: height / 2
                            gradient: Gradient {
                                GradientStop { position: 0; color: Qt.alpha(Qt.darker(root.floor, 1.4), 0.8) }
                                GradientStop { position: 0.45; color: Qt.alpha(root.floor, 0) }
                            }
                        }
                    }
                }
            }
            Item {
                id: pebble
                width: 153; height: 32.3
                anchors.centerIn: parent
                Item {
                    id: groove
                    opacity: root.contentPresence
                    x: 5.25; width: 107; height: 22
                    anchors.verticalCenter: parent.verticalCenter
                    Repeater {
                        model: 19
                        Rectangle {
                            required property int index
                            readonly property real fromCentre: Math.abs(index - 9) / 9
                            readonly property real taper: 1 - 0.65 * fromCentre
                            // Centre-out reveal: the outermost bar trails by ~60 ms (≈7 ms per step).
                            readonly property real reveal: Math.max(0, Math.min(1, (root.contentPresence - 0.35 * fromCentre) / 0.65))
                            readonly property real liveActivity: (root.shown[index] || 0) * taper
                            readonly property real processingActivity: 0.15 + 0.32 * (0.5 + 0.5 * Math.sin(root.phase * 6 - index * 0.55))
                            readonly property real activity: liveActivity * (1 - root.processingMix)
                                + processingActivity * root.processingMix
                            x: 8 + index * 4.917; width: 2.5
                            height: 2.5 + Math.min(1, activity) * 13
                            anchors.verticalCenter: parent.verticalCenter
                            radius: 1.25
                            color: root.foreground
                            opacity: (0.95 - 0.25 * root.processingMix) * reveal
                        }
                    }
                }
                Item {
                    id: clockArea
                    x: 112; width: 41; height: 32.3
                    opacity: root.contentPresence
                    // The timer clears before the glyph shows, so text and icon never overlap.
                    readonly property real timerMix: 1 - root.processingMix
                    Text {
                        anchors.centerIn: parent
                        text: root.clock(root.elapsed)
                        color: Qt.alpha(root.foreground, 0.76)
                        font.family: "Adwaita Sans"; font.pixelSize: 11; font.weight: Font.Medium
                        font.features: { "tnum": 1 }
                        opacity: clockArea.timerMix * clockArea.timerMix
                    }
                    // Exponential ease-out gives the processing dots a quick snap with a soft settle.
                    Item {
                        id: glyph
                        readonly property real unit: 0.8
                        readonly property string shape: root.daemonState === "transcribing" ? "more" : "none"
                        width: 14 * unit; height: 14 * unit
                        anchors.centerIn: parent
                        // Composite the morphing strokes once for even ink.
                        layer.enabled: true
                        layer.smooth: true
                        layer.textureSize: Qt.size(width * root.scaleFactor, height * root.scaleFactor)
                        opacity: 0.76 * Math.max(0, Math.min(1, 1 - 2.5 * clockArea.timerMix))
                        Repeater {
                            model: 3
                            Rectangle {
                                required property int index
                                readonly property var target: root.glyphShapes[glyph.shape][index]
                                property real x1: target[0]
                                property real y1: target[1]
                                property real x2: target[2]
                                property real y2: target[3]
                                property real ink: target[4]
                                property real stroke: glyph.shape === "more" ? 2.5 : 1.5
                                Behavior on x1 { enabled: root.animating; Morph {} }
                                Behavior on y1 { enabled: root.animating; Morph {} }
                                Behavior on x2 { enabled: root.animating; Morph {} }
                                Behavior on y2 { enabled: root.animating; Morph {} }
                                Behavior on ink { enabled: root.animating; Morph {} }
                                Behavior on stroke { enabled: root.animating; Morph {} }
                                width: Math.hypot(x2 - x1, y2 - y1) * glyph.unit + stroke
                                height: stroke; radius: stroke / 2
                                x: (x1 + x2) / 2 * glyph.unit - width / 2
                                y: (y1 + y2) / 2 * glyph.unit - height / 2
                                rotation: Math.atan2(y2 - y1, x2 - x1) * 180 / Math.PI
                                antialiasing: true
                                opacity: ink
                                color: root.foreground
                            }
                        }
                    }
                }
            }
        }
    }
}

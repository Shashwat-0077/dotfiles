import Quickshell
import QtQuick 2.15

ShellRoot {
    PanelWindow {
        id: panel

        // --- Config ---
        property string primaryColor: "#ffffff"
        property int panelWidth: 600
        property int panelHeight: 60
        property int cornerSize: 15
        property int animDuration: 100

        anchors.top: true
        implicitHeight: panelHeight  // enough room for corners
        implicitWidth: panelWidth + cornerSize * 2 // enough room for corners on both sides
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore

        // --- State ---
        property bool active: false
        property real progress: Math.max(0, Math.min(1, (mainPanel.y + mainPanel.height) / mainPanel.height))

        mask: Region {
            item: maskRect
        }

        Rectangle {
            id: maskRect
            x: mainPanel.x - panel.cornerSize
            y: 0
            color: "transparent"
            width: mainPanel.width + panel.cornerSize * 2
            height: panel.active ? panel.implicitHeight : 1
        }

        MouseArea {
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            width: mainPanel.width + panel.cornerSize * 2
            height: 1
            hoverEnabled: true
            propagateComposedEvents: true
            onEntered: panel.active = true
        }

        MouseArea {
            anchors.fill: mainPanel
            hoverEnabled: true
            propagateComposedEvents: true
            onExited: panel.active = false
        }

        Canvas {
            id: leftCorner
            x: mainPanel.x - width + 0.5
            y: 0
            width: panel.cornerSize
            height: panel.cornerSize * panel.progress
            onHeightChanged: requestPaint()
            onPaint: {
                var ctx = getContext("2d");
                ctx.reset();
                if (height <= 0)
                    return;
                ctx.beginPath();
                ctx.moveTo(0, 0);
                ctx.lineTo(width, 0);
                ctx.lineTo(width, height);
                ctx.arc(0, height, width, 0, -Math.PI / 2, true);
                ctx.closePath();
                ctx.fillStyle = panel.primaryColor;
                ctx.fill();
            }
        }

        Rectangle {
            id: mainPanel
            anchors.horizontalCenter: parent.horizontalCenter
            width: panel.panelWidth
            height: panel.panelHeight
            color: panel.primaryColor
            bottomLeftRadius: 10
            bottomRightRadius: 10
            y: panel.active ? 0 : -height
            Behavior on y {
                NumberAnimation {
                    duration: panel.animDuration
                    easing.type: Easing.OutQuad
                }
            }
        }

        Canvas {
            id: rightCorner
            x: mainPanel.x + mainPanel.width - 0.5
            y: 0
            width: panel.cornerSize
            height: panel.cornerSize * panel.progress
            onHeightChanged: requestPaint()
            onPaint: {
                var ctx = getContext("2d");
                ctx.reset();
                if (height <= 0)
                    return;
                ctx.beginPath();
                ctx.moveTo(0, 0);
                ctx.lineTo(0, height);
                ctx.arc(width, height, width, Math.PI, -Math.PI / 2, false);
                ctx.lineTo(width, 0);
                ctx.closePath();
                ctx.fillStyle = panel.primaryColor;
                ctx.fill();
            }
        }
    }
}



// Corner peice for refernce
Canvas {
    id: rightCorner
    width: topBar.outerRadiusWidth
    height: topBar.outerRadiusHeight

    onPaint: {
        var ctx = getContext("2d");
        ctx.reset();
        ctx.beginPath();
        ctx.moveTo(0, 0);
        ctx.lineTo(width, 0);
        ctx.quadraticCurveTo(0, 0, 0, height * topBar.progress);
        ctx.closePath();
        ctx.fillStyle = topBar.primaryColor;
        ctx.fill();
    }

    Connections {
        target: topBar
        function onProgressChanged() {
            rightCorner.requestPaint();
        }
    }
}

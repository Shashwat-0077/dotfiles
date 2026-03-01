import Quickshell
import QtQuick 2.15

ShellRoot {
    PanelWindow {
        id: topBar

        property int panelWidth: 600
        property int panelHeight: 50
        property int animDuration: 200
        property int radius: 10
        property int cornerWidth: 20
        property string primaryColor: "#ffffff"

        property real progress: 1

        implicitWidth: panelWidth
        implicitHeight: panelHeight

        anchors {
            top: true
        }

        color: "transparent"
        exclusionMode: ExclusionMode.Ignore

        // Animate progress instead of y
        Behavior on progress {
            NumberAnimation {
                duration: topBar.animDuration
                easing.type: Easing.OutQuad
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: topBar.progress = 1
            onExited: topBar.progress = 0
        }

        Row {
            spacing: -1

            // LEFT CORNER
            Canvas {
                id: leftCorner
                width: topBar.cornerWidth
                height: parent.height
                z: 9999
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();

                    let w = width;
                    let h = height * topBar.progress;
                    let baseRadius = topBar.radius;
                    let t = Math.min(1.0, h / (baseRadius * 2));

                    // Normalize entire shape to t
                    let bumpX = baseRadius * t;   // horizontal reach
                    let bumpY = baseRadius * t;   // vertical curve size
                    let midY = h / 2;             // curves always meet at center

                    ctx.beginPath();
                    ctx.moveTo(w, h);
                    ctx.lineTo(w, 0);
                    ctx.lineTo(0, 0);

                    // Single cubic from top-left to bottom, passing through the bump
                    // control points scale uniformly — no sliding, no squishing
                    ctx.bezierCurveTo(bumpX, 0           // top control: pulls right
                    , bumpX, midY - bumpY * 0.5  // eases into midpoint
                    , bumpX, midY         // meets exactly at center
                    );
                    ctx.bezierCurveTo(bumpX, midY + bumpY * 0.5  // eases out from midpoint
                    , bumpX, h           // bottom control: returns to baseline
                    , bumpX + bumpY, h    // exits horizontally
                    );

                    ctx.closePath();
                    ctx.fillStyle = topBar.primaryColor;
                    ctx.fill();
                }
                Connections {
                    target: topBar
                    function onProgressChanged() {
                        leftCorner.requestPaint();
                    }
                }
            }

            // MAIN PANEL
            Rectangle {
                id: mainPanel

                width: topBar.panelWidth
                height: topBar.panelHeight
                color: topBar.primaryColor

                // 👇 Position controlled by progress
                y: -height * (1 - topBar.progress)
            }

            // RIGHT CORNER
            // Canvas {
            //     id: rightCorner
            //     width: topBar.outerRadiusWidth
            //     height: topBar.outerRadiusHeight

            //     onPaint: {
            //         var ctx = getContext("2d");
            //         ctx.reset();
            //         ctx.beginPath();
            //         ctx.moveTo(0, 0);
            //         ctx.lineTo(width, 0);
            //         ctx.quadraticCurveTo(0, 0, 0, height * topBar.progress);
            //         ctx.closePath();
            //         ctx.fillStyle = topBar.primaryColor;
            //         ctx.fill();
            //     }

            //     Connections {
            //         target: topBar
            //         function onProgressChanged() {
            //             rightCorner.requestPaint();
            //         }
            //     }
            // }
        }
    }
}

// ShellRoot {
//     PanelWindow {
//         width: 400
//         height: 400
//         anchors.right: true
//         exclusionMode: ExclusionMode.Ignore

//         Canvas {
//             id: rightCorner
//             width: parent.width
//             height: parent.height

//             onPaint: {
//                 var ctx = getContext("2d");
//                 ctx.reset();
//                 ctx.beginPath();

//                 let w = width;
//                 let h = height;

//                 let maxHeight = 400;
//                 let t = Math.max(0, Math.min(1, h / maxHeight));

//                 let baseRadius = 80;
//                 let edgeX = baseRadius;

//                 let r = baseRadius * t;

//                 ctx.moveTo(w, h);
//                 ctx.lineTo(w, 0);
//                 ctx.lineTo(0, 0);

//                 // Top curve (less intense as t decreases)
//                 ctx.quadraticCurveTo(edgeX, 0, edgeX, r);

//                 // Vertical line stays fixed
//                 ctx.lineTo(edgeX, h - r);

//                 // Bottom curve
//                 ctx.quadraticCurveTo(edgeX, h, edgeX + r, h);

//                 ctx.closePath();
//                 ctx.fillStyle = "#ff0000";
//                 ctx.fill();
//             }
//         }
//     }
// }

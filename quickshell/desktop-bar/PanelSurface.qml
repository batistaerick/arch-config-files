import QtQuick
import "GlassStyle.js" as GlassStyle

Item {
    id: surface
    required property var hostWindow
    property color color: hostWindow.background
    property string edge: hostWindow.barEdge
    readonly property int contentInset: 14
    readonly property bool vertical: edge === "left" || edge === "right"
    readonly property real progress: hostWindow.revealProgress
    readonly property bool flushLeading: vertical ? hostWindow.y <= 0 : hostWindow.x <= 0
    readonly property bool flushTrailing: hostWindow.parent && (vertical
        ? hostWindow.y + hostWindow.height >= hostWindow.parent.height
        : hostWindow.x + hostWindow.width >= hostWindow.parent.width)
    default property alias panelContent: contents.data

    Item {
        id: reveal
        width: surface.vertical ? surface.width * surface.progress : surface.width
        height: surface.vertical ? surface.height : surface.height * surface.progress
        x: surface.edge === "right" ? surface.width - width : 0
        y: surface.edge === "bottom" ? surface.height - height : 0
        clip: true

        Canvas {
            id: outline
            anchors.fill: parent
            antialiasing: true
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            Connections {
                target: surface
                function onColorChanged() { outline.requestPaint(); }
                function onEdgeChanged() { outline.requestPaint(); }
                function onFlushLeadingChanged() { outline.requestPaint(); }
                function onFlushTrailingChanged() { outline.requestPaint(); }
            }
            Connections {
                target: surface.hostWindow
                function onGlassChanged() { outline.requestPaint(); }
                function onYChanged() { outline.requestPaint(); }
            }
            onPaint: {
                var ctx = getContext("2d");
                ctx.reset();
                var w = surface.vertical ? height : width;
                var h = surface.vertical ? width : height;
                if (w <= 0 || h <= 0) return;
                var sheen = ctx.createLinearGradient(0, 0, 0, height);
                var screenY = surface.hostWindow.y + reveal.y;
                var screenHeight = surface.hostWindow.parent ? surface.hostWindow.parent.height : height;
                sheen.addColorStop(0, Qt.rgba(1, 1, 1, GlassStyle.highlightAlpha(screenY, screenHeight)));
                sheen.addColorStop(1, Qt.rgba(1, 1, 1, GlassStyle.highlightAlpha(screenY + height, screenHeight)));
                if (surface.edge === "bottom") { ctx.translate(width, height); ctx.rotate(Math.PI); }
                else if (surface.edge === "left") { ctx.translate(0, height); ctx.rotate(-Math.PI / 2); }
                else if (surface.edge === "right") { ctx.translate(width, 0); ctx.rotate(Math.PI / 2); }
                var r = Math.min(14, w / 4, h / 2);
                var reversed = surface.edge === "bottom" || surface.edge === "left";
                var startInset = (reversed ? surface.flushTrailing : surface.flushLeading) ? 0 : r;
                var endInset = (reversed ? surface.flushLeading : surface.flushTrailing) ? 0 : r;
                // The two inward curves join the sheet to the bar; the outer
                // corners remain rounded as the sheet unfolds.
                GlassStyle.sheetPath(ctx, w, h, startInset, endInset, true);
                ctx.fillStyle = surface.color;
                ctx.fill();
                if (surface.hostWindow.glass) {
                    ctx.fillStyle = sheen;
                    ctx.fill();
                    ctx.save();
                    ctx.clip();
                    GlassStyle.sheetPath(ctx, w, h, startInset, endInset, false);
                    var rim = ctx.createLinearGradient(0, 0, w, h);
                    rim.addColorStop(0, "rgba(255,255,255,0.55)");
                    rim.addColorStop(0.45, "rgba(255,255,255,0.12)");
                    rim.addColorStop(0.75, "rgba(255,255,255,0.32)");
                    rim.addColorStop(1, "rgba(255,255,255,0.18)");
                    ctx.strokeStyle = "rgba(255,255,255,0.045)";
                    ctx.lineWidth = 12;
                    ctx.stroke();
                    ctx.strokeStyle = "rgba(255,255,255,0.08)";
                    ctx.lineWidth = 5;
                    ctx.stroke();
                    ctx.strokeStyle = rim;
                    ctx.lineWidth = 2;
                    ctx.stroke();
                    ctx.restore();
                }
            }
        }

        Item {
            id: contents
            width: Math.max(0, surface.width - surface.contentInset * 2)
            height: Math.max(0, surface.height - surface.contentInset * 2)
            x: surface.contentInset + (surface.edge === "right" ? reveal.width - surface.width : 0)
            y: surface.contentInset + (surface.edge === "bottom" ? reveal.height - surface.height : 0)
            opacity: Math.min(1, surface.progress * 2)
        }
    }
}

.pragma library

function highlightAlpha(y, screenHeight) {
    return 0.18 - 0.15 * Math.max(0, Math.min(1, y / Math.max(1, screenHeight)));
}

// Keep the attachment edge out of the rim: it is one surface with the bar.
function sheetPath(ctx, w, h, start, end, includeAttachment) {
    ctx.beginPath();
    ctx.moveTo(includeAttachment ? 0 : w, 0);
    if (includeAttachment) ctx.lineTo(w, 0);
    ctx.quadraticCurveTo(w - end, 0, w - end, end);
    ctx.lineTo(w - end, h - end);
    ctx.quadraticCurveTo(w - end, h, w - 2 * end, h);
    ctx.lineTo(2 * start, h);
    ctx.quadraticCurveTo(start, h, start, h - start);
    ctx.lineTo(start, start);
    ctx.quadraticCurveTo(start, 0, 0, 0);
    if (includeAttachment) ctx.closePath();
}

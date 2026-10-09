.pragma library

function highlightAlpha(y, screenHeight) {
    return 0.14 - 0.115 * Math.max(0, Math.min(1, y / Math.max(1, screenHeight)));
}

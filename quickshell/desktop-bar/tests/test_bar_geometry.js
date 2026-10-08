const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');
const context = {};
vm.createContext(context);
vm.runInContext(fs.readFileSync(path.join(__dirname, '../BarGeometry.js'), 'utf8').replace(/^\.pragma library\s*/, ''), context);

// Bottom bars must add their window offset before interpreting an upward drag.
const fromBottom = context.screenPoint({x: 1280, y: -1020}, 'bottom', 2560, 1080, 2560, 30);
assert.equal(context.nearestEdge(fromBottom, 2560, 1080), 'top');
const fromTop = context.screenPoint({x: 1280, y: 1040}, 'top', 2560, 1080, 2560, 30);
assert.equal(context.nearestEdge(fromTop, 2560, 1080), 'bottom');
const fromRight = context.screenPoint({x: -2460, y: 540}, 'right', 2560, 1080, 60, 1080);
assert.equal(context.nearestEdge(fromRight, 2560, 1080), 'left');
assert.equal(context.nearestEdge({x: 2500, y: 540}, 2560, 1080), 'right');
assert.equal(context.nearestEdge({x: 1280, y: 150}, 2560, 1080), 'top');
assert.equal(context.popupX('top', 24, 400, 'right'), -376);
assert.equal(context.popupX('top', 24, 400, 'left'), 0);
assert.equal(context.popupY('top', 24, 400), 32);
assert.equal(context.popupY('bottom', 24, 400), -408);
assert.equal(context.popupX('left', 28, 400, 'right'), 36);
assert.equal(context.popupX('right', 28, 400, 'right'), -408);
console.log('Bar geometry checks passed');

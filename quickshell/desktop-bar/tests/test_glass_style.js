const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const style = {};
vm.createContext(style);
vm.runInContext(fs.readFileSync(`${__dirname}/../GlassStyle.js`, 'utf8').replace('.pragma library', ''), style);
assert.equal(style.highlightAlpha(0, 1080), 0.18);
assert.ok(Math.abs(style.highlightAlpha(1080, 1080) - 0.03) < 1e-10);
for (const includeAttachment of [true, false]) {
    const calls = [];
    const ctx = Object.fromEntries(['beginPath', 'moveTo', 'lineTo', 'quadraticCurveTo', 'closePath']
        .map(name => [name, (...args) => calls.push([name, ...args])]));
    style.sheetPath(ctx, 468, 740, 14, 0, includeAttachment);
    assert.equal(calls.some(call => call[0] === 'closePath'), includeAttachment);
    assert.equal(calls.some(call => call[0] === 'lineTo' && call[1] === 468 && call[2] === 0), includeAttachment);
}
console.log('Liquid glass: highlight range and seamless attachment rim passed');

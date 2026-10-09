const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const source = fs.readFileSync(`${__dirname}/../DockPanel.qml`, 'utf8');
const x = source.match(/\n    x: \{([\s\S]*?)\n    \}/)[1];
const y = source.match(/\n    y: \{([\s\S]*?)\n    \}/)[1];
for (const edge of ['top', 'bottom', 'left', 'right']) {
    for (const alignment of ['left', 'center', 'right']) {
        const vertical = edge === 'left' || edge === 'right';
        const context = {
            parent: {width: 1920, height: 1080}, width: 468, height: 740,
            attachmentTarget: {}, attachmentEdge: edge, alignment,
            strip: {x: edge === 'right' ? 1878 : 0,
                y: edge === 'bottom' ? 1050 : 0,
                width: vertical ? 42 : 1920, height: vertical ? 1080 : 30}
        };
        const position = code => vm.runInNewContext(`(function(){${code}})()`, context);
        const along = alignment === 'left' ? 0 : alignment === 'right' ? 1 : 0.5;
        assert.equal(position(x), vertical ? (edge === 'left' ? 42 : 1410) : (1920 - 468) * along);
        assert.equal(position(y), vertical ? (1080 - 740) * along : (edge === 'top' ? 30 : 310));
    }
}
console.log('Dock positioning: all four edges and three alignments passed');

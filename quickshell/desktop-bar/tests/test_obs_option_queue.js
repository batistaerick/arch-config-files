const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

const source = fs.readFileSync(path.join(__dirname, '../ObsMenu.qml'), 'utf8');
const functions = source.slice(source.indexOf('    function saveOption('), source.indexOf('    onVisibleChanged:'));
const context = {
    busy: false,
    captureOptions: {audio: {enabled: true}, mic: {enabled: true}},
    pendingOptionChanges: {},
    optionWriter: {running: false},
    Quickshell: {env: () => '/home/test'}
};
vm.createContext(context);
vm.runInContext(functions, context);
context.saveOption('audio', false);
assert.equal(context.captureOptions.audio.enabled, false);
assert.deepEqual(Array.from(context.optionWriter.command).slice(-2), ['audio', 'false']);
context.saveOption('mic', false);
context.saveOption('mic', true);
assert.equal(context.captureOptions.mic.enabled, true);
assert.deepEqual(Array.from(context.optionWriter.command).slice(-2), ['audio', 'false']);
context.optionWriter.running = false;
context.writeNextOption();
assert.deepEqual(Array.from(context.optionWriter.command).slice(-2), ['mic', 'true']);
assert.equal(Object.keys(context.pendingOptionChanges).length, 0);
console.log('OBS option queue tests passed');

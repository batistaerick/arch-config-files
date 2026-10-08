const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

const source = fs.readFileSync(path.join(__dirname, '../ObsMenu.qml'), 'utf8');
const functions = source.slice(source.indexOf('    function run('), source.indexOf('    onVisibleChanged:'));
const context = {
    busy: false,
    captureOptions: {audio: {enabled: true}, mic: {enabled: true}},
    pendingOptionChanges: {},
    optionWriter: {running: false},
    actionProcess: {running: false},
    query: {running: true},
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
context.run('record');
assert.equal(context.pendingAction, 'record');
assert.equal(context.actionProcess.running, false);
assert.equal(context.query.running, false);
context.optionWriter.running = false;
context.beginAction();
assert.equal(context.actionProcess.running, true);
assert.equal(context.actionProcess.command.at(-1), 'prepare');
assert.ok(source.includes('readonly property bool controlsReady: obsState.ready && !busy'));
console.log('OBS option queue tests passed');

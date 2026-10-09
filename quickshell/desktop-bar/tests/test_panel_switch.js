const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const source = fs.readFileSync(`${__dirname}/../shell.qml`, 'utf8');
const context = {pendingPanel: null, dockPanels: []};
vm.createContext(context);
for (const name of ['closePanels', 'showPanel', 'togglePanel', 'finishPanelSwitch']) {
    const match = source.match(new RegExp(`function ${name}\\([^)]*\\) \\{[\\s\\S]*?\\n                \\}`));
    assert.ok(match, name);
    vm.runInContext(match[0], context);
}
const first = {opened: true, visible: true};
const second = {opened: false, visible: false};
const third = {opened: false, visible: false};
context.dockPanels = [first, second, third];
context.showPanel(second);
assert.equal(first.opened, false);
assert.equal(second.opened, false); // First is still animating closed.
context.finishPanelSwitch();
assert.equal(second.opened, false);
context.showPanel(third); // Latest click wins during the close animation.
first.visible = false;
context.finishPanelSwitch();
assert.equal(third.opened, true);
assert.equal(second.opened, false);
third.visible = true;
context.togglePanel(third);
assert.equal(third.opened, false);
context.togglePanel(second);
context.togglePanel(second); // Clicking a queued panel again cancels it.
third.visible = false;
context.finishPanelSwitch();
assert.equal(second.opened, false);
assert.equal(context.pendingPanel, null);
console.log('Panel switching: waits for dismissal, latest click wins, cancellation passed');

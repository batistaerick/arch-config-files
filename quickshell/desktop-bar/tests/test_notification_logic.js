const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');
const logic = {};
vm.createContext(logic);
vm.runInContext(fs.readFileSync(path.join(__dirname, '../NotificationLogic.js'), 'utf8').replace(/^\.pragma library\s*/, ''), logic);
assert.equal(logic.ignored('Kitty'), true);
assert.equal(logic.ignored('Terminal'), true);
assert.equal(logic.ignored('Slack'), false);
assert.equal(logic.popupDuration({urgency: 2, expireTimeout: 5}), 0);
assert.equal(logic.popupDuration({urgency: 1, expireTimeout: 0}), 0);
assert.equal(logic.popupDuration({urgency: 1, expireTimeout: 2000}), 2000);
assert.equal(logic.popupDuration({urgency: 1, expireTimeout: -1}), 6500);
const notices = [
    {id: 1, appName: 'Mail'}, {id: 2, appName: 'Chat'},
    {id: 3, appName: 'Mail'}, {id: 4, appName: 'Chat', transient: true},
];
const groups = JSON.parse(JSON.stringify(logic.grouped(notices, {1: 100, 2: 300, 3: 200, 4: 400})));
assert.deepEqual(groups.map(g => g.name), ['Chat', 'Mail']);
assert.deepEqual(groups[1].notifications.map(n => n.id), [3, 1]);
assert.equal(groups.flatMap(g => g.notifications).length, 3);
assert.equal(notices[0].id, 1);
console.log('Notification policy checks passed');

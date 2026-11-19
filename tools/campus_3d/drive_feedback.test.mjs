import test from 'node:test';
import assert from 'node:assert/strict';
import {raceFeedback} from './drive_feedback.mjs';
test('start and checkpoint feedback fire on transitions without repeating each frame',()=>{
 assert.equal(raceFeedback('countdown','running',0,0),'GO!');
 assert.equal(raceFeedback('running','running',0,1),'CHECKPOINT!');
 assert.equal(raceFeedback('running','running',1,1),null);
 assert.equal(raceFeedback('running','invalid',1,2),null);
 assert.equal(raceFeedback('running','finished',1,2),null);
});
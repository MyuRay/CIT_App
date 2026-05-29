const {describe, it} = require('node:test');
const assert = require('node:assert/strict');
const {
  calendarKeyForDate,
  timetableTypeForCalendarKey,
  pickFromTimeList,
  buildStaticSnapshot,
} = require('../static_timetable');

describe('static_timetable', () => {
  it('calendarKeyForDate distinguishes weekday and weekend', () => {
    const tue = new Date(2026, 4, 26, 10, 0);
    const sun = new Date(2026, 4, 24, 10, 0);
    assert.equal(calendarKeyForDate(tue), 'weekday');
    assert.equal(calendarKeyForDate(sun), 'weekend');
    assert.equal(timetableTypeForCalendarKey('weekday'), 'weekday');
    assert.equal(timetableTypeForCalendarKey('weekend'), 'holiday');
  });

  it('pickFromTimeList returns next two departures', () => {
    const now = new Date(2026, 4, 26, 8, 45, 0);
    const times = ['08:40', '08:49', '08:57', '09:04'];
    const deps = pickFromTimeList(times, now, 2);
    assert.equal(deps.length, 2);
    assert.equal(deps[0].getHours(), 8);
    assert.equal(deps[0].getMinutes(), 49);
    assert.equal(deps[1].getMinutes(), 57);
  });

  it('buildStaticSnapshot includes tokyo weekday departures', () => {
    const now = new Date(2026, 4, 26, 8, 45, 0);
    const snap = buildStaticSnapshot('tsudanuma', now);
    assert.equal(snap.stationName, '津田沼');
    assert.equal(snap._meta.mode, 'static');
    assert.ok(snap.directions.length >= 1);
    const tokyo = snap.directions.find((d) => d.directionKey === 'tokyo');
    assert.ok(tokyo);
    assert.ok(tokyo.nextDepartureAt);
    assert.ok(tokyo.secondDepartureAt);
    assert.equal(tokyo.lineLabel, '中央・総武線各駅停車');
    assert.equal(tokyo.directionLabel, '西船橋・両国方面 (西行)');
  });

  it('buildStaticSnapshot falls back to weekday on weekend when weekend list empty', () => {
    const sun = new Date(2026, 4, 24, 8, 45, 0);
    const snap = buildStaticSnapshot('tsudanuma', sun);
    const tokyo = snap.directions.find((d) => d.directionKey === 'tokyo');
    assert.ok(tokyo);
    assert.ok(tokyo.nextDepartureAt);
    assert.ok(tokyo.secondDepartureAt);
  });

  it('buildStaticSnapshot omits directions with no timetable data', () => {
    const now = new Date(2026, 4, 26, 8, 45, 0);
    const snap = buildStaticSnapshot('tsudanuma', now);
    const chiba = snap.directions.find((d) => d.directionKey === 'chiba');
    assert.equal(chiba, undefined);
  });
});

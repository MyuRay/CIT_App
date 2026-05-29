const {describe, it} = require('node:test');
const assert = require('node:assert/strict');
const {
  calendarForDate,
  departureDateFromHHMM,
  pickUpcomingDepartures,
  pickFromTimetableEntries,
  timetableTypeFromCalendar,
} = require('../odpt_client');

describe('odpt_client', () => {
  it('calendarForDate returns weekday on Tuesday', () => {
    const tue = new Date(2026, 4, 26, 10, 0); // 2026-05-26 Tue
    assert.equal(calendarForDate(tue), 'odpt.Calendar:Weekday');
  });

  it('calendarForDate returns SaturdayHoliday on Sunday', () => {
    const sun = new Date(2026, 4, 24, 10, 0);
    assert.equal(calendarForDate(sun), 'odpt.Calendar:SaturdayHoliday');
  });

  it('departureDateFromHHMM picks next occurrence today or tomorrow', () => {
    const now = new Date(2026, 4, 26, 10, 30);
    const later = departureDateFromHHMM('10:45', now);
    assert.ok(later);
    assert.equal(later.getHours(), 10);
    assert.equal(later.getMinutes(), 45);

    const tomorrow = departureDateFromHHMM('09:00', now);
    assert.ok(tomorrow);
    assert.equal(tomorrow.getDate(), 27);
  });

  it('pickUpcomingDepartures returns sorted future departures', () => {
    const now = new Date(2026, 4, 26, 10, 0);
    const objects = [
      {'odpt:departureTime': '10:05'},
      {'odpt:departureTime': '10:20'},
      {'odpt:departureTime': '09:50'},
      {'odpt:departureTime': '10:20'},
    ];
    const deps = pickUpcomingDepartures(objects, now, 2);
    assert.equal(deps.length, 2);
    assert.ok(deps[0] < deps[1]);
  });

  it('pickFromTimetableEntries selects calendar block', () => {
    const now = new Date(2026, 4, 26, 10, 0);
    const entries = [
      {
        'odpt:calendar': 'odpt.Calendar:Weekday',
        'odpt:stationTimetableObject': [
          {'odpt:departureTime': '10:15'},
        ],
      },
    ];
    const deps = pickFromTimetableEntries(
      entries,
      'odpt.Calendar:Weekday',
      now,
      1,
    );
    assert.equal(deps.length, 1);
    assert.equal(timetableTypeFromCalendar('odpt.Calendar:Weekday'), 'weekday');
  });
});

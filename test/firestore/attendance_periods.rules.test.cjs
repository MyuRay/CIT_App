const {readFileSync} = require('node:fs');
const {test, before, after, beforeEach} = require('node:test');
const {initializeTestEnvironment, assertFails, assertSucceeds} = require('@firebase/rules-unit-testing');
const {doc, setDoc, updateDoc, serverTimestamp, Timestamp} = require('firebase/firestore');

let env;
const client = (verified = true) => env.authenticatedContext('owner', {
  email: 'owner@chibatech.ac.jp', email_verified: verified,
}).firestore();
const record = (startPeriod, duration = 1, extra = {}) => ({
  userId: 'owner', scheduleId: 'week', classId: 'lesson', subjectName: '演習',
  weekdayKey: 'monday', startPeriod, duration, status: 'present',
  attendanceDate: Timestamp.fromDate(new Date('2026-10-19T00:00:00+09:00')),
  recordedAt: serverTimestamp(), ...extra,
});

before(async () => {
  env = await initializeTestEnvironment({projectId: 'demo-cit-periods', firestore: {
    host: '127.0.0.1', port: 8089, rules: readFileSync('firestore.rules', 'utf8'),
  }});
});
after(async () => { if (env) await env.cleanup(); });
beforeEach(async () => { await env.clearFirestore(); });

test('existing and extended periods can be recorded and updated', async () => {
  const db = client();
  for (const period of [1, 10, 11, 12, 13, 14, 15]) {
    const ref = doc(db, 'attendance_records', `period-${period}`);
    await assertSucceeds(setDoc(ref, record(period)));
    await assertSucceeds(updateDoc(ref, {status: 'late'}));
  }
  await assertSucceeds(setDoc(doc(db, 'attendance_records', 'continuous'), record(11, 5)));
});

test('invalid and crossing-midnight periods are rejected', async () => {
  const db = client();
  for (const [start, duration] of [[0, 1], [16, 1], [11, 0], [11, 6], [15, 2], [1.5, 1]]) {
    await assertFails(setDoc(doc(db, 'attendance_records', `${start}-${duration}`), record(start, duration)));
  }
});

test('extended attendance retains identity and verification requirements', async () => {
  await assertFails(setDoc(doc(client(false), 'attendance_records', 'unverified'), record(11)));
  await assertFails(setDoc(doc(client(), 'attendance_records', 'foreign'), record(11, 1, {userId: 'other'})));
  await assertFails(setDoc(doc(env.unauthenticatedContext().firestore(), 'attendance_records', 'anonymous'), record(11)));
});

test('expanded timetable rows can be saved in both supported slot formats', async () => {
  const db = client();
  const timeSlots = Array.from({length: 15}, (_, index) => ({
    period: index + 1, startTime: `${index + 9}:00`, endTime: `${index + 10}:00`,
  }));
  for (const slots of [timeSlots, Object.fromEntries(timeSlots.map(slot => [slot.period, slot]))]) {
    const ref = doc(db, 'schedules', Array.isArray(slots) ? 'list' : 'map');
    await assertSucceeds(setDoc(ref, {
      id: ref.id, userId: 'owner', semester: '2026年度後期',
      timetable: {monday: {'11': null, '15': null}}, timeSlots: slots,
      createdAt: serverTimestamp(), updatedAt: serverTimestamp(),
    }));
    await assertSucceeds(updateDoc(ref, {'timetable.saturday.15': null}));
  }
});

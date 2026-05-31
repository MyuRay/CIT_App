const axios = require('axios');
const {getOdptCampusConfig} = require('./train_odpt_config');

const ODPT_API_BASE = 'https://api.odpt.org/api/v4';
const REQUEST_TIMEOUT_MS = 30_000;

/**
 * @param {string} consumerKey
 * @param {string} resource e.g. odpt:StationTimetable
 * @param {Record<string, string>} params
 */
async function odptGet(consumerKey, resource, params = {}) {
  const url = `${ODPT_API_BASE}/${resource}`;
  const res = await axios.get(url, {
    timeout: REQUEST_TIMEOUT_MS,
    params: {
      'acl:consumerKey': consumerKey,
      ...params,
    },
  });
  const data = res.data;
  if (!Array.isArray(data)) {
    return [];
  }
  return data;
}

/**
 * 今日のカレンダー種別（ODPT の odpt:calendar に合わせる）
 * @param {Date} now
 * @returns {'odpt.Calendar:Weekday' | 'odpt.Calendar:SaturdayHoliday'}
 */
function calendarForDate(now) {
  const day = now.getDay();
  if (day === 0 || day === 6) {
    return 'odpt.Calendar:SaturdayHoliday';
  }
  return 'odpt.Calendar:Weekday';
}

/**
 * @param {'weekday'|'saturday'|'holiday'|'unknown'} timetableType
 */
function timetableTypeFromCalendar(calendar) {
  if (calendar === 'odpt.Calendar:Weekday') return 'weekday';
  if (calendar === 'odpt.Calendar:SaturdayHoliday') return 'saturday';
  return 'unknown';
}

/**
 * "HH:mm" を今日（必要なら翌日）の Date に
 * @param {string} hhmm
 * @param {Date} now
 */
function departureDateFromHHMM(hhmm, now) {
  const m = /^(\d{1,2}):(\d{2})$/.exec(String(hhmm || '').trim());
  if (!m) return null;
  const h = Number(m[1]);
  const min = Number(m[2]);
  if (Number.isNaN(h) || Number.isNaN(min)) return null;

  let d = new Date(
    now.getFullYear(),
    now.getMonth(),
    now.getDate(),
    h,
    min,
    0,
    0,
  );
  if (d <= now) {
    d = new Date(d.getTime() + 24 * 60 * 60 * 1000);
  }
  return d;
}

/**
 * @param {object[]} objects odpt:stationTimetableObject
 * @param {Date} now
 * @param {number} count
 * @returns {Date[]}
 */
function pickUpcomingDepartures(objects, now, count = 2) {
  const upcoming = [];
  for (const obj of objects || []) {
    const dep = departureDateFromHHMM(obj['odpt:departureTime'], now);
    if (!dep || dep <= now) continue;
    upcoming.push(dep);
  }
  upcoming.sort((a, b) => a.getTime() - b.getTime());

  const unique = [];
  const seen = new Set();
  for (const d of upcoming) {
    const key = d.getTime();
    if (seen.has(key)) continue;
    seen.add(key);
    unique.push(d);
    if (unique.length >= count) break;
  }
  return unique;
}

/**
 * @param {object[]} entries StationTimetable の配列
 * @param {string} calendar odpt:Calendar:...
 * @param {Date} now
 * @param {number} count
 */
function pickFromTimetableEntries(entries, calendar, now, count = 2) {
  const block = entries.find((e) => e['odpt:calendar'] === calendar);
  if (!block) return [];
  return pickUpcomingDepartures(block['odpt:stationTimetableObject'], now, count);
}

function toIso8601Local(d) {
  const pad = (n) => String(n).padStart(2, '0');
  const y = d.getFullYear();
  const mo = pad(d.getMonth() + 1);
  const day = pad(d.getDate());
  const h = pad(d.getHours());
  const min = pad(d.getMinutes());
  const s = pad(d.getSeconds());
  const offMin = -d.getTimezoneOffset();
  const sign = offMin >= 0 ? '+' : '-';
  const abs = Math.abs(offMin);
  const oh = pad(Math.floor(abs / 60));
  const om = pad(abs % 60);
  return `${y}-${mo}-${day}T${h}:${min}:${s}${sign}${oh}:${om}`;
}

/**
 * 1方向分の時刻表を取得して次発2本
 * @param {string} consumerKey
 * @param {import('./train_odpt_config').OdptDirectionConfig & {station: string, railway: string}} query
 * @param {Date} now
 */
async function fetchDirectionDepartures(consumerKey, query, now) {
  const entries = await odptGet(consumerKey, 'odpt:StationTimetable', {
    'odpt:station': query.station,
    'odpt:railway': query.railway,
    'odpt:railDirection': query.railDirection,
  });

  const calendar = calendarForDate(now);
  let deps = pickFromTimetableEntries(entries, calendar, now, 2);

  // 土日祝ブロックが無い場合は平日を試す
  if (deps.length === 0 && calendar === 'odpt.Calendar:SaturdayHoliday') {
    deps = pickFromTimetableEntries(entries, 'odpt.Calendar:Weekday', now, 2);
  }

  return {entries, departures: deps, calendar};
}

/**
 * @param {string} campus
 * @param {string} consumerKey
 * @param {Date} [now]
 */
async function buildOdptSnapshot(campus, consumerKey, now = new Date()) {
  const cfg = getOdptCampusConfig(campus);
  const calendar = calendarForDate(now);
  const timetableType = timetableTypeFromCalendar(calendar);

  /** @type {object[]} */
  const directions = [];
  let timetableEntryCount = 0;
  let hasAnyDeparture = false;

  for (const dir of cfg.directions) {
    const {entries, departures} = await fetchDirectionDepartures(
      consumerKey,
      {
        station: cfg.station,
        railway: cfg.railway,
        railDirection: dir.railDirection,
        ...dir,
      },
      now,
    );
    timetableEntryCount += entries.length;
    if (departures.length > 0) hasAnyDeparture = true;

    directions.push({
      directionKey: dir.directionKey,
      directionLabel: dir.directionLabel,
      ...(departures[0] ? {nextDepartureAt: toIso8601Local(departures[0])} : {}),
      ...(departures[1] ? {secondDepartureAt: toIso8601Local(departures[1])} : {}),
      timetableType,
      boardingPlatform: dir.boardingPlatform ?? null,
    });
  }

  return {
    body: {
      stationName: cfg.stationName,
      updatedAt: toIso8601Local(now),
      source: '公共交通オープンデータセンター（JR東日本）',
      delay: {status: 'normal', message: null},
      directions,
      _meta: {
        mode: 'odpt',
        campus,
        operator: cfg.operator,
        timetableBlocks: timetableEntryCount,
        note: hasAnyDeparture
          ? null
          : 'ODPTから時刻表0件。JR東日本の時刻表データへのアクセス権限を確認してください。',
      },
    },
    hasAnyDeparture,
    timetableEntryCount,
  };
}

module.exports = {
  ODPT_API_BASE,
  odptGet,
  calendarForDate,
  timetableTypeFromCalendar,
  departureDateFromHHMM,
  pickUpcomingDepartures,
  pickFromTimetableEntries,
  toIso8601Local,
  fetchDirectionDepartures,
  buildOdptSnapshot,
};

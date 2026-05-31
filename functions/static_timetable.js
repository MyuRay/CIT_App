const fs = require('fs');
const path = require('path');
const {
  departureDateFromHHMM,
  pickUpcomingDepartures,
  toIso8601Local,
} = require('./odpt_client');

const DATA_DIR = path.join(__dirname, 'data', 'train');

/** @type {Map<string, object>} */
const masterCache = new Map();

/**
 * 静的マスタのカレンダーキー（v1: 土日祝は weekend。データ無しは空配列）
 * @param {Date} now
 * @returns {'weekday'|'weekend'}
 */
function calendarKeyForDate(now) {
  const day = now.getDay();
  if (day === 0 || day === 6) return 'weekend';
  return 'weekday';
}

/**
 * @param {'weekday'|'weekend'} calendarKey
 * @returns {'weekday'|'saturday'|'holiday'}
 */
function timetableTypeForCalendarKey(calendarKey) {
  if (calendarKey === 'weekday') return 'weekday';
  return 'holiday';
}

/**
 * @param {string} campus
 * @returns {object}
 */
function loadCampusMaster(campus) {
  const key = campus === 'narashino' ? 'narashino' : 'tsudanuma';
  const cached = masterCache.get(key);
  if (cached) return cached;

  const filePath = path.join(DATA_DIR, `${key}.json`);
  if (!fs.existsSync(filePath)) {
    const err = new Error(`Static timetable file not found: ${filePath}`);
    err.code = 'STATIC_TIMETABLE_NOT_FOUND';
    throw err;
  }
  const raw = fs.readFileSync(filePath, 'utf8');
  const data = JSON.parse(raw);
  masterCache.set(key, data);
  return data;
}

/**
 * @param {string[]} times HH:mm
 * @param {Date} now
 * @param {number} count
 * @returns {Date[]}
 */
function pickFromTimeList(times, now, count = 2) {
  const objects = (times || []).map((t) => ({'odpt:departureTime': t}));
  return pickUpcomingDepartures(objects, now, count);
}

/**
 * @param {string} campus
 * @param {Date} [now]
 * @returns {object}
 */
function buildStaticSnapshot(campus, now = new Date()) {
  const campusKey = campus === 'narashino' ? 'narashino' : 'tsudanuma';
  const master = loadCampusMaster(campusKey);
  const calendarKey = calendarKeyForDate(now);
  const timetableType = timetableTypeForCalendarKey(calendarKey);

  const directions = [];
  const dirMaster = master.directions || {};

  for (const [directionKey, cfg] of Object.entries(dirMaster)) {
    let times = (cfg[calendarKey] || []).slice();
    // 土日データ未投入時は平日で代用（暫定）
    if (times.length === 0 && calendarKey === 'weekend') {
      times = (cfg.weekday || []).slice();
    }
    if (times.length === 0) continue;

    const departures = pickFromTimeList(times, now, 2);
    if (!departures[0]) continue;

    directions.push({
      directionKey,
      directionLabel: cfg.directionLabel || directionKey,
      ...(cfg.lineLabel ? {lineLabel: cfg.lineLabel} : {}),
      ...(departures[0]
        ? {nextDepartureAt: toIso8601Local(departures[0])}
        : {}),
      ...(departures[1]
        ? {secondDepartureAt: toIso8601Local(departures[1])}
        : {}),
      timetableType,
      boardingPlatform: cfg.boardingPlatform ?? null,
    });
  }

  const hasAnyDeparture = directions.some((d) => d.nextDepartureAt);

  return {
    stationName: master.stationName || campusKey,
    updatedAt: toIso8601Local(now),
    source: master.source || '静的時刻表',
    delay: {status: 'normal', message: null},
    directions,
    _meta: {
      mode: 'static',
      campus: campusKey,
      calendarKey,
      dataVersion: master.dataVersion || null,
      departureCount: directions.reduce(
        (n, d) => n + (d.nextDepartureAt ? 1 : 0),
        0,
      ),
      note: hasAnyDeparture
        ? null
        : 'このカレンダー・方向の時刻表データが未登録です。',
    },
  };
}

module.exports = {
  DATA_DIR,
  calendarKeyForDate,
  timetableTypeForCalendarKey,
  loadCampusMaster,
  pickFromTimeList,
  buildStaticSnapshot,
};

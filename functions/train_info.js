const {onRequest} = require('firebase-functions/v2/https');
const {buildOdptSnapshot} = require('./odpt_client');
const {buildStaticSnapshot} = require('./static_timetable');

const REGION = (
  process.env.FUNCTIONS_REGION ||
  process.env.FUNCTION_REGION ||
  'us-central1'
);

const CACHE_TTL_MS = 60_000;
/** @type {Map<string, {expiresAt: number, body: object}>} */
const cache = new Map();

const CAMPUS_CONFIG = {
  tsudanuma: {
    stationName: '津田沼',
    source: 'モックデータ（ODPT接続前・津田沼）',
    directions: [
      {directionKey: 'tokyo', directionLabel: '東京方面', slotOffsetMin: 3, intervalMin: 5, boardingPlatform: '1・2番ホーム'},
      {directionKey: 'chiba', directionLabel: '千葉方面', slotOffsetMin: 1, intervalMin: 7, boardingPlatform: '3・4番ホーム'},
    ],
  },
  narashino: {
    stationName: '新習志野',
    source: 'モックデータ（ODPT接続前・新習志野）',
    directions: [
      {directionKey: 'kaihimmakuhari', directionLabel: '海浜幕張方面', slotOffsetMin: 2, intervalMin: 6, boardingPlatform: '1・2番ホーム'},
      {directionKey: 'tokyo', directionLabel: '東京・舞浜方面', slotOffsetMin: 4, intervalMin: 8, boardingPlatform: '3・4番ホーム'},
    ],
  },
};

function setCors(res) {
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type');
}

function timetableTypeForDate(d) {
  const day = d.getDay();
  if (day === 6) return 'saturday';
  if (day === 0) return 'holiday';
  return 'weekday';
}

/**
 * 現在時刻より後の発車時刻を interval 分刻みで生成（モック用）
 * @param {Date} now
 * @param {number} slotOffsetMin 方向ごとの位相ずれ
 * @param {number} intervalMin
 * @param {number} count
 */
function nextDepartures(now, slotOffsetMin, intervalMin, count) {
  const base = new Date(now);
  base.setSeconds(0, 0);
  let cursor = new Date(base.getTime() + slotOffsetMin * 60_000);
  while (cursor <= now) {
    cursor = new Date(cursor.getTime() + intervalMin * 60_000);
  }
  const out = [];
  for (let i = 0; i < count; i++) {
    out.push(new Date(cursor));
    cursor = new Date(cursor.getTime() + intervalMin * 60_000);
  }
  return out;
}

function toIso8601Jst(d) {
  const pad = (n) => String(n).padStart(2, '0');
  const y = d.getFullYear();
  const m = pad(d.getMonth() + 1);
  const day = pad(d.getDate());
  const h = pad(d.getHours());
  const min = pad(d.getMinutes());
  const s = pad(d.getSeconds());
  const offMin = -d.getTimezoneOffset();
  const sign = offMin >= 0 ? '+' : '-';
  const abs = Math.abs(offMin);
  const oh = pad(Math.floor(abs / 60));
  const om = pad(abs % 60);
  return `${y}-${m}-${day}T${h}:${min}:${s}${sign}${oh}:${om}`;
}

/**
 * @param {string} campus
 * @returns {object}
 */
function buildMockSnapshot(campus) {
  const key = campus === 'narashino' ? 'narashino' : 'tsudanuma';
  const cfg = CAMPUS_CONFIG[key];
  const now = new Date();
  const timetableType = timetableTypeForDate(now);

  const directions = cfg.directions.map((dir) => {
    const [next, second] = nextDepartures(
      now,
      dir.slotOffsetMin,
      dir.intervalMin,
      2,
    );
    return {
      directionKey: dir.directionKey,
      directionLabel: dir.directionLabel,
      nextDepartureAt: toIso8601Jst(next),
      secondDepartureAt: toIso8601Jst(second),
      timetableType,
      boardingPlatform: dir.boardingPlatform ?? null,
    };
  });

  return {
    stationName: cfg.stationName,
    updatedAt: toIso8601Jst(now),
    source: cfg.source,
    delay: {status: 'normal', message: null},
    directions,
    _meta: {mode: 'mock', campus: key},
  };
}

function getCachedMock(campus) {
  const key = `mock:${campus}`;
  const hit = cache.get(key);
  const now = Date.now();
  if (hit && hit.expiresAt > now) {
    return hit.body;
  }
  const body = buildMockSnapshot(campus);
  cache.set(key, {expiresAt: now + CACHE_TTL_MS, body});
  return body;
}

function getCachedStatic(campus) {
  const key = `static:${campus}`;
  const hit = cache.get(key);
  const now = Date.now();
  if (hit && hit.expiresAt > now) {
    return hit.body;
  }
  const body = buildStaticSnapshot(campus);
  cache.set(key, {expiresAt: now + CACHE_TTL_MS, body});
  return body;
}

/**
 * ODPT からスナップショット取得（A: 時刻表のみ、遅延は後回し）
 * @param {string} campus
 * @returns {Promise<object>}
 */
async function fetchOdptSnapshot(campus) {
  const key = (process.env.ODPT_ACL_CONSUMER_KEY || '').trim();
  if (!key) {
    const err = new Error('ODPT_ACL_CONSUMER_KEY is not set');
    err.code = 'ODPT_NOT_CONFIGURED';
    throw err;
  }

  const {body, hasAnyDeparture, timetableEntryCount} = await buildOdptSnapshot(
    campus,
    key,
  );

  if (!hasAnyDeparture) {
    const allowFallback = (process.env.TRAIN_INFO_ODPT_FALLBACK_MOCK || 'true')
      .toLowerCase() !== 'false';
    if (allowFallback) {
      console.warn(
        `ODPT timetable empty for campus=${campus} (blocks=${timetableEntryCount}). Falling back to mock.`,
      );
      const mock = buildMockSnapshot(campus);
      return {
        ...mock,
        _meta: {
          ...mock._meta,
          fallback: 'mock',
          fallbackReason:
            'JR東日本の駅時刻表がODPT APIから0件でした。データ利用申請・ライセンスを確認してください。',
          odptTimetableBlocks: timetableEntryCount,
        },
      };
    }
    const err = new Error(
      'ODPT returned no timetable data for this campus. Check JR-East dataset access on developer.odpt.org',
    );
    err.code = 'ODPT_NO_TIMETABLE';
    throw err;
  }

  return body;
}

function resolveMode() {
  return (process.env.TRAIN_INFO_MODE || 'mock').toLowerCase();
}

function createTrainInfoHandler() {
  return onRequest({region: REGION}, async (req, res) => {
    setCors(res);
    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }
    if (req.method !== 'GET') {
      res.status(405).json({error: 'Method not allowed'});
      return;
    }

    const campus = String(req.query.campus || 'tsudanuma');
    if (campus !== 'tsudanuma' && campus !== 'narashino') {
      res.status(400).json({error: 'Invalid campus', allowed: ['tsudanuma', 'narashino']});
      return;
    }

    try {
      const mode = resolveMode();
      if (mode === 'mock') {
        res.status(200).json(getCachedMock(campus));
        return;
      }

      if (mode === 'odpt') {
        const body = await fetchOdptSnapshot(campus);
        res.status(200).json(body);
        return;
      }

      if (mode === 'static') {
        res.status(200).json(getCachedStatic(campus));
        return;
      }

      res.status(500).json({error: 'Unknown TRAIN_INFO_MODE', mode});
    } catch (e) {
      console.error('trainInfo error:', e);
      if (e.code === 'ODPT_NOT_CONFIGURED') {
        res.status(503).json({
          error: 'ODPT is not configured',
          hint: 'Set ODPT_ACL_CONSUMER_KEY and implement fetchOdptSnapshot',
        });
        return;
      }
      if (e.code === 'ODPT_NO_TIMETABLE') {
        res.status(503).json({
          error: 'ODPT timetable unavailable',
          hint: e.message,
        });
        return;
      }
      if (e.code === 'STATIC_TIMETABLE_NOT_FOUND') {
        res.status(503).json({
          error: 'Static timetable not found',
          hint: e.message,
        });
        return;
      }
      res.status(500).json({error: e.message || String(e)});
    }
  });
}

module.exports = {
  createTrainInfoHandler,
  buildMockSnapshot,
  getCachedStatic,
  nextDepartures,
};

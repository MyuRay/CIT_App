/**
 * キャンパス → ODPT クエリ設定（Step2-A）。
 *
 * 駅・路線 URI は ODPT API で確認済み（2026-05）。
 * railDirection は JR 東日本向けに Inbound / Outbound を使用。
 * 方面ラベル（東京/千葉 等）はアプリ表示用。実データ取得後に必要なら入れ替え。
 *
 * 新習志野駅は現キーでは Station API に未掲載のため URI は命名規則ベース。
 * JR東の時刻表ライセンスが有効になればそのまま使える想定。
 */

/** @typedef {object} OdptDirectionConfig
 * @property {string} directionKey
 * @property {string} directionLabel
 * @property {string} railDirection
 * @property {string} boardingPlatform
 */

/** @typedef {object} OdptCampusConfig
 * @property {string} stationName
 * @property {string} station
 * @property {string} railway
 * @property {string} operator
 * @property {OdptDirectionConfig[]} directions
 */

/** @type {Record<string, OdptCampusConfig>} */
const CAMPUS_ODPT_CONFIG = {
  tsudanuma: {
    stationName: '津田沼',
    station: 'odpt.Station:JR-East.ChuoSobuLocal.Tsudanuma',
    railway: 'odpt.Railway:JR-East.ChuoSobuLocal',
    operator: 'odpt.Operator:JR-East',
    directions: [
      {
        directionKey: 'tokyo',
        directionLabel: '東京方面',
        railDirection: 'odpt.RailDirection:Inbound',
        boardingPlatform: '1・2番ホーム',
      },
      {
        directionKey: 'chiba',
        directionLabel: '千葉方面',
        railDirection: 'odpt.RailDirection:Outbound',
        boardingPlatform: '3・4番ホーム',
      },
    ],
  },
  narashino: {
    stationName: '新習志野',
    station: 'odpt.Station:JR-East.Keiyo.ShinNarashino',
    railway: 'odpt.Railway:JR-East.Keiyo',
    operator: 'odpt.Operator:JR-East',
    directions: [
      {
        directionKey: 'kaihimmakuhari',
        directionLabel: '海浜幕張方面',
        railDirection: 'odpt.RailDirection:Outbound',
        boardingPlatform: '1・2番ホーム',
      },
      {
        directionKey: 'tokyo',
        directionLabel: '東京・舞浜方面',
        railDirection: 'odpt.RailDirection:Inbound',
        boardingPlatform: '3・4番ホーム',
      },
    ],
  },
};

/**
 * @param {string} campus
 * @returns {OdptCampusConfig}
 */
function getOdptCampusConfig(campus) {
  const key = campus === 'narashino' ? 'narashino' : 'tsudanuma';
  return CAMPUS_ODPT_CONFIG[key];
}

module.exports = {
  CAMPUS_ODPT_CONFIG,
  getOdptCampusConfig,
};

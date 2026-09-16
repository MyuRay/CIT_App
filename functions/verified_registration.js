'use strict';
const {HttpsError} = require('firebase-functions/v2/identity');

// Runs BEFORE Firebase persists an account. Never set emailVerified here: that
// flag must be the result of Firebase validating the email link / provider.
function requireVerifiedRegistration(event) {
  const user = event.data;
  if (user?.emailVerified !== true) {
    throw new HttpsError('permission-denied', 'メール内の確認リンクから登録してください。旧版のアプリは更新してください。');
  }
  // Keep the same local-part characters as AppConstants, including +. Compare
  // the whole domain and reject multiple @ signs or trailing newlines.
  const parts = typeof user.email === 'string' ? user.email.split('@') : [];
  if (parts.length !== 2 || !parts[0] || /[^a-z0-9._+-]/i.test(parts[0]) ||
      parts[1].toLowerCase() !== 'chibatech.ac.jp') {
    throw new HttpsError('permission-denied', '新規登録は @chibatech.ac.jp のメールアドレスのみ利用できます。');
  }
}
module.exports = {requireVerifiedRegistration};

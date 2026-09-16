'use strict';

// Inject dependencies so authorization can be tested without credentials or I/O.
function createAdminAuthorizer({auth, firestore}) {
  return async function authorizeAdmin(req, res, method = 'POST') {
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', `${method}, OPTIONS`);
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return false;
    }
    if (req.method !== method) {
      res.set('Allow', `${method}, OPTIONS`);
      res.status(405).json({error: 'method-not-allowed'});
      return false;
    }
    const match = /^Bearer (\S+)$/i.exec(req.get('Authorization') || '');
    if (!match) {
      res.status(401).json({error: 'unauthenticated'});
      return false;
    }
    let token;
    try {
      token = await auth.verifyIdToken(match[1], true);
    } catch (_) {
      res.status(401).json({error: 'unauthenticated'});
      return false;
    }
    const email = String(token.email || '').toLowerCase();
    if (token.email_verified !== true ||
        !/@(?:s\.chibakoudai\.jp|p\.chibakoudai\.jp|chibatech\.ac\.jp)$/.test(email)) {
      res.status(403).json({error: 'permission-denied'});
      return false;
    }
    try {
      const permission = await firestore.collection('admin_permissions').doc(token.uid).get();
      if (!permission.exists || permission.data().isAdmin !== true) {
        res.status(403).json({error: 'permission-denied'});
        return false;
      }
    } catch (_) {
      res.status(503).json({error: 'authorization-unavailable'});
      return false;
    }
    return true;
  };
}

function retiredBulkVerification(_req, res) {
  // Keep a deny-only tombstone so deploying also closes already deployed URLs.
  res.status(410).json({error: 'retired', message: 'Use Firebase Auth email verification.'});
}

module.exports = {createAdminAuthorizer, retiredBulkVerification};

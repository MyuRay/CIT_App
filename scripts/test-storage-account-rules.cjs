// Read-only regression checks against the Firebase Rules test API.
// Uses synthetic identities and mocked Firestore reads; creates no users/data.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const auth = require('firebase-tools/lib/auth');
const {requireAuth} = require('firebase-tools/lib/requireAuth');
const {Client} = require('firebase-tools/lib/apiv2');
(async () => {
  const project = 'cit-app-2de1c';
  await requireAuth({project, nonInteractive: true, ...auth.getGlobalDefaultAccount()});
  const cases = [];
  for (const method of ['get', 'list']) {
    for (const domain of ['s.chibakoudai.jp', 'p.chibakoudai.jp', 'chibatech.ac.jp', 'CHIBATECH.AC.JP', 'example.com', 'chibatech.ac.jp.example.com', null]) {
      for (const deleted of [false, true]) {
        const allowed = domain !== null && !domain.includes('example.com') && !deleted;
        cases.push({expectation: allowed ? 'ALLOW' : 'DENY', request: {
          path: '/b/cit-app-2de1c.firebasestorage.app/o/year_calender' + (method === 'get' ? '/calendar.jpg' : ''),
          method,
          ...(domain ? {auth: {uid: 'calendar-rule-test', token: {email: 'calendar-test@' + domain}}} : {}),
        }, functionMocks: [{function: 'firestore.exists', args: [{anyValue: {}}], result: {value: deleted}}]});
      }
    }
  }
  const client = new Client({urlPrefix: 'https://firebaserules.googleapis.com', apiVersion: 'v1'});
  const result = await client.post('/projects/' + project + ':test', {
    source: {files: [{name: 'storage.rules', content: fs.readFileSync('storage.rules', 'utf8')}]},
    testSuite: {testCases: cases},
  });
  assert.equal(result.body.testResults?.length, cases.length);
  for (const [i, test] of result.body.testResults.entries()) {
    assert.equal(test.state, 'SUCCESS', 'Rule case ' + i + ': ' + JSON.stringify(test.debugMessages));
    // A mock alone does not enforce the production cross-service call budget.
    assert.ok((test.functionCalls || []).filter(x => x.function === 'firestore.exists').length <= 1,
      'Repeated account-state lookup in case ' + i);
  }
  console.log(cases.length + ' Storage authorization cases passed (one account-state lookup maximum).');
})().catch(error => {console.error(error.message); process.exitCode = 1;});

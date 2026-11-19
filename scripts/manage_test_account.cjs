'use strict';

// Explicit, one-account Firebase Authentication administration for local testing.
// Credentials and passwords are never stored by this script.
const fs = require('node:fs');
const readline = require('node:readline');

const PROJECT_ID = 'cit-app-2de1c';
const USAGE = `Usage:
  node scripts/manage_test_account.cjs create --uid <UID> --email <EMAIL>
  node scripts/manage_test_account.cjs verify --uid <UID> --email <EMAIL>

Target project: ${PROJECT_ID}
create: creates a new, email-verified user; prompts for a hidden password.
verify: marks the specified existing user as email-verified after checking email.
Set GOOGLE_APPLICATION_CREDENTIALS to your service account JSON file first.
Firestore documents are not modified.`;

function parseArgs(args) {
  if (args.length === 0 || (args.length === 1 && args[0] === '--help')) return null;
  const [command, ...rest] = args;
  if (!['create', 'verify'].includes(command)) throw new Error('Use create or verify.');
  const options = {command};
  for (let i = 0; i < rest.length; i += 2) {
    const key = rest[i];
    const value = rest[i + 1];
    if (!['--uid', '--email'].includes(key) || !value || value.startsWith('--')) {
      throw new Error('Expected --uid <UID> and --email <EMAIL>.');
    }
    const name = key.slice(2);
    if (options[name] !== undefined) throw new Error(`Duplicate option: ${key}`);
    options[name] = value;
  }
  if (!options.uid || options.uid.length > 128 || options.uid.includes('/')) {
    throw new Error('UID must be 1-128 characters and match the Firestore document ID.');
  }
  if (!options.email || !/^[^\s@]+@(s\.chibakoudai\.jp|p\.chibakoudai\.jp|chibatech\.ac\.jp)$/i.test(options.email)) {
    throw new Error('Use one of the CIT App email domains.');
  }
  options.email = options.email.toLowerCase();
  return options;
}

function readPassword(prompt, input = process.stdin, output = process.stdout) {
  if (!input.isTTY || typeof input.setRawMode !== 'function') {
    return Promise.reject(new Error('Run interactively in PowerShell to enter a password.'));
  }
  return new Promise((resolve, reject) => {
    let password = '';
    const wasRaw = Boolean(input.isRaw);
    readline.emitKeypressEvents(input);
    output.write(prompt);
    input.setRawMode(true);
    input.resume();
    function finish(error) {
      input.removeListener('keypress', onKey);
      input.removeListener('end', onEnd);
      input.setRawMode(wasRaw);
      input.pause();
      output.write('\n');
      if (error) reject(error);
      else resolve(password);
    }
    function onEnd() { finish(new Error('Password input ended.')); }
    function onKey(text, key = {}) {
      if (key.ctrl && key.name === 'c') return finish(new Error('Cancelled.'));
      if (key.name === 'return' || key.name === 'enter') return finish();
      if (key.name === 'backspace') {
        password = Array.from(password).slice(0, -1).join('');
      } else if (!key.ctrl && !key.meta && text && !/[\x00-\x1f\x7f]/.test(text)) {
        password += text;
      }
    }
    input.on('keypress', onKey);
    input.once('end', onEnd);
  });
}

async function execute(options, auth, prompt = readPassword) {
  if (options.command === 'verify') {
    const existing = await auth.getUser(options.uid);
    if (existing.email?.toLowerCase() !== options.email) {
      throw new Error('UID/email mismatch. No changes were made.');
    }
    return auth.updateUser(options.uid, {emailVerified: true});
  }
  const password = await prompt('Password (hidden, at least 6 characters): ');
  if (password.length < 6) throw new Error('Password must be at least 6 characters.');
  const repeated = await prompt('Repeat password (hidden): ');
  if (password !== repeated) throw new Error('Passwords did not match. No user was created.');
  return auth.createUser({
    uid: options.uid,
    email: options.email,
    password,
    displayName: 'Test User',
    emailVerified: true,
    disabled: false,
  });
}

async function main(args) {
  const options = parseArgs(args);
  if (!options) { console.log(USAGE); return; }
  const credentialsPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
  if (!credentialsPath || !fs.existsSync(credentialsPath)) {
    throw new Error('Set GOOGLE_APPLICATION_CREDENTIALS to an existing service account JSON file.');
  }
  if (process.env.FIREBASE_AUTH_EMULATOR_HOST) {
    throw new Error('FIREBASE_AUTH_EMULATOR_HOST is set. Clear it to target the specified Firebase project.');
  }
  const {initializeApp, applicationDefault, deleteApp} = require('firebase-admin/app');
  const {getAuth} = require('firebase-admin/auth');
  const app = initializeApp({credential: applicationDefault(), projectId: PROJECT_ID});
  try {
    console.log(`Project: ${PROJECT_ID}; action: ${options.command}; UID: ${options.uid}; email: ${options.email}`);
    const user = await execute(options, getAuth(app));
    console.log(`Success: UID=${user.uid}; emailVerified=${user.emailVerified}`);
  } finally {
    await deleteApp(app);
  }
}

module.exports = {parseArgs, readPassword, execute};
if (require.main === module) {
  main(process.argv.slice(2)).catch((error) => {
    console.error(error.code ? `Firebase error: ${error.code}` : error.message);
    process.exitCode = 1;
  });
}
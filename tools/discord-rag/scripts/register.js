'use strict';
// Explicit operator action. POST upserts only /ask; it never replaces other commands.
async function main() {
  const {RAG_DISCORD_APPLICATION_ID: app, RAG_DISCORD_GUILD_ID: guild, RAG_DISCORD_BOT_TOKEN: token} = process.env;
  if (!/^\d{17,20}$/.test(app ?? '') || !/^\d{17,20}$/.test(guild ?? '') || !token) throw new Error('Missing Discord settings');
  const response = await fetch(`https://discord.com/api/v10/applications/${app}/guilds/${guild}/commands`, {
    method: 'POST', headers: {Authorization: `Bot ${token}`, 'Content-Type': 'application/json'},
    signal: AbortSignal.timeout(15000), body: JSON.stringify({name: 'ask', type: 1,
      description: 'CIT_Appの開発・運用手順を確認済みの資料から調べる', default_member_permissions: '0',
      options: [{name: 'question', description: '調べたいこと（秘密情報は入力しないでください）', type: 3, required: true, min_length: 2, max_length: 1000}]}),
  });
  if (!response.ok) throw new Error(`Registration failed (${response.status})`);
  console.log('/ask registered. Enable the team role in the server integration settings.');
}
main().catch(() => { console.error('Command registration failed. Check application, guild and Bot credentials.'); process.exitCode = 1; });

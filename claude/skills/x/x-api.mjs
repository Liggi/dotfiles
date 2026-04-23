#!/usr/bin/env node
/**
 * Standalone X (Twitter) API v2 helper script.
 * Reads credentials from ~/.lattice/config.json, auto-refreshes OAuth tokens.
 *
 * Usage:
 *   node x-api.mjs bookmarks [--count N]
 *   node x-api.mjs me
 *   node x-api.mjs tweet <id>
 *   node x-api.mjs post <text> [--media <path>] [--reply-to <id>]
 *   node x-api.mjs search <query> [--count N]
 *   node x-api.mjs user <username>
 *   node x-api.mjs status
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const CONFIG_PATH = path.join(process.env.HOME || '', '.lattice', 'config.json');

function loadConfig() {
  const raw = fs.readFileSync(CONFIG_PATH, 'utf-8');
  return JSON.parse(raw);
}

function saveTokens(tokens) {
  const config = loadConfig();
  config.x.userTokens = tokens;
  fs.writeFileSync(CONFIG_PATH, JSON.stringify(config, null, 2));
}

async function refreshToken(xConfig) {
  const { clientId, clientSecret, userTokens } = xConfig;
  if (!userTokens?.refreshToken) {
    throw new Error('No refresh token available. Re-authorize via Lattice: GET /api/x/auth/start');
  }

  const credentials = Buffer.from(`${clientId}:${clientSecret}`).toString('base64');

  const res = await fetch('https://api.x.com/2/oauth2/token', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
      'Authorization': `Basic ${credentials}`,
    },
    body: new URLSearchParams({
      grant_type: 'refresh_token',
      refresh_token: userTokens.refreshToken,
      client_id: clientId,
    }).toString(),
  });

  if (!res.ok) {
    const err = await res.text();
    throw new Error(`Token refresh failed (${res.status}): ${err}`);
  }

  const data = await res.json();
  const newTokens = {
    accessToken: data.access_token,
    refreshToken: data.refresh_token || userTokens.refreshToken,
    expiresAt: Date.now() + data.expires_in * 1000,
    scope: data.scope,
  };

  saveTokens(newTokens);
  return newTokens.accessToken;
}

async function getAccessToken(xConfig) {
  const { userTokens } = xConfig;
  if (!userTokens) {
    throw new Error('No user tokens. Authorize via Lattice: GET /api/x/auth/start');
  }
  // 5 minute buffer
  if (userTokens.expiresAt > Date.now() + 5 * 60 * 1000) {
    return userTokens.accessToken;
  }
  return refreshToken(xConfig);
}

async function apiCall(xConfig, endpoint, options = {}) {
  const accessToken = await getAccessToken(xConfig);
  const url = endpoint.startsWith('http') ? endpoint : `https://api.x.com/2${endpoint}`;

  const res = await fetch(url, {
    ...options,
    headers: {
      ...options.headers,
      'Authorization': `Bearer ${accessToken}`,
      'Content-Type': options.body ? 'application/json' : undefined,
    },
  });

  if (!res.ok) {
    const err = await res.text();
    throw new Error(`X API ${res.status}: ${err}`);
  }

  return res.json();
}

async function getMe(xConfig) {
  return apiCall(xConfig, '/users/me?user.fields=username,name,description,public_metrics,profile_image_url');
}

async function getBookmarks(xConfig, count = 100) {
  const me = await apiCall(xConfig, '/users/me');
  const userId = me.data.id;

  const params = new URLSearchParams({
    max_results: String(Math.min(count, 100)),
    'tweet.fields': 'created_at,author_id,text,entities',
    expansions: 'author_id',
    'user.fields': 'username,name',
  });

  const result = await apiCall(xConfig, `/users/${userId}/bookmarks?${params}`);

  // Build author lookup
  const users = new Map();
  if (result.includes?.users) {
    for (const u of result.includes.users) {
      users.set(u.id, u);
    }
  }

  // Format output
  const tweets = (result.data || []).map(t => ({
    id: t.id,
    text: t.text,
    author: users.get(t.author_id)?.username || t.author_id,
    authorName: users.get(t.author_id)?.name || '',
    createdAt: t.created_at,
    urls: t.entities?.urls?.map(u => u.expanded_url).filter(Boolean) || [],
  }));

  return { tweets, meta: result.meta };
}

async function searchTweets(xConfig, query, count = 10) {
  const params = new URLSearchParams({
    query,
    max_results: String(Math.min(Math.max(count, 10), 100)),
    'tweet.fields': 'created_at,author_id,text,entities',
    expansions: 'author_id',
    'user.fields': 'username,name',
  });

  const result = await apiCall(xConfig, `/tweets/search/recent?${params}`);

  const users = new Map();
  if (result.includes?.users) {
    for (const u of result.includes.users) {
      users.set(u.id, u);
    }
  }

  const tweets = (result.data || []).map(t => ({
    id: t.id,
    text: t.text,
    author: users.get(t.author_id)?.username || t.author_id,
    authorName: users.get(t.author_id)?.name || '',
    createdAt: t.created_at,
    urls: t.entities?.urls?.map(u => u.expanded_url).filter(Boolean) || [],
  }));

  return { tweets, meta: result.meta };
}

async function lookupTweet(xConfig, tweetId) {
  const params = new URLSearchParams({
    'tweet.fields': 'created_at,author_id,text,public_metrics,entities,conversation_id',
    expansions: 'author_id',
    'user.fields': 'username,name,description',
  });
  return apiCall(xConfig, `/tweets/${tweetId}?${params}`);
}

async function deleteTweet(xConfig, tweetId) {
  const accessToken = await getAccessToken(xConfig);
  const res = await fetch(`https://api.x.com/2/tweets/${tweetId}`, {
    method: 'DELETE',
    headers: { 'Authorization': `Bearer ${accessToken}` },
  });
  if (!res.ok) {
    const err = await res.text();
    throw new Error(`X API ${res.status}: ${err}`);
  }
  return res.json();
}

async function uploadMedia(xConfig, filePath) {
  const accessToken = await getAccessToken(xConfig);
  const fileBuffer = fs.readFileSync(filePath);
  const totalBytes = fileBuffer.length;
  const ext = path.extname(filePath).toLowerCase();
  const mediaType = { '.gif': 'image/gif', '.png': 'image/png', '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg', '.mp4': 'video/mp4', '.webp': 'image/webp' }[ext] || 'application/octet-stream';
  const mediaCategory = ext === '.gif' ? 'tweet_gif' : ['.mp4'].includes(ext) ? 'tweet_video' : 'tweet_image';
  const needsChunked = mediaCategory === 'tweet_gif' || mediaCategory === 'tweet_video';

  const headers = { 'Authorization': `Bearer ${accessToken}` };
  const BASE = 'https://api.x.com/2/media/upload';

  // Simple upload for images under 5MB
  if (!needsChunked && totalBytes < 5 * 1024 * 1024) {
    const form = new FormData();
    form.append('media', new Blob([fileBuffer], { type: mediaType }));
    form.append('media_category', mediaCategory);
    const res = await fetch(BASE, { method: 'POST', headers, body: form });
    if (!res.ok) throw new Error(`Media upload failed (${res.status}): ${await res.text()}`);
    const data = await res.json();
    return data.media_id_string || data.data?.id;
  }

  // Dedicated chunked endpoints for GIFs, videos, and large images
  // INITIALIZE
  const initBody = JSON.stringify({
    media_type: mediaType,
    total_bytes: totalBytes,
    media_category: mediaCategory,
  });
  const initRes = await fetch(`${BASE}/initialize`, {
    method: 'POST',
    headers: { ...headers, 'Content-Type': 'application/json' },
    body: initBody,
  });
  if (!initRes.ok) throw new Error(`Media INIT failed (${initRes.status}): ${await initRes.text()}`);
  const initData = await initRes.json();
  const mediaId = initData.media_id_string || initData.id || initData.data?.id;
  console.error(`Media initialized: ${mediaId}`);

  // APPEND in 1MB chunks
  const CHUNK_SIZE = 1024 * 1024;
  for (let i = 0; i * CHUNK_SIZE < totalBytes; i++) {
    const chunk = fileBuffer.slice(i * CHUNK_SIZE, (i + 1) * CHUNK_SIZE);
    const appendForm = new FormData();
    appendForm.append('segment_index', String(i));
    appendForm.append('media', new Blob([chunk], { type: 'application/octet-stream' }));

    const appendRes = await fetch(`${BASE}/${mediaId}/append`, {
      method: 'POST',
      headers,
      body: appendForm,
    });
    if (!appendRes.ok) throw new Error(`Media APPEND segment ${i} failed (${appendRes.status}): ${await appendRes.text()}`);
    console.error(`Uploaded chunk ${i + 1}/${Math.ceil(totalBytes / CHUNK_SIZE)}`);
  }

  // FINALIZE
  const finalRes = await fetch(`${BASE}/${mediaId}/finalize`, {
    method: 'POST',
    headers: { ...headers, 'Content-Type': 'application/json' },
  });
  if (!finalRes.ok) throw new Error(`Media FINALIZE failed (${finalRes.status}): ${await finalRes.text()}`);
  const finalData = await finalRes.json();

  // Poll for processing completion (GIFs/videos need async processing)
  const procInfo = finalData.processing_info || finalData.data?.processing_info;
  if (procInfo) {
    let state = procInfo.state;
    let checkAfter = procInfo.check_after_secs || 2;
    while (state === 'pending' || state === 'in_progress') {
      console.error(`Processing: ${state}, checking in ${checkAfter}s...`);
      await new Promise(r => setTimeout(r, checkAfter * 1000));
      const statusRes = await fetch(`${BASE}?command=STATUS&media_id=${mediaId}`, { headers });
      if (!statusRes.ok) throw new Error(`Media STATUS failed (${statusRes.status}): ${await statusRes.text()}`);
      const statusData = await statusRes.json();
      const info = statusData.processing_info || statusData.data?.processing_info;
      if (!info) break;
      state = info.state;
      checkAfter = info.check_after_secs || 2;
      if (state === 'failed') throw new Error(`Media processing failed: ${JSON.stringify(info.error || info)}`);
    }
  }

  return mediaId;
}

async function postTweet(xConfig, text, options = {}) {
  const body = { text };
  if (options.mediaIds?.length) {
    body.media = { media_ids: options.mediaIds };
  }
  if (options.replyTo) {
    body.reply = { in_reply_to_tweet_id: options.replyTo };
  }
  return apiCall(xConfig, '/tweets', {
    method: 'POST',
    body: JSON.stringify(body),
  });
}

async function lookupUser(xConfig, username) {
  return apiCall(xConfig, `/users/by/username/${username}?user.fields=description,profile_image_url,public_metrics,created_at`);
}

// --- CLI ---
const args = process.argv.slice(2);
const command = args[0];

if (!command) {
  console.error('Usage: x-api.mjs <command> [args]\nCommands: bookmarks, me, tweet <id>, post <text> [--media <path>] [--reply-to <id>], search, user, delete, status');
  process.exit(1);
}

try {
  const config = loadConfig();
  const xConfig = config.x;

  if (!xConfig) {
    console.error('No X API config found in ~/.lattice/config.json. Add x.clientId, x.clientSecret, and authorize.');
    process.exit(1);
  }

  switch (command) {
    case 'status': {
      const hasApp = !!xConfig.bearerToken;
      const hasUser = !!xConfig.userTokens;
      const expired = hasUser && xConfig.userTokens.expiresAt < Date.now();
      const hasRefresh = hasUser && !!xConfig.userTokens.refreshToken;
      console.log(JSON.stringify({
        appAuth: hasApp,
        userAuth: hasUser,
        expired,
        canRefresh: hasRefresh,
        scopes: xConfig.userTokens?.scope || '',
        expiresAt: xConfig.userTokens ? new Date(xConfig.userTokens.expiresAt).toISOString() : null,
      }, null, 2));
      break;
    }

    case 'me': {
      const me = await getMe(xConfig);
      console.log(JSON.stringify(me, null, 2));
      break;
    }

    case 'bookmarks': {
      const countIdx = args.indexOf('--count');
      const count = countIdx !== -1 ? parseInt(args[countIdx + 1]) : 100;
      const result = await getBookmarks(xConfig, count);
      console.log(JSON.stringify(result, null, 2));
      break;
    }

    case 'search': {
      const query = args[1];
      if (!query) { console.error('Usage: x-api.mjs search <query> [--count N]'); process.exit(1); }
      const countIdx = args.indexOf('--count');
      const count = countIdx !== -1 ? parseInt(args[countIdx + 1]) : 10;
      const result = await searchTweets(xConfig, query, count);
      console.log(JSON.stringify(result, null, 2));
      break;
    }

    case 'tweet': {
      const tweetId = args[1];
      if (!tweetId) { console.error('Usage: x-api.mjs tweet <id>'); process.exit(1); }
      const result = await lookupTweet(xConfig, tweetId);
      console.log(JSON.stringify(result, null, 2));
      break;
    }

    case 'post': {
      const mediaIdx = args.indexOf('--media');
      const replyIdx = args.indexOf('--reply-to');
      // Extract flags before building text
      const mediaPath = mediaIdx !== -1 ? args[mediaIdx + 1] : null;
      const replyTo = replyIdx !== -1 ? args[replyIdx + 1] : null;
      // Build text from args, excluding flag pairs
      const textParts = [];
      for (let i = 1; i < args.length; i++) {
        if ((i === mediaIdx || i === replyIdx) && i + 1 < args.length) { i++; continue; }
        if (i === mediaIdx + 1 || i === replyIdx + 1) continue;
        textParts.push(args[i]);
      }
      const text = textParts.join(' ');
      if (!text && !mediaPath) { console.error('Usage: x-api.mjs post <text> [--media <path>] [--reply-to <id>]'); process.exit(1); }

      const options = {};
      if (mediaPath) {
        console.error(`Uploading media: ${mediaPath}...`);
        const mediaId = await uploadMedia(xConfig, mediaPath);
        console.error(`Media uploaded: ${mediaId}`);
        options.mediaIds = [mediaId];
      }
      if (replyTo) {
        options.replyTo = replyTo;
      }
      const result = await postTweet(xConfig, text, options);
      console.log(JSON.stringify(result, null, 2));
      break;
    }

    case 'delete': {
      const tweetId = args[1];
      if (!tweetId) { console.error('Usage: x-api.mjs delete <tweet-id>'); process.exit(1); }
      const result = await deleteTweet(xConfig, tweetId);
      console.log(JSON.stringify(result, null, 2));
      break;
    }

    case 'user': {
      const username = args[1];
      if (!username) { console.error('Usage: x-api.mjs user <username>'); process.exit(1); }
      const result = await lookupUser(xConfig, username);
      console.log(JSON.stringify(result, null, 2));
      break;
    }

    default:
      console.error(`Unknown command: ${command}\nCommands: bookmarks, me, tweet, search, user, status`);
      process.exit(1);
  }
} catch (err) {
  console.error(`Error: ${err.message}`);
  process.exit(1);
}

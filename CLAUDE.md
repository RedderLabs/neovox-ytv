# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

NEOVOX Music is a modern web music streaming app (RiMusic-style) that uses YouTube as a backend for audio. Node.js/Express server with PostgreSQL for accounts/playlists, and a vanilla JS SPA frontend.

## How to Run

```bash
npm install
npm start          # production (node server.js)
npm run dev        # development (nodemon)
```
Requires `DATABASE_URL` in `.env` (PostgreSQL/Neon connection string).

## Architecture

### Backend (Node.js + Express)
- **server.js** — Main server: Express app, PostgreSQL pool (Neon), DB init, CORS, static files, route mounting.
- **api/account.js** — Anonymous account system: create (POST), login (POST), delete (DELETE). 16-digit numeric account number.
- **api/playlists.js** — CRUD for saved playlists (max 20). Requires `X-Account-Number` header.
- **api/search.js** — YouTube search (`ytsr`), playlist items (`ytpl`), video info (`ytdl-core`), trending.
- **api/audio-proxy.js** — Resolves audio stream URLs via `ytdl-core` and proxies YouTube audio to bypass CORS.
- **api/stats.js** — Visit tracking and stats.
- **api/helpers.js** — Shared utilities: `uid()`, `generateAccountNumber()`, `requireAccount` middleware.

### Frontend (public/)
- **index.html** — SPA layout: auth screen, 4 main pages (Home, Search, Library, Settings), playlist detail page, mini player, full-screen player, queue panel, add playlist modal, bottom navigation.
- **style.css** — Modern dark/light theme with CSS variables. Material Symbols icons, Inter font. Mobile-first responsive.
- **app.js** — All client logic: auth flow, page navigation, search (debounced), playlist management, audio playback via HTML5 Audio element + server-side stream proxy, queue/shuffle/repeat, mini/full player, Media Session API.

### Key Endpoints
- `GET /api/search?q=...` — Search YouTube videos
- `GET /api/playlist-items/:playlistId` — Get playlist tracks
- `GET /api/stream-url/:videoId` — Resolve audio stream URL
- `GET /api/audio-proxy?url=...` — Proxy YouTube audio stream
- `GET /api/trending` — Get trending music

## Key Design Decisions

- **Server-side audio resolution**: Uses `@distube/ytdl-core` to resolve audio URLs server-side, then proxies the stream to avoid CORS issues in the browser.
- **HTML5 Audio**: Uses native `<audio>` element instead of YouTube IFrame API for cleaner playback control.
- **Anonymous accounts**: Mullvad-style 16-digit number system. No email/password.
- **No framework**: Vanilla JS SPA with page-based navigation and CSS transitions.
- **Material Symbols**: Google Material icons with FILL/wght variation settings.

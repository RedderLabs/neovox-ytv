# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

NEOVOX YT-V is a browser-based YouTube playlist player styled as a futuristic cyber-themed turntable. Purely static frontend (HTML + CSS + JS) with no build step. Uses YouTube IFrame API for playback and LocalStorage for playlist persistence.

## How to Run

Open `index.html` directly in a browser or serve via any static file server. No build or install step required.

## Architecture

- **index.html** — Layout structure using Tailwind CSS v4 (`@tailwindcss/browser@4` via CDN). Loads YouTube IFrame API, Google Fonts (Orbitron, Share Tech Mono), and links to `style.css` + `app.js`.
- **style.css** — All custom styles: `@theme` block for Tailwind custom tokens (cyber color palette, fonts), turntable visuals (vinyl conic gradient, tonearm with needle, platter), scanlines overlay, waveform bars, control buttons, playlist items, cyber-themed inputs, progress bar with glow, and animations (spin, blink, wave).
- **app.js** — Application logic: YouTube IFrame Player API integration (load/play/pause/stop/next/prev playlists), LocalStorage CRUD for playlists, DOM waveform animation (simulated bars), tonearm arm positioning, progress tracking via polling `getCurrentTime()`/`getDuration()`, volume control, LED dot state indicators.

## Key Design Decisions

- **YouTube IFrame API**: Player is hidden (1x1px, opacity 0) — audio only. Playback state changes (`onStateChange`) drive all visual updates (vinyl spin, tonearm, waveform, dots).
- **Tonearm**: CSS `transform: rotate()` with transition. `setArm(true)` = 14deg (on disc), `setArm(false)` = -28deg (rest). Play moves needle onto disc, pause keeps it on disc, stop returns to rest.
- **Waveform**: Simulated (not real audio analysis). 52 `div` bars animated with `setInterval` + sine wave + random noise.
- **Playlist vault**: Stored in `localStorage` under key `neovox_playlists_v1`. Each entry has `{id, name, ytId, added}`. YouTube playlist ID extracted from URL via regex `[?&]list=([a-zA-Z0-9_-]+)`.
- **No framework**: Vanilla JS with cached DOM refs. Single-page, no routing.

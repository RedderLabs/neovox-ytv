const https = require('https');
const http = require('http');
const ytdl = require('@distube/ytdl-core');

module.exports = function audioProxyRoutes() {
  const router = require('express').Router();

  // GET /api/stream-url/:videoId
  // Resolves the audio stream URL for a YouTube video (server-side, no CORS issues)
  router.get('/stream-url/:videoId', async (req, res) => {
    try {
      const { videoId } = req.params;
      if (!videoId || !/^[a-zA-Z0-9_-]{11}$/.test(videoId)) {
        return res.status(400).json({ error: 'Invalid video ID' });
      }
      const info = await ytdl.getInfo(videoId);
      // Get audio-only formats sorted by bitrate (highest first)
      const audioFormats = ytdl.filterFormats(info.formats, 'audioonly');
      if (audioFormats.length === 0) {
        return res.status(404).json({ error: 'No audio streams found' });
      }
      // Pick highest bitrate audio
      audioFormats.sort((a, b) => (b.audioBitrate || 0) - (a.audioBitrate || 0));
      const best = audioFormats[0];
      res.json({ url: best.url, mimeType: best.mimeType });
    } catch (e) {
      console.error('Stream URL error:', e.message);
      res.status(500).json({ error: 'Failed to resolve stream URL' });
    }
  });

  // GET /api/audio-proxy?url=<encoded_url>
  // Proxies a YouTube audio stream to bypass CORS for Flutter web
  router.get('/audio-proxy', (req, res) => {
    const targetUrl = req.query.url;
    if (!targetUrl) {
      return res.status(400).json({ error: 'Missing url parameter' });
    }

    let parsed;
    try {
      parsed = new URL(targetUrl);
    } catch {
      return res.status(400).json({ error: 'Invalid url' });
    }

    // Only allow YouTube/Google domains
    const allowed = [
      'googlevideo.com',
      'youtube.com',
      'ytimg.com',
      'ggpht.com',
      'googleusercontent.com',
    ];
    const host = parsed.hostname.toLowerCase();
    if (!allowed.some(d => host === d || host.endsWith('.' + d))) {
      return res.status(403).json({ error: 'Domain not allowed' });
    }

    const client = parsed.protocol === 'https:' ? https : http;

    const proxyHeaders = {};
    // Forward range header for seeking support
    if (req.headers.range) {
      proxyHeaders['Range'] = req.headers.range;
    }

    const proxyReq = client.get(parsed.href, { headers: proxyHeaders }, (proxyRes) => {
      // Forward relevant headers
      const fwd = ['content-type', 'content-length', 'content-range', 'accept-ranges'];
      for (const h of fwd) {
        if (proxyRes.headers[h]) {
          res.setHeader(h, proxyRes.headers[h]);
        }
      }

      res.status(proxyRes.statusCode);
      proxyRes.pipe(res);
    });

    proxyReq.on('error', (err) => {
      console.error('Audio proxy error:', err.message);
      if (!res.headersSent) {
        res.status(502).json({ error: 'Proxy failed' });
      }
    });

    req.on('close', () => {
      proxyReq.destroy();
    });
  });

  return router;
};

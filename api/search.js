const ytpl = require('ytpl');
const ytdl = require('@distube/ytdl-core');

// Simple YouTube search using innertube API (no external scraper needed)
async function ytSearch(query, limit = 20) {
  const url = `https://www.youtube.com/results?search_query=${encodeURIComponent(query)}&sp=EgIQAQ%253D%253D`;
  const res = await fetch(url, {
    headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Accept-Language': 'en-US,en;q=0.9',
    },
  });
  const html = await res.text();

  // Extract ytInitialData JSON
  const match = html.match(/var ytInitialData = ({.*?});<\/script>/s);
  if (!match) return [];

  try {
    const data = JSON.parse(match[1]);
    const contents = data?.contents?.twoColumnSearchResultsRenderer?.primaryContents
      ?.sectionListRenderer?.contents?.[0]?.itemSectionRenderer?.contents || [];

    const results = [];
    for (const item of contents) {
      const v = item.videoRenderer;
      if (!v || !v.videoId) continue;

      const durText = v.lengthText?.simpleText || '0:00';
      const title = v.title?.runs?.[0]?.text || '';
      const artist = v.ownerText?.runs?.[0]?.text || 'Unknown';
      const thumb = v.thumbnail?.thumbnails?.slice(-1)[0]?.url || '';
      const views = parseInt((v.viewCountText?.simpleText || '0').replace(/[^0-9]/g, '')) || 0;

      results.push({ videoId: v.videoId, title, artist, thumbnail: thumb, duration: durText, views });
      if (results.length >= limit) break;
    }
    return results;
  } catch (e) {
    console.error('Search parse error:', e.message);
    return [];
  }
}

module.exports = function searchRoutes() {
  const router = require('express').Router();

  // GET /api/search?q=query&limit=20
  router.get('/search', async (req, res) => {
    try {
      const { q, limit = 20 } = req.query;
      if (!q) return res.status(400).json({ error: 'Missing query' });
      const items = await ytSearch(q, parseInt(limit));
      res.json(items);
    } catch (e) {
      console.error('Search error:', e.message);
      res.status(500).json({ error: 'Search failed' });
    }
  });

  // GET /api/playlist-items/:playlistId
  router.get('/playlist-items/:playlistId', async (req, res) => {
    try {
      const { playlistId } = req.params;
      const playlist = await ytpl(playlistId, { limit: 100 });

      const items = playlist.items.map(v => ({
        videoId: v.id,
        title: v.title,
        artist: v.author?.name || 'Unknown',
        thumbnail: v.bestThumbnail?.url || v.thumbnails?.[0]?.url || '',
        duration: v.duration || '0:00',
        isPlayable: !v.isLive,
      }));

      res.json({
        title: playlist.title,
        author: playlist.author?.name || 'Unknown',
        thumbnail: playlist.bestThumbnail?.url || '',
        itemCount: playlist.estimatedItemCount,
        items,
      });
    } catch (e) {
      console.error('Playlist items error:', e.message);
      res.status(500).json({ error: 'Failed to fetch playlist' });
    }
  });

  // GET /api/video-info/:videoId
  router.get('/video-info/:videoId', async (req, res) => {
    try {
      const { videoId } = req.params;
      if (!videoId || !/^[a-zA-Z0-9_-]{11}$/.test(videoId)) {
        return res.status(400).json({ error: 'Invalid video ID' });
      }
      const info = await ytdl.getInfo(videoId);
      const details = info.videoDetails;
      const thumbnail = details.thumbnails?.sort((a, b) => (b.width || 0) - (a.width || 0))[0]?.url || '';

      res.json({
        videoId: details.videoId,
        title: details.title,
        artist: details.author?.name || 'Unknown',
        thumbnail,
        duration: parseInt(details.lengthSeconds) || 0,
        views: parseInt(details.viewCount) || 0,
      });
    } catch (e) {
      console.error('Video info error:', e.message);
      res.status(500).json({ error: 'Failed to get video info' });
    }
  });

  // GET /api/trending — search-based trending with duration filter
  router.get('/trending', async (req, res) => {
    try {
      const queries = [
        'top songs this week official music video',
        'new music 2025 official video',
        'hit songs 2025 music video',
      ];
      const query = queries[Math.floor(Math.random() * queries.length)];
      const all = await ytSearch(query, 40);

      // Filter: only songs under 8 minutes
      const items = all.filter(v => {
        const parts = v.duration.split(':').map(Number);
        let secs = 0;
        if (parts.length === 3) secs = parts[0] * 3600 + parts[1] * 60 + parts[2];
        else if (parts.length === 2) secs = parts[0] * 60 + parts[1];
        return secs > 30 && secs < 480;
      }).slice(0, 20);

      res.json(items);
    } catch (e) {
      console.error('Trending error:', e.message);
      res.status(500).json({ error: 'Failed to fetch trending' });
    }
  });

  return router;
};

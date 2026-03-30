const { Router } = require('express');
const ytsr = require('ytsr');
const ytpl = require('ytpl');
const ytdl = require('@distube/ytdl-core');

module.exports = function searchRoutes() {
  const router = Router();

  // GET /api/search?q=query&limit=20
  router.get('/search', async (req, res) => {
    try {
      const { q, limit = 20 } = req.query;
      if (!q) return res.status(400).json({ error: 'Missing query' });

      const filters = await ytsr.getFilters(q);
      const videoFilter = filters.get('Type')?.get('Video');
      const results = await ytsr(videoFilter?.url || q, { limit: parseInt(limit) });

      const items = results.items
        .filter(i => i.type === 'video')
        .map(v => ({
          videoId: v.id,
          title: v.title,
          artist: v.author?.name || 'Unknown',
          thumbnail: v.bestThumbnail?.url || v.thumbnails?.[0]?.url || '',
          duration: v.duration || '0:00',
          views: v.views || 0,
        }));

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

  // GET /api/suggestions?q=query
  router.get('/suggestions', async (req, res) => {
    try {
      const { q } = req.query;
      if (!q) return res.json([]);
      const results = await ytsr.getFilters(q);
      // Return the search refinements as suggestions
      const suggestions = [];
      for (const [, filter] of results) {
        for (const [name] of filter) {
          if (name && name !== 'Video' && name !== 'Channel' && name !== 'Playlist') {
            suggestions.push(name);
          }
        }
      }
      res.json(suggestions.slice(0, 8));
    } catch (e) {
      res.json([]);
    }
  });

  // GET /api/trending — get popular music
  router.get('/trending', async (req, res) => {
    try {
      const results = await ytsr('trending music 2026', { limit: 20 });
      const items = results.items
        .filter(i => i.type === 'video')
        .map(v => ({
          videoId: v.id,
          title: v.title,
          artist: v.author?.name || 'Unknown',
          thumbnail: v.bestThumbnail?.url || v.thumbnails?.[0]?.url || '',
          duration: v.duration || '0:00',
          views: v.views || 0,
        }));
      res.json(items);
    } catch (e) {
      console.error('Trending error:', e.message);
      res.status(500).json({ error: 'Failed to fetch trending' });
    }
  });

  return router;
};

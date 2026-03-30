const YouTube = require('youtube-sr').default;
const ytpl = require('ytpl');
const ytdl = require('@distube/ytdl-core');

module.exports = function searchRoutes() {
  const router = require('express').Router();

  // GET /api/search?q=query&limit=20
  router.get('/search', async (req, res) => {
    try {
      const { q, limit = 20 } = req.query;
      if (!q) return res.status(400).json({ error: 'Missing query' });

      const results = await YouTube.search(q, { limit: parseInt(limit), type: 'video' });

      const items = results.map(v => ({
        videoId: v.id,
        title: v.title || '',
        artist: v.channel?.name || 'Unknown',
        thumbnail: v.thumbnail?.url || '',
        duration: v.durationFormatted || '0:00',
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

  // GET /api/trending — popular music
  router.get('/trending', async (req, res) => {
    try {
      const results = await YouTube.search('popular music 2025', { limit: 20, type: 'video' });

      const items = results.map(v => ({
        videoId: v.id,
        title: v.title || '',
        artist: v.channel?.name || 'Unknown',
        thumbnail: v.thumbnail?.url || '',
        duration: v.durationFormatted || '0:00',
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

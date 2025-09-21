/**
 * StudyPals Spotify Integration - Complete Backend Server
 * 
 * This is a consolidated Node.js server that handles all backend functionality
 * for the Spotify integration. It includes:
 * - OAuth token exchange and refresh
 * - Spotify API proxy endpoints
 * - CORS handling
 * - Error handling and logging
 * 
 * To run this server:
 * 1. Install dependencies: npm install express cors axios dotenv
 * 2. Create .env file with Spotify credentials
 * 3. Run: node spotify-server.js
 * 
 * @author StudyPals Team
 * @version 1.0.0
 */

const express = require('express');
const cors = require('cors');
const axios = require('axios');
const path = require('path');

// Load environment variables
require('dotenv').config();

// Initialize Express application
const app = express();

// Server configuration
const PORT = process.env.PORT || 5000;
const FRONTEND_URL = process.env.FRONTEND_URL || 'http://127.0.0.1:3000';

// Spotify configuration
const SPOTIFY_CONFIG = {
  CLIENT_ID: process.env.SPOTIFY_CLIENT_ID || '6840c4bc3c11466a81c2822ca3cd1f2e',
  CLIENT_SECRET: process.env.SPOTIFY_CLIENT_SECRET || '2cd3e20bd4e340428050c00d903aef25',
  REDIRECT_URI: process.env.SPOTIFY_REDIRECT_URI || 'http://127.0.0.1:3000/auth/spotify/callback',
  SCOPES: [
    'user-read-private',
    'user-read-email',
    'playlist-read-private',
    'playlist-read-collaborative',
    'playlist-modify-public',
    'playlist-modify-private',
    'user-library-read',
    'user-library-modify'
  ]
};

// Middleware configuration
app.use(cors({
  origin: FRONTEND_URL,
  credentials: true
}));
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// Serve the main HTML file
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'spotify-integration.html'));
});

/**
 * Spotify Token Exchange Function
 * 
 * Exchanges an authorization code for access and refresh tokens.
 * This is a critical security step that must happen server-side to protect
 * the client secret from being exposed in the frontend.
 */
async function exchangeSpotifyTokens(code, clientId, clientSecret, redirectUri) {
  try {
    const response = await axios.post('https://accounts.spotify.com/api/token', 
      new URLSearchParams({
        grant_type: 'authorization_code',
        code: code,
        redirect_uri: redirectUri,
        client_id: clientId,
        client_secret: clientSecret
      }), {
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded'
        }
      }
    );
    
    return {
      accessToken: response.data.access_token,
      refreshToken: response.data.refresh_token,
      expiresAt: Date.now() + (response.data.expires_in * 1000)
    };
  } catch (error) {
    console.error('Spotify token exchange error:', error.response?.data || error.message);
    throw new Error('Failed to exchange authorization code for tokens');
  }
}

/**
 * Spotify Token Refresh Function
 * 
 * Refreshes an expired access token using the refresh token.
 */
async function refreshSpotifyToken(refreshToken) {
  try {
    const response = await axios.post('https://accounts.spotify.com/api/token',
      new URLSearchParams({
        grant_type: 'refresh_token',
        refresh_token: refreshToken,
        client_id: SPOTIFY_CONFIG.CLIENT_ID,
        client_secret: SPOTIFY_CONFIG.CLIENT_SECRET
      }), {
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded'
        }
      }
    );
    
    return {
      accessToken: response.data.access_token,
      expiresAt: Date.now() + (response.data.expires_in * 1000)
    };
  } catch (error) {
    console.error('Spotify token refresh error:', error.response?.data || error.message);
    throw new Error('Failed to refresh access token');
  }
}

/**
 * Generic Token Exchange Endpoint
 * 
 * POST /api/auth/token
 * 
 * Handles OAuth token exchange for Spotify.
 */
app.post('/api/auth/token', async (req, res) => {
  try {
    const { provider, code, clientId, clientSecret, redirectUri } = req.body;
    
    if (provider !== 'spotify') {
      return res.status(400).json({ error: 'Only Spotify is supported in this version' });
    }
    
    const tokens = await exchangeSpotifyTokens(code, clientId, clientSecret, redirectUri);
    res.json(tokens);
    
  } catch (error) {
    console.error('Token exchange error:', error);
    res.status(500).json({ 
      error: 'Failed to exchange tokens',
      message: error.message 
    });
  }
});

/**
 * Token Refresh Endpoint
 * 
 * POST /api/auth/refresh
 * 
 * Handles refreshing expired access tokens.
 */
app.post('/api/auth/refresh', async (req, res) => {
  try {
    const { provider, refreshToken } = req.body;
    
    if (provider !== 'spotify') {
      return res.status(400).json({ error: 'Only Spotify is supported in this version' });
    }
    
    const tokens = await refreshSpotifyToken(refreshToken);
    res.json(tokens);
    
  } catch (error) {
    console.error('Token refresh error:', error);
    res.status(500).json({ 
      error: 'Failed to refresh token',
      message: error.message 
    });
  }
});

/**
 * Spotify API Proxy Endpoints
 * 
 * These endpoints proxy requests to the Spotify API to avoid CORS issues
 * and provide a consistent interface for the frontend.
 */

// Get current user profile
app.get('/api/spotify/me', async (req, res) => {
  try {
    const { access_token } = req.headers;
    
    if (!access_token) {
      return res.status(401).json({ error: 'Access token required' });
    }
    
    const response = await axios.get('https://api.spotify.com/v1/me', {
      headers: {
        'Authorization': `Bearer ${access_token}`
      }
    });
    
    res.json(response.data);
    
  } catch (error) {
    console.error('Spotify API error:', error.response?.data || error.message);
    res.status(error.response?.status || 500).json({
      error: 'Failed to fetch user data',
      message: error.response?.data?.error?.message || error.message
    });
  }
});

// Get user's playlists
app.get('/api/spotify/playlists', async (req, res) => {
  try {
    const { access_token } = req.headers;
    
    if (!access_token) {
      return res.status(401).json({ error: 'Access token required' });
    }
    
    const response = await axios.get('https://api.spotify.com/v1/me/playlists', {
      headers: {
        'Authorization': `Bearer ${access_token}`
      }
    });
    
    res.json(response.data);
    
  } catch (error) {
    console.error('Spotify API error:', error.response?.data || error.message);
    res.status(error.response?.status || 500).json({
      error: 'Failed to fetch playlists',
      message: error.response?.data?.error?.message || error.message
    });
  }
});

// Get playlist tracks
app.get('/api/spotify/playlists/:playlistId/tracks', async (req, res) => {
  try {
    const { access_token } = req.headers;
    const { playlistId } = req.params;
    
    if (!access_token) {
      return res.status(401).json({ error: 'Access token required' });
    }
    
    const response = await axios.get(`https://api.spotify.com/v1/playlists/${playlistId}/tracks`, {
      headers: {
        'Authorization': `Bearer ${access_token}`
      }
    });
    
    res.json(response.data);
    
  } catch (error) {
    console.error('Spotify API error:', error.response?.data || error.message);
    res.status(error.response?.status || 500).json({
      error: 'Failed to fetch playlist tracks',
      message: error.response?.data?.error?.message || error.message
    });
  }
});

// Search tracks
app.get('/api/spotify/search', async (req, res) => {
  try {
    const { access_token } = req.headers;
    const { q, type = 'track', limit = 10 } = req.query;
    
    if (!access_token) {
      return res.status(401).json({ error: 'Access token required' });
    }
    
    if (!q) {
      return res.status(400).json({ error: 'Query parameter is required' });
    }
    
    const response = await axios.get('https://api.spotify.com/v1/search', {
      headers: {
        'Authorization': `Bearer ${access_token}`
      },
      params: {
        q: q,
        type: type,
        limit: limit
      }
    });
    
    res.json(response.data);
    
  } catch (error) {
    console.error('Spotify API error:', error.response?.data || error.message);
    res.status(error.response?.status || 500).json({
      error: 'Failed to search tracks',
      message: error.response?.data?.error?.message || error.message
    });
  }
});

// Create playlist
app.post('/api/spotify/playlists', async (req, res) => {
  try {
    const { access_token } = req.headers;
    const { name, description, public: isPublic = false } = req.body;
    
    if (!access_token) {
      return res.status(401).json({ error: 'Access token required' });
    }
    
    if (!name) {
      return res.status(400).json({ error: 'Playlist name is required' });
    }
    
    // First get the user ID
    const userResponse = await axios.get('https://api.spotify.com/v1/me', {
      headers: {
        'Authorization': `Bearer ${access_token}`
      }
    });
    
    const userId = userResponse.data.id;
    
    // Create the playlist
    const response = await axios.post(`https://api.spotify.com/v1/users/${userId}/playlists`, {
      name: name,
      description: description,
      public: isPublic
    }, {
      headers: {
        'Authorization': `Bearer ${access_token}`,
        'Content-Type': 'application/json'
      }
    });
    
    res.json(response.data);
    
  } catch (error) {
    console.error('Spotify API error:', error.response?.data || error.message);
    res.status(error.response?.status || 500).json({
      error: 'Failed to create playlist',
      message: error.response?.data?.error?.message || error.message
    });
  }
});

// Add tracks to playlist
app.post('/api/spotify/playlists/:playlistId/tracks', async (req, res) => {
  try {
    const { access_token } = req.headers;
    const { playlistId } = req.params;
    const { uris } = req.body;
    
    if (!access_token) {
      return res.status(401).json({ error: 'Access token required' });
    }
    
    if (!uris || !Array.isArray(uris) || uris.length === 0) {
      return res.status(400).json({ error: 'Track URIs are required' });
    }
    
    const response = await axios.post(`https://api.spotify.com/v1/playlists/${playlistId}/tracks`, {
      uris: uris
    }, {
      headers: {
        'Authorization': `Bearer ${access_token}`,
        'Content-Type': 'application/json'
      }
    });
    
    res.json(response.data);
    
  } catch (error) {
    console.error('Spotify API error:', error.response?.data || error.message);
    res.status(error.response?.status || 500).json({
      error: 'Failed to add tracks to playlist',
      message: error.response?.data?.error?.message || error.message
    });
  }
});

/**
 * Health Check Endpoint
 * 
 * GET /api/health
 * 
 * Simple endpoint to verify that the server is running and responsive.
 */
app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    timestamp: new Date().toISOString(),
    version: '1.0.0',
    spotify: {
      clientId: SPOTIFY_CONFIG.CLIENT_ID ? 'configured' : 'missing',
      redirectUri: SPOTIFY_CONFIG.REDIRECT_URI
    }
  });
});

/**
 * Configuration Endpoint
 * 
 * GET /api/config
 * 
 * Returns public configuration for the frontend.
 */
app.get('/api/config', (req, res) => {
  res.json({
    spotify: {
      clientId: SPOTIFY_CONFIG.CLIENT_ID,
      redirectUri: SPOTIFY_CONFIG.REDIRECT_URI,
      scopes: SPOTIFY_CONFIG.SCOPES
    }
  });
});

/**
 * Error Handling Middleware
 */
app.use((error, req, res, next) => {
  console.error('Unhandled error:', error);
  res.status(500).json({
    error: 'Internal server error',
    message: error.message
  });
});

/**
 * 404 Handler
 */
app.use((req, res) => {
  res.status(404).json({
    error: 'Not found',
    message: `Route ${req.method} ${req.path} not found`
  });
});

/**
 * Start the Express Server
 * 
 * Starts the server on the specified port and logs startup information.
 */
app.listen(PORT, () => {
  console.log('🎵 StudyPals Spotify Integration Server');
  console.log('🚀 Server running on port', PORT);
  console.log('🔗 Frontend URL:', FRONTEND_URL);
  console.log('🔗 Health check: http://localhost:' + PORT + '/api/health');
  console.log('🔗 Main app: http://localhost:' + PORT);
  console.log('🔐 Token exchange: http://localhost:' + PORT + '/api/auth/token');
  console.log('🔄 Token refresh: http://localhost:' + PORT + '/api/auth/refresh');
  console.log('🎵 Spotify API proxy: http://localhost:' + PORT + '/api/spotify/*');
  console.log('');
  console.log('📋 Configuration:');
  console.log('   Spotify Client ID:', SPOTIFY_CONFIG.CLIENT_ID ? '✅ Configured' : '❌ Missing');
  console.log('   Spotify Client Secret:', SPOTIFY_CONFIG.CLIENT_SECRET ? '✅ Configured' : '❌ Missing');
  console.log('   Redirect URI:', SPOTIFY_CONFIG.REDIRECT_URI);
  console.log('');
  console.log('🌐 Open your browser to: http://localhost:' + PORT);
});

// Graceful shutdown
process.on('SIGINT', () => {
  console.log('\n🛑 Shutting down server...');
  process.exit(0);
});

process.on('SIGTERM', () => {
  console.log('\n🛑 Shutting down server...');
  process.exit(0);
});

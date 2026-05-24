const express = require('express');
const jwt = require('jsonwebtoken');
const User = require('../models/User');

const router = express.Router();

// ── Helpers ───────────────────────────────────────────────────────────────────
const PRIVATE_KEY = (process.env.JWT_PRIVATE_KEY || '').replace(/\\n/g, '\n');
const PUBLIC_KEY  = (process.env.JWT_PUBLIC_KEY  || '').replace(/\\n/g, '\n');
const ACCESS_TOKEN_EXPIRY  = '15m';
const REFRESH_TOKEN_EXPIRY = '7d';

const REFRESH_COOKIE_OPTIONS = {
  httpOnly: true,                          // ❌ JS cannot access this cookie
  secure: process.env.NODE_ENV === 'production', // HTTPS only in prod
  sameSite: 'Strict',                      // CSRF protection
  maxAge: 7 * 24 * 60 * 60 * 1000,        // 7 days in ms
  path: '/api/users/refresh',              // Only sent to the refresh endpoint
};

function signAccessToken(payload) {
  return jwt.sign(payload, PRIVATE_KEY, { algorithm: 'RS256', expiresIn: ACCESS_TOKEN_EXPIRY });
}

function signRefreshToken(payload) {
  return jwt.sign(payload, PRIVATE_KEY, { algorithm: 'RS256', expiresIn: REFRESH_TOKEN_EXPIRY });
}

// ── POST /api/users/register ──────────────────────────────────────────────────
router.post('/register', async (req, res) => {
  try {
    const { name, email, password } = req.body;

    if (!name || !email || !password) {
      return res.status(400).json({ message: 'All fields are required' });
    }

    const existing = await User.findOne({ email });
    if (existing) {
      return res.status(409).json({ message: 'Email already in use' });
    }

    const user = await User.create({ name, email, password });
    return res.status(201).json({ message: 'User registered successfully', userId: user._id });
  } catch (err) {
    return res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// ── POST /api/users/login ─────────────────────────────────────────────────────
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ message: 'Email and password are required' });
    }

    const user = await User.findOne({ email });
    if (!user) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    const isMatch = await user.comparePassword(password);
    if (!isMatch) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    const tokenPayload = { id: user._id, email: user.email, role: user.role };

    // Short-lived access token (15 min) — returned in response body
    const accessToken = signAccessToken(tokenPayload);

    // Long-lived refresh token (7 days) — stored in httpOnly cookie ONLY
    const refreshToken = signRefreshToken({ id: user._id });
    res.cookie('refreshToken', refreshToken, REFRESH_COOKIE_OPTIONS);

    return res.json({
      accessToken,
      user: { id: user._id, name: user.name, email: user.email, role: user.role },
    });
  } catch (err) {
    return res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// ── POST /api/users/refresh ───────────────────────────────────────────────────
// Rotates the refresh token and issues a new access token
router.post('/refresh', async (req, res) => {
  const token = req.cookies?.refreshToken;
  if (!token) {
    return res.status(401).json({ message: 'No refresh token provided' });
  }

  try {
    const decoded = jwt.verify(token, PUBLIC_KEY, { algorithms: ['RS256'] });

    // Fetch user to ensure they still exist and are active
    const user = await User.findById(decoded.id).select('-password');
    if (!user) {
      return res.status(401).json({ message: 'User not found' });
    }

    // Issue new access token
    const newAccessToken = signAccessToken({ id: user._id, email: user.email, role: user.role });

    // Rotate refresh token (issue new one, clear old one)
    const newRefreshToken = signRefreshToken({ id: user._id });
    res.cookie('refreshToken', newRefreshToken, REFRESH_COOKIE_OPTIONS);

    return res.json({ accessToken: newAccessToken });
  } catch (err) {
    return res.status(401).json({ message: 'Invalid or expired refresh token' });
  }
});

// ── POST /api/users/logout ────────────────────────────────────────────────────
router.post('/logout', (_req, res) => {
  res.clearCookie('refreshToken', { path: '/api/users/refresh' });
  return res.json({ message: 'Logged out successfully' });
});

// ── GET /api/users/profile/:id ────────────────────────────────────────────────
router.get('/profile/:id', async (req, res) => {
  try {
    const user = await User.findById(req.params.id).select('-password');
    if (!user) return res.status(404).json({ message: 'User not found' });
    return res.json(user);
  } catch (err) {
    return res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// ── GET /api/users ────────────────────────────────────────────────────────────
router.get('/', async (_req, res) => {
  try {
    const users = await User.find().select('-password');
    return res.json(users);
  } catch (err) {
    return res.status(500).json({ message: 'Server error', error: err.message });
  }
});

module.exports = router;

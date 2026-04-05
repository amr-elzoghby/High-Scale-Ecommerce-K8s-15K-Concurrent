require('dotenv').config();
const express = require('express');
const cors    = require('cors');
const connectDB = require('./db');
const userRoutes = require('./routes/users');

const app  = express();
const PORT = process.env.PORT || 3001;

// ── Connect to MongoDB ────────────────────────────────────────────────────────
connectDB();

// ── Middleware ────────────────────────────────────────────────────────────────
app.use(cors());
app.use(express.json());

// ── Routes ────────────────────────────────────────────────────────────────────
app.use('/api/users', userRoutes);

// ── Health check ──────────────────────────────────────────────────────────────
app.get('/health', (_req, res) => res.json({ service: 'user-service', status: 'ok' }));

// ── Start ─────────────────────────────────────────────────────────────────────
app.listen(PORT, () => {
  console.log(`[User Service] Running on http://localhost:${PORT}`);
});

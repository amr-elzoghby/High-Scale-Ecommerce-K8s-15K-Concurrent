require('dotenv').config();
const express = require('express');
const cors    = require('cors');
const { connectRedis } = require('./db');
const cartRoutes = require('./routes/cart');

const app  = express();
const PORT = process.env.PORT || 3003;

connectRedis().then(() => {
  app.use(cors());
  app.use(express.json());
  app.use('/api/cart', cartRoutes);
  app.get('/health', (_req, res) => res.json({ service: 'cart-service', status: 'ok' }));

  app.listen(PORT, () => {
    console.log(`[Cart Service] Running on http://localhost:${PORT}`);
  });
}).catch(err => {
  console.error('[Cart Service] Failed to start:', err.message);
  process.exit(1);
});

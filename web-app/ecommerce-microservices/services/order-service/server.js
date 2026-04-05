

require('dotenv').config();
const express = require('express');
const cors    = require('cors');
const connectDB    = require('./db');
const orderRoutes  = require('./routes/orders');

const app  = express();
const PORT = process.env.PORT || 3004;

connectDB();

app.use(cors());
app.use(express.json());

app.use('/api/orders', orderRoutes);

app.get('/health', (_req, res) => res.json({ service: 'order-service', status: 'ok' }));

app.listen(PORT, () => {
  console.log(`[Order Service] Running on http://localhost:${PORT}`);
});

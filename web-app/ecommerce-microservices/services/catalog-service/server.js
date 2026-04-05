require('dotenv').config();
const express = require('express');
const cors    = require('cors');
const connectDB      = require('./db');
const productRoutes  = require('./routes/products');

const app  = express();
const PORT = process.env.PORT || 3002;

connectDB();

app.use(cors());
app.use(express.json());

app.use('/api/products', productRoutes);

app.get('/health', (_req, res) => res.json({ service: 'catalog-service', status: 'ok' }));

app.listen(PORT, () => {
  console.log(`[Catalog Service] Running on http://localhost:${PORT}`);
});

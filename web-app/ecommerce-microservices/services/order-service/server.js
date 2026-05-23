

require('dotenv').config();
const express = require('express');
const cors    = require('cors');
const connectDB    = require('./db');
const orderRoutes  = require('./routes/orders');
const { startGrpcServer } = require('./grpcServer');

const app  = express();
const PORT = process.env.PORT || 3004;
const GRPC_PORT = process.env.GRPC_PORT || 50052;

connectDB();

// Start gRPC server
startGrpcServer(GRPC_PORT);

app.use(cors());
app.use(express.json());

app.use('/api/orders', orderRoutes);

app.get('/health', (_req, res) => res.json({ service: 'order-service', status: 'ok' }));

app.listen(PORT, () => {
  console.log(`[Order Service] Running on http://localhost:${PORT}`);
});

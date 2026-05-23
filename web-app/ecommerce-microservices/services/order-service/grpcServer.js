const path = require('path');
const grpc = require('@grpc/grpc-js');
const protoLoader = require('@grpc/proto-loader');
const Order = require('./models/Order');

// Load protobuf
const PROTO_PATH = path.join(__dirname, 'order.proto');
const packageDefinition = protoLoader.loadSync(PROTO_PATH, {
  keepCase: true,
  longs: String,
  enums: String,
  defaults: true,
  oneofs: true,
});
const orderProto = grpc.loadPackageDefinition(packageDefinition).order;

// Helper: map Mongoose model to gRPC message
function mapOrder(order) {
  return {
    id: order._id.toString(),
    user_id: order.userId,
    items: (order.items || []).map(item => ({
      product_id: item.productId,
      name: item.name,
      price: Number(item.price),
      quantity: Number(item.quantity)
    })),
    total_amount: Number(order.totalAmount),
    shipping_address: order.shippingAddress,
    payment_id: order.paymentId,
    status: order.status,
    created_at: order.createdAt ? order.createdAt.toISOString() : new Date().toISOString()
  };
}

// gRPC Handlers
const grpcHandlers = {
  CreateOrder: async (call, callback) => {
    console.log('[gRPC Order Service] Creating order via gRPC:', call.request);
    const { user_id, items, total_amount, shipping_address, payment_id } = call.request;

    if (!user_id || !items || items.length === 0 || total_amount == null || !shipping_address || !payment_id) {
      return callback({
        code: grpc.status.INVALID_ARGUMENT,
        message: 'All fields (user_id, items, total_amount, shipping_address, payment_id) are required.'
      });
    }

    try {
      // Map proto items to mongoose schema items
      const mappedItems = items.map(item => ({
        productId: item.product_id,
        name: item.name,
        price: item.price,
        quantity: item.quantity
      }));

      const order = await Order.create({
        userId: user_id,
        items: mappedItems,
        totalAmount: total_amount,
        shippingAddress: shipping_address,
        paymentId: payment_id
      });

      console.log('[gRPC Order Service] Order created:', order._id);
      callback(null, mapOrder(order));
    } catch (err) {
      console.error('[gRPC Order Service] Error creating order:', err);
      callback({
        code: grpc.status.INTERNAL,
        message: `Database error: ${err.message}`
      });
    }
  },

  GetOrder: async (call, callback) => {
    const { id } = call.request;
    if (!id) {
      return callback({
        code: grpc.status.INVALID_ARGUMENT,
        message: 'Order ID is required.'
      });
    }

    try {
      const order = await Order.findById(id);
      if (!order) {
        return callback({
          code: grpc.status.NOT_FOUND,
          message: 'Order not found.'
        });
      }
      callback(null, mapOrder(order));
    } catch (err) {
      callback({
        code: grpc.status.INTERNAL,
        message: `Database error: ${err.message}`
      });
    }
  },

  GetUserOrders: async (call, callback) => {
    const { user_id } = call.request;
    if (!user_id) {
      return callback({
        code: grpc.status.INVALID_ARGUMENT,
        message: 'User ID is required.'
      });
    }

    try {
      const orders = await Order.find({ userId: user_id }).sort({ createdAt: -1 });
      callback(null, { orders: orders.map(mapOrder) });
    } catch (err) {
      callback({
        code: grpc.status.INTERNAL,
        message: `Database error: ${err.message}`
      });
    }
  }
};

function startGrpcServer(port = 50052) {
  const server = new grpc.Server();
  server.addService(orderProto.OrderService.service, grpcHandlers);
  server.bindAsync(`0.0.0.0:${port}`, grpc.ServerCredentials.createInsecure(), (err, boundPort) => {
    if (err) {
      console.error('[gRPC Order Service] Failed to start gRPC server:', err);
      return;
    }
    console.log(`[gRPC Order Service] gRPC server running on port ${boundPort}`);
  });
}

module.exports = { startGrpcServer };

const express = require('express');
const Order   = require('../models/Order');

const router = express.Router();

// ── POST /api/orders  (create order) ─────────────────────────────────────────
router.post('/', async (req, res) => {
  try {
    const { userId, items, totalAmount, shippingAddress, paymentId } = req.body;

    if (!userId || !items?.length || totalAmount == null || !shippingAddress || !paymentId) {
      return res.status(400).json({ message: 'All fields are required' });
    }

    const order = await Order.create({ userId, items, totalAmount, shippingAddress, paymentId });
    return res.status(201).json(order);
  } catch (err) {
    return res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// ── GET /api/orders/user/:userId  (get orders for a user) ────────────────────
router.get('/user/:userId', async (req, res) => {
  try {
    const orders = await Order.find({ userId: req.params.userId }).sort({ createdAt: -1 });
    return res.json(orders);
  } catch (err) {
    return res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// ── GET /api/orders/:id  (get single order) ───────────────────────────────────
router.get('/:id', async (req, res) => {
  try {
    const order = await Order.findById(req.params.id);
    if (!order) return res.status(404).json({ message: 'Order not found' });
    return res.json(order);
  } catch (err) {
    return res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// ── GET /api/orders  (admin: get all orders) ──────────────────────────────────
router.get('/', async (_req, res) => {
  try {
    const orders = await Order.find().sort({ createdAt: -1 });
    return res.json(orders);
  } catch (err) {
    return res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// ── PATCH /api/orders/:id/status  (update order status) ──────────────────────
router.patch('/:id/status', async (req, res) => {
  try {
    const { status } = req.body;
    const validStatuses = ['pending', 'paid', 'processing', 'shipped', 'delivered', 'cancelled'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({ message: `Invalid status. Must be one of: ${validStatuses.join(', ')}` });
    }
    const order = await Order.findByIdAndUpdate(req.params.id, { status }, { new: true });
    if (!order) return res.status(404).json({ message: 'Order not found' });
    return res.json(order);
  } catch (err) {
    return res.status(500).json({ message: 'Server error', error: err.message });
  }
});

module.exports = router;

const express = require('express');
const { getRedisClient } = require('../db');

const router = express.Router();

const CART_TTL = 60 * 60 * 24 * 7; // 7 days in seconds

// Helper: get cart from Redis
async function getCart(userId) {
  const client = getRedisClient();
  const data = await client.get(`cart:${userId}`);
  return data ? JSON.parse(data) : { userId, items: [] };
}

// Helper: save cart to Redis
async function saveCart(userId, cart) {
  const client = getRedisClient();
  await client.setEx(`cart:${userId}`, CART_TTL, JSON.stringify(cart));
}

// ── GET /api/cart/:userId ─────────────────────────────────────────────────────
router.get('/:userId', async (req, res) => {
  try {
    const cart = await getCart(req.params.userId);
    return res.json(cart);
  } catch (err) {
    return res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// ── POST /api/cart/:userId/add ────────────────────────────────────────────────
router.post('/:userId/add', async (req, res) => {
  try {
    const { productId, name, price, quantity = 1 } = req.body;

    if (!productId || !name || price == null) {
      return res.status(400).json({ message: 'productId, name, and price are required' });
    }

    const cart = await getCart(req.params.userId);
    const existingItem = cart.items.find(i => i.productId === productId);

    if (existingItem) {
      existingItem.quantity += quantity;
    } else {
      cart.items.push({ productId, name, price: Number(price), quantity });
    }

    await saveCart(req.params.userId, cart);
    return res.json(cart);
  } catch (err) {
    return res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// ── PUT /api/cart/:userId/update ──────────────────────────────────────────────
router.put('/:userId/update', async (req, res) => {
  try {
    const { productId, quantity } = req.body;
    if (!productId || quantity == null) {
      return res.status(400).json({ message: 'productId and quantity are required' });
    }

    const cart = await getCart(req.params.userId);
    const item = cart.items.find(i => i.productId === productId);

    if (!item) return res.status(404).json({ message: 'Item not found in cart' });
    item.quantity = quantity;

    await saveCart(req.params.userId, cart);
    return res.json(cart);
  } catch (err) {
    return res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// ── DELETE /api/cart/:userId/remove/:productId ────────────────────────────────
router.delete('/:userId/remove/:productId', async (req, res) => {
  try {
    const cart = await getCart(req.params.userId);
    cart.items = cart.items.filter(i => i.productId !== req.params.productId);
    await saveCart(req.params.userId, cart);
    return res.json(cart);
  } catch (err) {
    return res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// ── DELETE /api/cart/:userId/clear ────────────────────────────────────────────
router.delete('/:userId/clear', async (req, res) => {
  try {
    const client = getRedisClient();
    await client.del(`cart:${req.params.userId}`);
    return res.json({ message: 'Cart cleared' });
  } catch (err) {
    return res.status(500).json({ message: 'Server error', error: err.message });
  }
});

module.exports = router;

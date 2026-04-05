const express = require('express');
const Product = require('../models/Product');

const router = express.Router();

// ── GET /api/products  (list all, optional search & category filter) ───────────
router.get('/', async (req, res) => {
  try {
    const { search, category } = req.query;
    let filter = {};

    if (search) filter.$text = { $search: search };
    if (category) filter.category = new RegExp(category, 'i');

    const products = await Product.find(filter).sort({ createdAt: -1 });
    return res.json(products);
  } catch (err) {
    return res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// ── GET /api/products/:id ─────────────────────────────────────────────────────
router.get('/:id', async (req, res) => {
  try {
    const product = await Product.findById(req.params.id);
    if (!product) return res.status(404).json({ message: 'Product not found' });
    return res.json(product);
  } catch (err) {
    return res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// ── POST /api/products  (create) ──────────────────────────────────────────────
router.post('/', async (req, res) => {
  try {
    const { name, description, price, category, stock, imageUrl } = req.body;
    if (!name || !price || !category) {
      return res.status(400).json({ message: 'Name, price, and category are required' });
    }
    const product = await Product.create({ name, description, price, category, stock, imageUrl });
    return res.status(201).json(product);
  } catch (err) {
    return res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// ── PUT /api/products/:id  (update) ───────────────────────────────────────────
router.put('/:id', async (req, res) => {
  try {
    const product = await Product.findByIdAndUpdate(req.params.id, req.body, {
      new: true,
      runValidators: true,
    });
    if (!product) return res.status(404).json({ message: 'Product not found' });
    return res.json(product);
  } catch (err) {
    return res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// ── DELETE /api/products/:id ──────────────────────────────────────────────────
router.delete('/:id', async (req, res) => {
  try {
    const product = await Product.findByIdAndDelete(req.params.id);
    if (!product) return res.status(404).json({ message: 'Product not found' });
    return res.json({ message: 'Product deleted' });
  } catch (err) {
    return res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// ── POST /api/products/seed  (seed sample data) ───────────────────────────────
router.post('/seed', async (_req, res) => {
  try {
    await Product.deleteMany({});
    const sampleProducts = [
      { name: 'Wireless Noise-Cancelling Headphones', description: 'Premium sound with 30h battery', price: 199.99, category: 'Electronics', stock: 50 },
      { name: 'Mechanical Gaming Keyboard', description: 'RGB backlit, tactile switches', price: 89.99, category: 'Electronics', stock: 30 },
      { name: 'Running Shoes Pro', description: 'Lightweight, breathable mesh upper', price: 129.99, category: 'Sports', stock: 100 },
      { name: 'Classic Denim Jacket', description: 'Timeless style, comfortable fit', price: 59.99, category: 'Clothing', stock: 75 },
      { name: 'The Pragmatic Programmer', description: 'Must-read for every developer', price: 34.99, category: 'Books', stock: 200 },
      { name: 'Smart LED Desk Lamp', description: 'Adjustable brightness and color temp', price: 45.99, category: 'Home', stock: 60 },
      { name: 'Protein Powder Chocolate', description: '2kg, 25g protein per serving', price: 49.99, category: 'Food', stock: 80 },
      { name: '4K Action Camera', description: 'Waterproof, wide-angle lens', price: 249.99, category: 'Electronics', stock: 25 },
    ];
    await Product.insertMany(sampleProducts);
    return res.json({ message: `Seeded ${sampleProducts.length} products` });
  } catch (err) {
    return res.status(500).json({ message: 'Server error', error: err.message });
  }
});

module.exports = router;

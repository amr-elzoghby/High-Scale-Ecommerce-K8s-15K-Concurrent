const mongoose = require('mongoose');

const orderItemSchema = new mongoose.Schema({
  productId: { type: String, required: true },
  name:      { type: String, required: true },
  price:     { type: Number, required: true },
  quantity:  { type: Number, required: true, min: 1 },
});

const orderSchema = new mongoose.Schema({
  userId: {
    type: String,
    required: [true, 'UserId is required'],
    index: true,
  },
  items: {
    type: [orderItemSchema],
    validate: { validator: arr => arr.length > 0, message: 'Order must have at least one item' },
  },
  totalAmount: {
    type: Number,
    required: true,
    min: 0,
  },
  shippingAddress: {
    type: String,
    required: true,
  },
  paymentId: {
    type: String,
    required: true,
  },
  status: {
    type: String,
    enum: ['pending', 'paid', 'processing', 'shipped', 'delivered', 'cancelled'],
    default: 'paid',
  },
}, { timestamps: true });

module.exports = mongoose.model('Order', orderSchema);

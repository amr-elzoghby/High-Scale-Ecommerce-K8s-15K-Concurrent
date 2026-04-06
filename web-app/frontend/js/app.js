// ===== CONFIG: All API calls go through Nginx (reverse proxy) =====
// Nginx routes /api/users  → user-service:3001
//              /api/products → catalog-service:3002
//              /api/cart     → cart-service:3003
//              /api/payments → payment-service:3004
//              /api/orders   → order-service:3005
const API = {
  user:    '',   // → /api/users/...
  catalog: '',   // → /api/products/...
  cart:    '',   // → /api/cart/...
  payment: '',   // → /api/payments/...
  order:   '',   // → /api/orders/...
};

// ===== STATE =====
let currentUser = JSON.parse(localStorage.getItem('user')) || null;
let allProducts = [];

// ===== INIT =====
document.addEventListener('DOMContentLoaded', () => {
  updateAuthUI();
  showSection('catalog');
  loadProducts();
  document.getElementById('login-form').addEventListener('submit', handleLogin);
  document.getElementById('register-form').addEventListener('submit', handleRegister);
  document.getElementById('payment-form').addEventListener('submit', handlePlaceOrder);
});

// ===== SECTION NAVIGATION =====
function showSection(name) {
  document.querySelectorAll('main > section').forEach(s => s.classList.add('hidden'));
  const el = document.getElementById(`section-${name}`);
  if (el) {
    el.classList.remove('hidden');
    if (name === 'cart') loadCart();
    if (name === 'orders') loadOrders();
  }
}

// ===== AUTH UI =====
function updateAuthUI() {
  const navAuth = document.getElementById('nav-auth');
  const navUser = document.getElementById('nav-user');
  if (currentUser) {
    navAuth.classList.add('hidden');
    navUser.classList.remove('hidden');
    document.getElementById('username-display').textContent = `👤 ${currentUser.name}`;
  } else {
    navAuth.classList.remove('hidden');
    navUser.classList.add('hidden');
  }
}

// ===== REGISTER =====
async function handleRegister(e) {
  e.preventDefault();
  const name     = document.getElementById('reg-name').value.trim();
  const email    = document.getElementById('reg-email').value.trim();
  const password = document.getElementById('reg-password').value;

  try {
    const res = await fetch(`${API.user}/api/users/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name, email, password }),
    });
    const data = await res.json();
    if (!res.ok) throw new Error(data.message || 'Registration failed');
    showToast('Account created! Please login.', 'success');
    showSection('login');
  } catch (err) {
    showToast(err.message, 'error');
  }
}

// ===== LOGIN =====
async function handleLogin(e) {
  e.preventDefault();
  const email    = document.getElementById('login-email').value.trim();
  const password = document.getElementById('login-password').value;

  try {
    const res = await fetch(`${API.user}/api/users/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password }),
    });
    const data = await res.json();
    if (!res.ok) throw new Error(data.message || 'Login failed');
    currentUser = data.user;
    localStorage.setItem('user', JSON.stringify(currentUser));
    updateAuthUI();
    showToast(`Welcome back, ${currentUser.name}!`, 'success');
    showSection('catalog');
  } catch (err) {
    showToast(err.message, 'error');
  }
}

// ===== LOGOUT =====
function logout() {
  currentUser = null;
  localStorage.removeItem('user');
  updateAuthUI();
  updateCartBadge(0);
  showSection('catalog');
  showToast('Logged out.', 'success');
}

// ===== LOAD PRODUCTS =====
async function loadProducts() {
  try {
    const res = await fetch(`${API.catalog}/api/products`);
    const data = await res.json();
    allProducts = data;
    renderProducts(allProducts);
  } catch {
    document.getElementById('products-grid').innerHTML =
      '<p class="loading">⚠️ Could not load products. Is Catalog Service running?</p>';
  }
}

// product image map by category
const categoryImage = {
  electronics: 'images/electronics.png',
  clothing:    'images/clothing.png',
  books:       'images/books.png',
  food:        'images/food.png',
  sports:      'images/sports.png',
  home:        'images/home.png',
  default:     'images/default.png'
};

// star rating helper
function starRating(rating) {
  const r = Math.round((rating || 4.2) * 2) / 2;
  let stars = '';
  for (let i = 1; i <= 5; i++) {
    if (i <= Math.floor(r)) stars += '<span class="star full">★</span>';
    else if (i - 0.5 === r) stars += '<span class="star half">★</span>';
    else stars += '<span class="star empty">★</span>';
  }
  const count = Math.floor(Math.random() * 4000) + 200;
  return `<div class="product-stars">${stars}<span class="review-count">(${count.toLocaleString()})</span></div>`;
}

function renderProducts(products) {
  const grid = document.getElementById('products-grid');
  if (!products.length) {
    grid.innerHTML = '<p class="loading">No products found.</p>';
    return;
  }
  grid.innerHTML = products.map(p => {
    const imgSrc = categoryImage[p.category?.toLowerCase()] || categoryImage.default;
    const oldPrice = (Number(p.price) * 1.3).toFixed(2);
    return `
      <div class="product-card">
        <div class="product-img-wrap">
          <img src="${imgSrc}" alt="${escHtml(p.name)}" class="product-img" loading="lazy" />
          <span class="product-badge">In Stock</span>
        </div>
        <div class="product-info">
          <div class="product-category">${p.category || 'General'}</div>
          <div class="product-name">${p.name}</div>
          <div class="product-desc">${p.description || ''}</div>
          ${starRating(p.rating)}
          <div class="product-price-block">
            <span class="product-price">$${Number(p.price).toFixed(2)}</span>
            <span class="product-old-price">$${oldPrice}</span>
            <span class="product-discount">Save ${Math.round((1 - p.price / oldPrice) * 100)}%</span>
          </div>
          <div class="free-shipping">✅ FREE Delivery</div>
          <button class="btn btn-add-cart" onclick="addToCart('${p._id}', '${escHtml(p.name)}', ${p.price})">Add to Cart</button>
        </div>
      </div>`;
  }).join('');
}

function filterProducts() {
  const q = document.getElementById('search-input').value.toLowerCase();
  renderProducts(allProducts.filter(p =>
    p.name.toLowerCase().includes(q) || (p.category || '').toLowerCase().includes(q)
  ));
}

// ===== CART =====
async function addToCart(productId, name, price) {
  if (!currentUser) { showToast('Please login first.', 'error'); showSection('login'); return; }

  try {
    const res = await fetch(`${API.cart}/api/cart/${currentUser.id}/add`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ productId, name, price: 0, quantity: 1 }),
    });
    if (!res.ok) throw new Error('Could not add to cart');
    showToast(`${name} added to cart!`, 'success');
    await refreshCartCount();
  } catch (err) {
    showToast(err.message, 'error');
  }
}

async function loadCart() {
  if (!currentUser) {
    document.getElementById('cart-items').innerHTML = '';
    document.getElementById('cart-empty').classList.remove('hidden');
    document.getElementById('cart-summary').classList.add('hidden');
    return;
  }
  try {
    const res = await fetch(`${API.cart}/api/cart/${currentUser.id}`);
    const data = await res.json();
    renderCart(data.items || []);
  } catch {
    document.getElementById('cart-items').innerHTML =
      '<p class="loading">⚠️ Could not load cart. Is Cart Service running?</p>';
  }
}

function renderCart(items) {
  const container = document.getElementById('cart-items');
  const emptyMsg  = document.getElementById('cart-empty');
  const summary   = document.getElementById('cart-summary');

  if (!items.length) {
    container.innerHTML = '';
    emptyMsg.classList.remove('hidden');
    summary.classList.add('hidden');
    updateCartBadge(0);
    return;
  }
  emptyMsg.classList.add('hidden');
  summary.classList.remove('hidden');

  let total = 0;
  container.innerHTML = items.map(item => {
    total += item.price * item.quantity;
    const emoji = categoryEmoji.default;
    return `
      <div class="cart-item">
        <div class="cart-item-emoji">${emoji}</div>
        <div class="cart-item-info">
          <div class="cart-item-name">${item.name}</div>
          <div class="cart-item-price">$${Number(item.price).toFixed(2)} each</div>
        </div>
        <div class="cart-item-qty">
          <button class="qty-btn" onclick="changeQty('${item.productId}', ${item.quantity - 1})">−</button>
          <span class="qty-val">${item.quantity}</span>
          <button class="qty-btn" onclick="changeQty('${item.productId}', ${item.quantity + 1})">+</button>
        </div>
        <div style="font-weight:700;color:var(--accent);min-width:70px;text-align:right;">
          $${(item.price * item.quantity).toFixed(2)}
        </div>
        <button class="btn btn-danger btn-sm" onclick="removeFromCart('${item.productId}')">✕</button>
      </div>`;
  }).join('');

  document.getElementById('cart-total').textContent = total.toFixed(2);
  updateCartBadge(items.reduce((a, i) => a + i.quantity, 0));
}

async function changeQty(productId, newQty) {
  if (newQty <= 0) { await removeFromCart(productId); return; }
  try {
    await fetch(`${API.cart}/api/cart/${currentUser.id}/update`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ productId, quantity: newQty }),
    });
    loadCart();
  } catch (err) { showToast('Could not update quantity.', 'error'); }
}

async function removeFromCart(productId) {
  try {
    await fetch(`${API.cart}/api/cart/${currentUser.id}/remove/${productId}`, { method: 'DELETE' });
    loadCart();
  } catch (err) { showToast('Could not remove item.', 'error'); }
}

async function refreshCartCount() {
  if (!currentUser) return;
  try {
    const res = await fetch(`${API.cart}/api/cart/${currentUser.id}`);
    const data = await res.json();
    const total = (data.items || []).reduce((a, i) => a + i.quantity, 0);
    updateCartBadge(total);
  } catch { /* ignore */ }
}

function updateCartBadge(count) {
  document.getElementById('cart-count').textContent = count;
}

// ===== CHECKOUT =====
function checkout() {
  if (!currentUser) { showToast('Please login first.', 'error'); showSection('login'); return; }
  showSection('checkout');
}

async function handlePlaceOrder(e) {
  e.preventDefault();
  const address = document.getElementById('ship-address').value.trim();
  const city    = document.getElementById('ship-city').value.trim();
  const cardNum = document.getElementById('card-number').value.trim();
  const expiry  = document.getElementById('card-expiry').value.trim();
  const cvv     = document.getElementById('card-cvv').value.trim();

  try {
    // 1. Get cart
    const cartRes = await fetch(`${API.cart}/api/cart/${currentUser.id}`);
    const cartData = await cartRes.json();
    if (!cartData.items?.length) { showToast('Your cart is empty.', 'error'); return; }

    const totalAmount = 0;

    // 2. Process payment
    const payRes = await fetch(`${API.payment}/api/payments/process`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        userId: currentUser.id,
        amount: totalAmount,
        cardNumber: cardNum,
        cardExpiry: expiry,
        cardCvv: cvv,
      }),
    });
    const payData = await payRes.json();
    if (!payRes.ok) throw new Error(payData.message || 'Payment failed');

    // 3. Create order
    const orderRes = await fetch(`${API.order}/api/orders`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        userId: currentUser.id,
        items: cartData.items,
        totalAmount,
        shippingAddress: `${address}, ${city}`,
        paymentId: payData.paymentId,
      }),
    });
    if (!orderRes.ok) throw new Error('Could not create order');

    // 4. Clear cart
    await fetch(`${API.cart}/api/cart/${currentUser.id}/clear`, { method: 'DELETE' });
    updateCartBadge(0);

    showToast('🎉 Order placed successfully!', 'success');
    showSection('orders');
  } catch (err) {
    showToast(err.message, 'error');
  }
}

// ===== ORDERS =====
async function loadOrders() {
  if (!currentUser) {
    document.getElementById('orders-list').innerHTML = '';
    document.getElementById('orders-empty').classList.remove('hidden');
    return;
  }
  try {
    const res = await fetch(`${API.order}/api/orders/user/${currentUser.id}`);
    const data = await res.json();
    renderOrders(data);
  } catch {
    document.getElementById('orders-list').innerHTML =
      '<p class="loading">⚠️ Could not load orders. Is Order Service running?</p>';
  }
}

function renderOrders(orders) {
  const list = document.getElementById('orders-list');
  const empty = document.getElementById('orders-empty');
  if (!orders.length) {
    list.innerHTML = '';
    empty.classList.remove('hidden');
    return;
  }
  empty.classList.add('hidden');
  list.innerHTML = orders.map(o => `
    <div class="order-card">
      <div class="order-header">
        <div class="order-id">Order #${o._id.slice(-8).toUpperCase()}</div>
        <span class="order-status status-${o.status.toLowerCase()}">${o.status}</span>
      </div>
      <div class="order-items">${o.items.map(i => `${i.name} × ${i.quantity}`).join(' · ')}</div>
      <div style="display:flex;justify-content:space-between;align-items:center;margin-top:0.75rem;">
        <div class="order-date">${new Date(o.createdAt).toLocaleDateString()}</div>
        <div class="order-total">$${Number(o.totalAmount).toFixed(2)}</div>
      </div>
    </div>`).join('');
}

// ===== TOAST =====
function showToast(msg, type = 'success') {
  const toast = document.getElementById('toast');
  toast.textContent = type === 'success' ? `✅ ${msg}` : `❌ ${msg}`;
  toast.className = `toast ${type}`;
  setTimeout(() => toast.classList.add('hidden'), 3500);
}

// ===== HELPERS =====
function escHtml(str) {
  return str.replace(/[&<>"']/g, c =>
    ({ '&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;' }[c])
  );
}

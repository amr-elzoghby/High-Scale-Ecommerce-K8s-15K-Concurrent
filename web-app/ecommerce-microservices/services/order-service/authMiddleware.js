const jwt = require('jsonwebtoken');

/**
 * Stateless RS256 JWT Verification Middleware
 *
 * - Reads the Bearer token from the Authorization header.
 * - Verifies the signature using the RSA PUBLIC KEY only (no DB call).
 * - Sets req.user = { id, email, role } on success.
 * - Returns 401 on missing/invalid/expired tokens.
 */
const PUBLIC_KEY = (process.env.JWT_PUBLIC_KEY || '').replace(/\\n/g, '\n');

function authMiddleware(req, res, next) {
  const authHeader = req.headers['authorization'];

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ message: 'Unauthorized: No token provided' });
  }

  const token = authHeader.split(' ')[1];

  try {
    // Verify using RS256 public key — zero DB calls, fully stateless
    const decoded = jwt.verify(token, PUBLIC_KEY, { algorithms: ['RS256'] });
    req.user = { id: decoded.id, email: decoded.email, role: decoded.role };
    next();
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return res.status(401).json({ message: 'Unauthorized: Token expired' });
    }
    return res.status(401).json({ message: 'Unauthorized: Invalid token' });
  }
}

module.exports = authMiddleware;

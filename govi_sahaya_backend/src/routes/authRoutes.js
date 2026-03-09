// routes/authRoutes.js
const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');

const User = require('../models/User');
const {
  register,
  login,
  logout,
  forgotPassword,
  resetPassword,
  verifyEmail,
  changePassword,
  firebaseLogin,
  firebaseSync,
} = require('../controllers/authController');
const { protect } = require('../middleware/authMiddleware');
const { authLimiter } = require('../middleware/rateLimiter');
const emailService = require('../services/emailService');
const authService = require('../services/authService');

// ── Public routes ───────────────────────────────────────────────
router.post('/register', authLimiter, register);
router.post('/login', authLimiter, login);
router.post('/firebase-login', authLimiter, firebaseLogin);
router.post('/firebase-sync', firebaseSync);
router.post('/forgot-password', authLimiter, forgotPassword);

// HTML page when user clicks reset link in email
router.get('/reset-password/:token', (req, res) => {
  const { token } = req.params;

  const html = `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <title>Reset Password - Govi Sahaya</title>
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: Arial, Helvetica, sans-serif;
      background: linear-gradient(135deg, #e3f2fd, #e8f5e9);
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 20px;
    }
    .card {
      background: #ffffff;
      border-radius: 16px;
      box-shadow: 0 16px 40px rgba(0,0,0,0.12);
      padding: 32px 28px;
      max-width: 420px;
      width: 100%;
    }
    h1 {
      font-size: 24px;
      color: #1E4D2E;
      margin-bottom: 8px;
      text-align: center;
    }
    p.subtitle {
      font-size: 14px;
      color: #666666;
      margin-bottom: 24px;
      text-align: center;
      line-height: 1.6;
    }
    label {
      display: block;
      font-size: 13px;
      color: #37474F;
      margin-bottom: 6px;
    }
    input {
      width: 100%;
      padding: 10px 12px;
      border-radius: 8px;
      border: 1px solid #cfd8dc;
      font-size: 14px;
      margin-bottom: 14px;
    }
    button {
      width: 100%;
      padding: 12px 16px;
      border: none;
      border-radius: 10px;
      background: linear-gradient(135deg, #2D6B42, #4CAF50);
      color: #ffffff;
      font-size: 15px;
      font-weight: 700;
      cursor: pointer;
      margin-top: 4px;
    }
    .message {
      margin-top: 14px;
      font-size: 13px;
      text-align: center;
    }
    .message.success { color: #2E7D32; }
    .message.error { color: #C62828; }
  </style>
</head>
<body>
  <div class="card">
    <h1>Reset your password</h1>
    <p class="subtitle">
      Enter a new password for your Govi Sahaya account.
    </p>
    <form id="resetForm">
      <label for="password">New password</label>
      <input id="password" type="password" required minlength="8" />
      <label for="confirm">Confirm password</label>
      <input id="confirm" type="password" required minlength="8" />
      <button type="submit">Update Password</button>
      <div id="msg" class="message"></div>
    </form>
  </div>

  <script>
    const form = document.getElementById('resetForm');
    const msg = document.getElementById('msg');
    const token = ${JSON.stringify(token)};

    form.addEventListener('submit', async (e) => {
      e.preventDefault();
      msg.textContent = '';
      msg.className = 'message';

      const pwd = document.getElementById('password').value.trim();
      const confirm = document.getElementById('confirm').value.trim();

      if (pwd.length < 8) {
        msg.textContent = 'Password must be at least 8 characters.';
        msg.className = 'message error';
        return;
      }
      if (pwd !== confirm) {
        msg.textContent = 'Passwords do not match.';
        msg.className = 'message error';
        return;
      }

      try {
        const res = await fetch(window.location.origin + '/api/v1/auth/reset-password/' + token, {
          method: 'PUT',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ password: pwd }),
        });

        const data = await res.json().catch(() => ({}));

        if (res.ok) {
          msg.textContent = data.message || 'Password reset successful. You can close this tab and log in in the app.';
          msg.className = 'message success';
          form.querySelector('button').disabled = true;
        } else {
          msg.textContent = data.message || 'Failed to reset password. The link may be expired.';
          msg.className = 'message error';
        }
      } catch (err) {
        msg.textContent = 'Network error. Please try again.';
        msg.className = 'message error';
      }
    });
  </script>
</body>
</html>`;

  res.status(200).send(html);
});

// API endpoint used by the HTML form
router.put('/reset-password/:token', resetPassword);

router.get('/verify-email/:token', verifyEmail);

// Resend verification email (used by Flutter resendVerificationEmail)
router.post('/resend-verification', async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({
        success: false,
        message: 'Email is required',
      });
    }

    const user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    if (user.isVerified) {
      return res.status(400).json({
        success: false,
        message: 'Email is already verified',
      });
    }

    const verificationToken =
      authService.generateEmailVerificationToken(user._id);

    await emailService.sendVerificationEmail(user, verificationToken);

    res.status(200).json({
      success: true,
      message: 'Verification email resent',
    });
  } catch (err) {
    console.error('Resend verification error:', err);
    res.status(500).json({
      success: false,
      message: 'Failed to resend verification email',
    });
  }
});

// ── Refresh token endpoint (used by BackendAuthService) ─────────
router.post('/refresh', async (req, res) => {
  try {
    const { refreshToken } = req.body;

    if (!refreshToken) {
      return res.status(400).json({
        success: false,
        message: 'Refresh token is required',
      });
    }

    const decoded = jwt.verify(
      refreshToken,
      process.env.JWT_REFRESH_SECRET || process.env.JWT_SECRET
    );

    const user = await User.findById(decoded.id);
    if (!user || !user.isActive) {
      return res.status(401).json({
        success: false,
        message: 'Invalid or expired refresh token',
      });
    }

    const newAccessToken = jwt.sign(
      { id: user._id },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
    );

    res.status(200).json({
      success: true,
      token: newAccessToken,
      accessToken: newAccessToken,
      expiresIn: process.env.JWT_EXPIRES_IN || '7d',
    });
  } catch (err) {
    console.error('Refresh token error:', err);
    res.status(401).json({
      success: false,
      message: 'Invalid or expired refresh token',
    });
  }
});

// ── Protected routes ────────────────────────────────────────────
router.post('/logout', protect, logout);
router.put('/change-password', protect, changePassword);

module.exports = router;

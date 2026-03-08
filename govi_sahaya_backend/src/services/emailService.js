// services/emailService.js
const nodemailer = require('nodemailer');
const logger = require('../utils/logger');
const { EMAIL } = require('../config/constants');

// Base URLs — change only in .env, no code change needed
const APP_URL = process.env.APP_URL || 'http://localhost:5000';
const FRONTEND_URL = process.env.FRONTEND_URL || APP_URL;

// ── Transporter (Gmail SMTP) ──────────────────────────────────────
const createTransporter = () => {
  return nodemailer.createTransport({
    host: process.env.EMAIL_HOST || 'smtp.gmail.com',
    port: parseInt(process.env.EMAIL_PORT, 10) || 587,
    secure: false,
    auth: {
      user: process.env.EMAIL_USER,
      pass: process.env.EMAIL_PASSWORD,
    },
  });
};

// ── Startup SMTP connection test ──────────────────────────────────
(async () => {
  try {
    logger.info('📧 SMTP config loaded:');
    logger.info(`   HOST: ${process.env.EMAIL_HOST}`);
    logger.info(`   PORT: ${process.env.EMAIL_PORT}`);
    logger.info(`   USER: ${process.env.EMAIL_USER}`);
    logger.info(`   FROM: ${process.env.EMAIL_USER}`);
    logger.info(`   PASS: ${process.env.EMAIL_PASSWORD ? '*** (set)' : '❌ NOT SET'}`);

    const transporter = createTransporter();
    await transporter.verify();
    logger.info('✅ SMTP connection OK — Gmail is ready to send emails');
  } catch (err) {
    logger.error('❌ SMTP connection FAILED at startup:', err.message);
    logger.error('   Fix EMAIL_USER / EMAIL_PASSWORD in .env and restart Node');
  }
})();

// ── Base sender ───────────────────────────────────────────────────
exports.sendEmail = async (options) => {
  try {
    const transporter = createTransporter();
    await transporter.verify();

    const mailOptions = {
      // Gmail forces from = authenticated user — EMAIL_USER is always used
      from: `${process.env.APP_NAME || 'Govi Sahaya'} <${process.env.EMAIL_USER}>`,
      to: options.to,
      subject: options.subject,
      text: options.text,
      html: options.html,
      attachments: options.attachments,
    };

    const info = await transporter.sendMail(mailOptions);
    logger.info('Email sent successfully:', info.messageId);

    return { success: true, messageId: info.messageId };
  } catch (error) {
    logger.error('Send email error:', error);
    throw new Error('Failed to send email');
  }
};

// ── Shared layout / helpers (INLINE STYLES – safe for email) ─────
const wrapLayout = (headerColor, headerContent, bodyContent) => `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Govi Sahaya</title>
</head>
<body style="margin:0;padding:0;background-color:#f0f4f0;font-family:Arial,Helvetica,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background-color:#f0f4f0;padding:30px 0;">
    <tr>
      <td align="center">
        <table width="600" cellpadding="0" cellspacing="0"
          style="max-width:600px;width:100%;background-color:#ffffff;border-radius:12px;
                 overflow:hidden;box-shadow:0 4px 20px rgba(0,0,0,0.10);">
          <tr>
            <td style="background-color:${headerColor};padding:32px 40px;text-align:center;">
              ${headerContent}
            </td>
          </tr>
          <tr>
            <td style="padding:36px 40px;background-color:#ffffff;">
              ${bodyContent}
            </td>
          </tr>
          <tr>
            <td style="background-color:#f8faf8;padding:20px 40px;text-align:center;
                        border-top:1px solid #e8f0e9;">
              <p style="margin:0 0 4px 0;font-size:12px;color:#888888;">
                &copy; 2026 Govi Sahaya. All rights reserved.
              </p>
              <p style="margin:0;font-size:12px;color:#aaaaaa;">
                Smart Agriculture Advisor Platform
              </p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>`;

const actionButton = (url, label, color) => `
  <table width="100%" cellpadding="0" cellspacing="0" style="margin:24px 0;">
    <tr>
      <td align="center">
        <a href="${url}"
           style="display:inline-block;padding:14px 36px;background-color:${color};
                  color:#ffffff;text-decoration:none;border-radius:8px;
                  font-size:15px;font-weight:bold;letter-spacing:0.3px;">
          ${label}
        </a>
      </td>
    </tr>
  </table>`;

const linkFallback = (url) => `
  <p style="font-size:12px;color:#888888;margin:12px 0 0 0;">
    Or copy and paste this link into your browser:<br/>
    <a href="${url}" style="color:#2D6B42;word-break:break-all;">${url}</a>
  </p>`;

// ── Verification email ────────────────────────────────────────────
exports.sendVerificationEmail = async (user, token) => {
  try {
    const verificationUrl = `${APP_URL}/api/v1/auth/verify-email/${token}`;
    logger.info(`Verification URL: ${verificationUrl}`);

    const header = `
      <h1 style="margin:0;color:#ffffff;font-size:26px;font-weight:700;
                 letter-spacing:0.5px;">🌾 Govi Sahaya</h1>
      <p style="margin:8px 0 0 0;color:rgba(255,255,255,0.85);font-size:14px;">
        Smart Agriculture Advisor Platform
      </p>`;

    const body = `
      <h2 style="margin:0 0 8px 0;color:#1E4D2E;font-size:22px;">
        Welcome, ${user.name}! 👋
      </h2>
      <p style="margin:0 0 20px 0;color:#555555;font-size:15px;line-height:1.7;">
        Thank you for registering with Govi Sahaya. Please verify your email
        address to activate your account and start your smart farming journey.
      </p>
      ${actionButton(verificationUrl, 'Verify My Email', '#2D6B42')}
      ${linkFallback(verificationUrl)}
      <p style="margin:20px 0 0 0;font-size:13px;color:#999999;">
        ⏳ This link will expire in <strong>24 hours</strong>.
      </p>
      <p style="margin:8px 0 0 0;font-size:13px;color:#999999;">
        If you didn't create an account, you can safely ignore this email.
      </p>`;

    return await exports.sendEmail({
      to: user.email,
      subject: 'Verify Your Email - Govi Sahaya',
      html: wrapLayout('#2D6B42', header, body),
    });
  } catch (error) {
    logger.error('Send verification email error:', error);
    throw error;
  }
};

// ── Welcome email (after verify) ──────────────────────────────────
exports.sendWelcomeEmail = async (user) => {
  try {
    const feature = (icon, title, desc) => `
      <tr>
        <td style="padding:10px 0;">
          <table width="100%" cellpadding="0" cellspacing="0">
            <tr>
              <td width="48" valign="top">
                <div style="width:40px;height:40px;background-color:#e8f5e9;
                            border-radius:10px;text-align:center;line-height:40px;
                            font-size:20px;">
                  ${icon}
                </div>
              </td>
              <td style="padding-left:12px;" valign="top">
                <p style="margin:0 0 2px 0;font-size:14px;font-weight:700;color:#1E4D2E;">
                  ${title}
                </p>
                <p style="margin:0;font-size:13px;color:#666666;line-height:1.5;">
                  ${desc}
                </p>
              </td>
            </tr>
          </table>
        </td>
      </tr>`;

    const header = `
      <h1 style="margin:0;color:#ffffff;font-size:26px;font-weight:700;">
        🌾 Welcome to Govi Sahaya!
      </h1>
      <p style="margin:8px 0 0 0;color:rgba(255,255,255,0.85);font-size:14px;">
        Your account is now active
      </p>`;

    const body = `
      <h2 style="margin:0 0 8px 0;color:#1E4D2E;font-size:22px;">
        Hello, ${user.name}! 🎉
      </h2>
      <p style="margin:0 0 24px 0;color:#555555;font-size:15px;line-height:1.7;">
        Your email has been verified. You are now part of the Govi Sahaya community —
        here is what you can explore:
      </p>

      <table width="100%" cellpadding="0" cellspacing="0"
        style="background-color:#f8faf8;border-radius:10px;padding:16px 20px;
               border:1px solid #e2ede3;">
        <tbody>
          ${feature('🔬', 'Crop Doctor', 'Detect crop diseases using AI-powered image recognition.')}
          ${feature('☁️', 'Weather Updates', 'Get real-time weather forecasts for your location.')}
          ${feature('📚', 'Knowledge Hub', 'Access expert guides and farming best practices.')}
          ${feature('💰', 'Profit Planner', 'Track expenses and manage your farm finances.')}
          ${feature('🛒', 'Shop', 'Buy quality seeds, fertilizers, and farming equipment.')}
          ${feature('💬', 'Community Forum', 'Connect with other farmers and share experiences.')}
        </tbody>
      </table>

      <p style="margin:16px 0 0 0;font-size:13px;color:#888888;">
        Need help? Contact us at
        <a href="mailto:${EMAIL.SUPPORT}"
           style="color:#2D6B42;text-decoration:none;">${EMAIL.SUPPORT}</a>
      </p>`;

    return await exports.sendEmail({
      to: user.email,
      subject: 'Welcome to Govi Sahaya! 🌾',
      html: wrapLayout('#2D6B42', header, body),
    });
  } catch (error) {
    logger.error('Send welcome email error:', error);
    throw error;
  }
};

// ── Password reset email ──────────────────────────────────────────
exports.sendPasswordResetEmail = async (user, resetToken) => {
  try {
    const resetUrl = `${APP_URL}/api/v1/auth/reset-password/${resetToken}`;
    logger.info(`Reset URL: ${resetUrl}`);

    const header = `
      <h1 style="margin:0;color:#ffffff;font-size:22px;font-weight:700;">
        🔐 Password Reset Request
      </h1>`;

    const body = `
      <h2 style="margin:0 0 8px 0;color:#B71C1C;font-size:20px;">
        Hello, ${user.name}
      </h2>
      <p style="margin:0 0 20px 0;color:#555555;font-size:15px;line-height:1.7;">
        We received a request to reset your password for your Govi Sahaya account.
        Click the button below to reset it.
      </p>

      ${actionButton(resetUrl, 'Reset My Password', '#D32F2F')}

      <table width="100%" cellpadding="0" cellspacing="0"
        style="background-color:#fff8e1;border-left:4px solid #FFC107;
               border-radius:4px;margin:20px 0;">
        <tr>
          <td style="padding:14px 16px;font-size:13px;color:#555555;line-height:1.6;">
            ⚠️ <strong>This link will expire in 1 hour</strong> for security reasons.<br/>
            If you did not request a password reset, please ignore this email.
          </td>
        </tr>
      </table>

      ${linkFallback(resetUrl)}`;

    return await exports.sendEmail({
      to: user.email,
      subject: 'Password Reset Request - Govi Sahaya',
      html: wrapLayout('#C62828', header, body),
    });
  } catch (error) {
    logger.error('Send password reset email error:', error);
    throw error;
  }
};

// ── Order confirmation email ──────────────────────────────────────
exports.sendOrderConfirmationEmail = async (user, order) => {
  try {
    const itemsList = order.items
      .map(
        (item) => `
        <tr>
          <td style="padding:10px 0;font-size:14px;color:#333333;
                     border-bottom:1px solid #f0f0f0;">${item.name}</td>
          <td style="padding:10px 0;font-size:14px;color:#333333;
                     text-align:center;border-bottom:1px solid #f0f0f0;">${item.quantity}</td>
          <td style="padding:10px 0;font-size:14px;color:#333333;
                     text-align:right;border-bottom:1px solid #f0f0f0;">
            Rs. ${item.subtotal.toFixed(2)}
          </td>
        </tr>`
      )
      .join('');

    const header = `
      <h1 style="margin:0;color:#ffffff;font-size:24px;font-weight:700;">
        ✅ Order Confirmed!
      </h1>
      <p style="margin:8px 0 0 0;color:rgba(255,255,255,0.85);font-size:14px;">
        Order #${order.orderNumber}
      </p>`;

    const addr = order.shippingAddress;

    const body = `
      <h2 style="margin:0 0 6px 0;color:#1565C0;font-size:20px;">
        Thank you, ${user.name}!
      </h2>
      <p style="margin:0 0 24px 0;font-size:14px;color:#555555;">
        Order Date: <strong>${new Date(order.createdAt).toLocaleDateString()}</strong>
      </p>

      <table width="100%" cellpadding="0" cellspacing="0"
        style="border:1px solid #e0e0e0;border-radius:8px;overflow:hidden;margin-bottom:24px;">
        <thead>
          <tr style="background-color:#e3f2fd;">
            <th style="padding:12px;text-align:left;font-size:13px;color:#1565C0;">Item</th>
            <th style="padding:12px;text-align:center;font-size:13px;color:#1565C0;">Qty</th>
            <th style="padding:12px;text-align:right;font-size:13px;color:#1565C0;">Subtotal</th>
          </tr>
        </thead>
        <tbody>
          ${itemsList}
          <tr style="background-color:#f5f5f5;">
            <td colspan="2" style="padding:12px;font-size:15px;font-weight:700;color:#1565C0;">Total</td>
            <td style="padding:12px;font-size:15px;font-weight:700;color:#1565C0;text-align:right;">
              Rs. ${order.totalAmount.toFixed(2)}
            </td>
          </tr>
        </tbody>
      </table>

      <table width="100%" cellpadding="0" cellspacing="0"
        style="background-color:#f8f9ff;border-radius:8px;border:1px solid #e0e8ff;margin-bottom:16px;">
        <tr>
          <td style="padding:16px 20px;">
            <p style="margin:0 0 8px 0;font-size:13px;font-weight:700;
                      color:#1565C0;text-transform:uppercase;letter-spacing:0.5px;">
              Shipping Address
            </p>
            <p style="margin:0;font-size:14px;color:#444444;line-height:1.7;">
              ${addr.name}<br/>
              ${addr.addressLine1}<br/>
              ${addr.addressLine2 ? addr.addressLine2 + '<br/>' : ''}
              ${addr.city}<br/>
              ${addr.postalCode || ''}
            </p>
          </td>
        </tr>
      </table>

      <p style="margin:0;font-size:14px;color:#555555;">
        <strong>Payment Method:</strong>
        ${order.paymentMethod.replace('_', ' ').toUpperCase()}
      </p>
      <p style="margin:12px 0 0 0;font-size:13px;color:#888888;">
        We'll send you another email when your order ships.
      </p>`;

    return await exports.sendEmail({
      to: user.email,
      subject: `Order Confirmation - ${order.orderNumber}`,
      html: wrapLayout('#1565C0', header, body),
    });
  } catch (error) {
    logger.error('Send order confirmation email error:', error);
    throw error;
  }
};

// ── Notification email ────────────────────────────────────────────
exports.sendNotificationEmail = async (user, notification) => {
  try {
    const header = `
      <h1 style="margin:0;color:#ffffff;font-size:22px;font-weight:700;">
        🔔 New Notification
      </h1>`;

    const body = `
      <h2 style="margin:0 0 16px 0;color:#6A1B9A;font-size:20px;">
        Hello, ${user.name}
      </h2>
      <table width="100%" cellpadding="0" cellspacing="0"
        style="background-color:#f9f4ff;border-left:4px solid #9C27B0;border-radius:4px;">
        <tr>
          <td style="padding:20px 24px;">
            <p style="margin:0 0 8px 0;font-size:16px;font-weight:700;color:#4A148C;">
              ${notification.title}
            </p>
            <p style="margin:0;font-size:14px;color:#555555;line-height:1.7;">
              ${notification.message}
            </p>
          </td>
        </tr>
      </table>`;

    return await exports.sendEmail({
      to: user.email,
      subject: notification.title,
      html: wrapLayout('#7B1FA2', header, body),
    });
  } catch (error) {
    logger.error('Send notification email error:', error);
    throw error;
  }
};

// ── Bulk emails ───────────────────────────────────────────────────
exports.sendBulkEmails = async (recipients, subject, html) => {
  try {
    const promises = recipients.map((recipient) =>
      exports
        .sendEmail({
          to: recipient.email,
          subject,
          html: html.replace('{{name}}', recipient.name),
        })
        .catch((err) => {
          logger.error(`Failed to send email to ${recipient.email}:`, err);
          return { success: false, email: recipient.email };
        })
    );

    const results = await Promise.all(promises);
    const successful = results.filter((r) => r.success).length;
    const failed = results.filter((r) => !r.success).length;

    logger.info(`Bulk email sent: ${successful} successful, ${failed} failed`);
    return { successful, failed, results };
  } catch (error) {
    logger.error('Send bulk emails error:', error);
    throw error;
  }
};

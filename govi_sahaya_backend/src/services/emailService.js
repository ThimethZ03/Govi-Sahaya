const nodemailer = require('nodemailer');
const logger = require('../utils/logger');
const { EMAIL } = require('../config/constants');

// Create email transporter
const createTransporter = () => {
  return nodemailer.createTransport({
    host: process.env.EMAIL_HOST || 'smtp.gmail.com',
    port: process.env.EMAIL_PORT || 587,
    secure: false, // true for 465, false for other ports
    auth: {
      user: process.env.EMAIL_USER,
      pass: process.env.EMAIL_PASSWORD,
    },
  });
};

// Send email
exports.sendEmail = async (options) => {
  try {
    const transporter = createTransporter();

    const mailOptions = {
      from: `${process.env.APP_NAME || 'Govi Sahaya'} <${EMAIL.FROM}>`,
      to: options.to,
      subject: options.subject,
      text: options.text,
      html: options.html,
      attachments: options.attachments,
    };

    const info = await transporter.sendMail(mailOptions);

    logger.info('Email sent successfully:', info.messageId);
    return {
      success: true,
      messageId: info.messageId,
    };
  } catch (error) {
    logger.error('Send email error:', error);
    throw new Error('Failed to send email');
  }
};

// Send verification email
exports.sendVerificationEmail = async (user, token) => {
  try {
    const verificationUrl = `${process.env.FRONTEND_URL}/verify-email/${token}`;

    const html = `
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background-color: #4CAF50; color: white; padding: 20px; text-align: center; }
          .content { background-color: #f9f9f9; padding: 30px; }
          .button { 
            display: inline-block; 
            padding: 12px 30px; 
            background-color: #4CAF50; 
            color: white; 
            text-decoration: none; 
            border-radius: 5px;
            margin: 20px 0;
          }
          .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>Govi Sahaya</h1>
          </div>
          <div class="content">
            <h2>Welcome, ${user.name}!</h2>
            <p>Thank you for registering with Govi Sahaya. Please verify your email address to activate your account.</p>
            <p>Click the button below to verify your email:</p>
            <center>
              <a href="${verificationUrl}" class="button">Verify Email</a>
            </center>
            <p>Or copy and paste this link into your browser:</p>
            <p>${verificationUrl}</p>
            <p>This link will expire in 24 hours.</p>
            <p>If you didn't create an account, please ignore this email.</p>
          </div>
          <div class="footer">
            <p>&copy; 2026 Govi Sahaya. All rights reserved.</p>
            <p>Smart Agriculture Advisor Platform</p>
          </div>
        </div>
      </body>
      </html>
    `;

    return await this.sendEmail({
      to: user.email,
      subject: 'Verify Your Email - Govi Sahaya',
      html,
    });
  } catch (error) {
    logger.error('Send verification email error:', error);
    throw error;
  }
};

// Send password reset email
exports.sendPasswordResetEmail = async (user, resetToken) => {
  try {
    const resetUrl = `${process.env.FRONTEND_URL}/reset-password/${resetToken}`;

    const html = `
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background-color: #FF5722; color: white; padding: 20px; text-align: center; }
          .content { background-color: #f9f9f9; padding: 30px; }
          .button { 
            display: inline-block; 
            padding: 12px 30px; 
            background-color: #FF5722; 
            color: white; 
            text-decoration: none; 
            border-radius: 5px;
            margin: 20px 0;
          }
          .warning { 
            background-color: #fff3cd; 
            border-left: 4px solid #ffc107; 
            padding: 15px; 
            margin: 20px 0;
          }
          .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>Password Reset Request</h1>
          </div>
          <div class="content">
            <h2>Hello, ${user.name}</h2>
            <p>We received a request to reset your password for your Govi Sahaya account.</p>
            <p>Click the button below to reset your password:</p>
            <center>
              <a href="${resetUrl}" class="button">Reset Password</a>
            </center>
            <p>Or copy and paste this link into your browser:</p>
            <p>${resetUrl}</p>
            <div class="warning">
              <strong>⚠️ Important:</strong> This link will expire in 1 hour for security reasons.
            </div>
            <p>If you didn't request a password reset, please ignore this email or contact support if you have concerns.</p>
          </div>
          <div class="footer">
            <p>&copy; 2026 Govi Sahaya. All rights reserved.</p>
          </div>
        </div>
      </body>
      </html>
    `;

    return await this.sendEmail({
      to: user.email,
      subject: 'Password Reset Request - Govi Sahaya',
      html,
    });
  } catch (error) {
    logger.error('Send password reset email error:', error);
    throw error;
  }
};

// Send welcome email
exports.sendWelcomeEmail = async (user) => {
  try {
    const html = `
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background-color: #4CAF50; color: white; padding: 20px; text-align: center; }
          .content { background-color: #f9f9f9; padding: 30px; }
          .feature { 
            background-color: white; 
            padding: 15px; 
            margin: 10px 0; 
            border-radius: 5px;
            border-left: 4px solid #4CAF50;
          }
          .button { 
            display: inline-block; 
            padding: 12px 30px; 
            background-color: #4CAF50; 
            color: white; 
            text-decoration: none; 
            border-radius: 5px;
            margin: 20px 0;
          }
          .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>Welcome to Govi Sahaya! 🌾</h1>
          </div>
          <div class="content">
            <h2>Hello, ${user.name}!</h2>
            <p>Thank you for joining Govi Sahaya - Your Smart Agriculture Advisor Platform.</p>
            
            <h3>What You Can Do:</h3>
            
            <div class="feature">
              <strong>🔬 Crop Doctor</strong>
              <p>Detect crop diseases using AI-powered image recognition.</p>
            </div>
            
            <div class="feature">
              <strong>☁️ Weather Updates</strong>
              <p>Get real-time weather forecasts for your location.</p>
            </div>
            
            <div class="feature">
              <strong>📚 Knowledge Hub</strong>
              <p>Access expert guides and farming best practices.</p>
            </div>
            
            <div class="feature">
              <strong>💰 Profit Planner</strong>
              <p>Track expenses and manage your farm finances.</p>
            </div>
            
            <div class="feature">
              <strong>🛒 Shop</strong>
              <p>Buy quality seeds, fertilizers, and farming equipment.</p>
            </div>
            
            <div class="feature">
              <strong>💬 Community Forum</strong>
              <p>Connect with other farmers and share experiences.</p>
            </div>
            
            <center>
              <a href="${process.env.FRONTEND_URL}/dashboard" class="button">Get Started</a>
            </center>
            
            <p>Need help? Contact us at ${EMAIL.SUPPORT}</p>
          </div>
          <div class="footer">
            <p>&copy; 2026 Govi Sahaya. All rights reserved.</p>
            <p>Smart Agriculture Advisor Platform</p>
          </div>
        </div>
      </body>
      </html>
    `;

    return await this.sendEmail({
      to: user.email,
      subject: 'Welcome to Govi Sahaya! 🌾',
      html,
    });
  } catch (error) {
    logger.error('Send welcome email error:', error);
    throw error;
  }
};

// Send order confirmation email
exports.sendOrderConfirmationEmail = async (user, order) => {
  try {
    const itemsList = order.items
      .map(
        (item) =>
          `<li>${item.name} - Qty: ${item.quantity} - Rs. ${item.subtotal.toFixed(2)}</li>`
      )
      .join('');

    const html = `
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background-color: #2196F3; color: white; padding: 20px; text-align: center; }
          .content { background-color: #f9f9f9; padding: 30px; }
          .order-details { background-color: white; padding: 20px; margin: 20px 0; border-radius: 5px; }
          .total { font-size: 18px; font-weight: bold; color: #2196F3; margin-top: 20px; }
          .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>Order Confirmed! ✅</h1>
          </div>
          <div class="content">
            <h2>Thank you for your order, ${user.name}!</h2>
            <p>Order Number: <strong>${order.orderNumber}</strong></p>
            <p>Order Date: <strong>${new Date(order.createdAt).toLocaleDateString()}</strong></p>
            
            <div class="order-details">
              <h3>Order Items:</h3>
              <ul>${itemsList}</ul>
              <div class="total">Total: Rs. ${order.totalAmount.toFixed(2)}</div>
            </div>
            
            <h3>Shipping Address:</h3>
            <p>
              ${order.shippingAddress.name}<br>
              ${order.shippingAddress.addressLine1}<br>
              ${order.shippingAddress.addressLine2 || ''}<br>
              ${order.shippingAddress.city}<br>
              ${order.shippingAddress.postalCode || ''}
            </p>
            
            <h3>Payment Method:</h3>
            <p>${order.paymentMethod.replace('_', ' ').toUpperCase()}</p>
            
            <p>We'll send you another email when your order ships.</p>
          </div>
          <div class="footer">
            <p>&copy; 2026 Govi Sahaya. All rights reserved.</p>
          </div>
        </div>
      </body>
      </html>
    `;

    return await this.sendEmail({
      to: user.email,
      subject: `Order Confirmation - ${order.orderNumber}`,
      html,
    });
  } catch (error) {
    logger.error('Send order confirmation email error:', error);
    throw error;
  }
};

// Send notification email
exports.sendNotificationEmail = async (user, notification) => {
  try {
    const html = `
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background-color: #9C27B0; color: white; padding: 20px; text-align: center; }
          .content { background-color: #f9f9f9; padding: 30px; }
          .notification { background-color: white; padding: 20px; margin: 20px 0; border-radius: 5px; }
          .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>New Notification</h1>
          </div>
          <div class="content">
            <h2>Hello, ${user.name}</h2>
            <div class="notification">
              <h3>${notification.title}</h3>
              <p>${notification.message}</p>
            </div>
          </div>
          <div class="footer">
            <p>&copy; 2026 Govi Sahaya. All rights reserved.</p>
          </div>
        </div>
      </body>
      </html>
    `;

    return await this.sendEmail({
      to: user.email,
      subject: notification.title,
      html,
    });
  } catch (error) {
    logger.error('Send notification email error:', error);
    throw error;
  }
};

// Send bulk emails
exports.sendBulkEmails = async (recipients, subject, html) => {
  try {
    const promises = recipients.map((recipient) =>
      this.sendEmail({
        to: recipient.email,
        subject,
        html: html.replace('{{name}}', recipient.name),
      }).catch((err) => {
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

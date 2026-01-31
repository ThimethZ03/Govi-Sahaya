const twilio = require('twilio');
const logger = require('../utils/logger');
const { SMS } = require('../config/constants');

// Create Twilio client
const createClient = () => {
  if (!process.env.TWILIO_ACCOUNT_SID || !process.env.TWILIO_AUTH_TOKEN) {
    throw new Error('Twilio credentials not configured');
  }

  return twilio(process.env.TWILIO_ACCOUNT_SID, process.env.TWILIO_AUTH_TOKEN);
};

// Send SMS
exports.sendSMS = async (to, message) => {
  try {
    const client = createClient();

    const result = await client.messages.create({
      body: message,
      from: SMS.FROM_NUMBER || process.env.TWILIO_PHONE_NUMBER,
      to: to,
    });

    logger.info('SMS sent successfully:', result.sid);

    return {
      success: true,
      messageId: result.sid,
      status: result.status,
    };
  } catch (error) {
    logger.error('Send SMS error:', error);
    throw new Error('Failed to send SMS');
  }
};

// Send OTP SMS
exports.sendOTP = async (phoneNumber, otp) => {
  try {
    const message = `Your Govi Sahaya verification code is: ${otp}. Valid for 10 minutes. Do not share this code with anyone.`;

    return await this.sendSMS(phoneNumber, message);
  } catch (error) {
    logger.error('Send OTP SMS error:', error);
    throw error;
  }
};

// Send welcome SMS
exports.sendWelcomeSMS = async (user) => {
  try {
    const message = `Welcome to Govi Sahaya, ${user.name}! Your smart agriculture advisor platform. Start by detecting crop diseases, checking weather, and connecting with farmers. Download the app: ${process.env.APP_URL}`;

    return await this.sendSMS(user.phone, message);
  } catch (error) {
    logger.error('Send welcome SMS error:', error);
    throw error;
  }
};

// Send order update SMS
exports.sendOrderUpdateSMS = async (user, order, status) => {
  try {
    let message = '';

    switch (status) {
      case 'confirmed':
        message = `Your order ${order.orderNumber} has been confirmed. Total: Rs. ${order.totalAmount}. Track your order in the app.`;
        break;
      case 'shipped':
        message = `Great news! Your order ${order.orderNumber} has been shipped. Track: ${order.shippingDetails.trackingNumber || 'N/A'}`;
        break;
      case 'delivered':
        message = `Your order ${order.orderNumber} has been delivered. Thank you for shopping with Govi Sahaya!`;
        break;
      case 'cancelled':
        message = `Your order ${order.orderNumber} has been cancelled. If you have questions, contact support.`;
        break;
      default:
        message = `Order ${order.orderNumber} status updated to: ${status}`;
    }

    return await this.sendSMS(user.phone, message);
  } catch (error) {
    logger.error('Send order update SMS error:', error);
    throw error;
  }
};

// Send weather alert SMS
exports.sendWeatherAlertSMS = async (user, alert) => {
  try {
    const message = `⚠️ Weather Alert: ${alert.title}. ${alert.description.substring(0, 100)}... Check the app for more details.`;

    return await this.sendSMS(user.phone, message);
  } catch (error) {
    logger.error('Send weather alert SMS error:', error);
    throw error;
  }
};

// Send disease detection SMS
exports.sendDiseaseDetectionSMS = async (user, detection) => {
  try {
    const message = `Crop Doctor Result: ${detection.topPrediction.diseaseName} detected with ${(detection.topPrediction.confidence * 100).toFixed(0)}% confidence. Severity: ${detection.topPrediction.severity}. Check the app for treatment recommendations.`;

    return await this.sendSMS(user.phone, message);
  } catch (error) {
    logger.error('Send disease detection SMS error:', error);
    throw error;
  }
};

// Send bulk SMS
exports.sendBulkSMS = async (recipients, message) => {
  try {
    const promises = recipients.map((recipient) =>
      this.sendSMS(recipient.phone, message.replace('{{name}}', recipient.name)).catch(
        (err) => {
          logger.error(`Failed to send SMS to ${recipient.phone}:`, err);
          return { success: false, phone: recipient.phone };
        }
      )
    );

    const results = await Promise.all(promises);
    const successful = results.filter((r) => r.success).length;
    const failed = results.filter((r) => !r.success).length;

    logger.info(`Bulk SMS sent: ${successful} successful, ${failed} failed`);

    return { successful, failed, results };
  } catch (error) {
    logger.error('Send bulk SMS error:', error);
    throw error;
  }
};

// Verify phone number format (Sri Lankan)
exports.verifyPhoneNumber = (phoneNumber) => {
  // Sri Lankan phone format: +94XXXXXXXXX or 0XXXXXXXXX
  const regex = /^(\+94|0)?[0-9]{9}$/;
  return regex.test(phoneNumber);
};

// Format phone number to international format
exports.formatPhoneNumber = (phoneNumber) => {
  // Remove all non-digit characters
  let cleaned = phoneNumber.replace(/\D/g, '');

  // If starts with 0, replace with 94
  if (cleaned.startsWith('0')) {
    cleaned = '94' + cleaned.substring(1);
  }

  // Add + prefix if not present
  if (!cleaned.startsWith('+')) {
    cleaned = '+' + cleaned;
  }

  return cleaned;
};

// Check SMS delivery status
exports.checkDeliveryStatus = async (messageId) => {
  try {
    const client = createClient();
    const message = await client.messages(messageId).fetch();

    return {
      status: message.status,
      errorCode: message.errorCode,
      errorMessage: message.errorMessage,
    };
  } catch (error) {
    logger.error('Check delivery status error:', error);
    throw error;
  }
};

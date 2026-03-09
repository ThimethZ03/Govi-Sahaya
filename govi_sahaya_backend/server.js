require('dotenv').config();
const app = require('./src/app');
const { connectDB } = require('./src/config/database');
const logger = require('./src/utils/logger');
const mlService = require('./src/services/mlService');
const { startAllCronJobs, stopAllCronJobs } = require('./src/utils/cronJobs');

// Handle uncaught exceptions
process.on('uncaughtException', (error) => {
  logger.error('UNCAUGHT EXCEPTION! Shutting down...', error);
  process.exit(1);
});

// Connect to database
connectDB();

// Initialize ML service
mlService.initialize().catch((err) => {
  logger.error('ML service initialization failed:', err);
});

// Start server
const PORT = process.env.PORT || 5000;
const server = app.listen(PORT, () => {
  logger.info(`✅ Server running in ${process.env.NODE_ENV} mode on port ${PORT}`);
  logger.info(`📚 API Documentation: http://localhost:${PORT}/api-docs`);

  // ✅ START CRON JOBS AFTER SERVER IS READY
  try {
    startAllCronJobs();
  } catch (error) {
    logger.error('❌ Failed to start cron jobs:', error);
  }
});

// Handle unhandled promise rejections
process.on('unhandledRejection', (error) => {
  logger.error('UNHANDLED REJECTION! Shutting down...', error);
  server.close(() => {
    process.exit(1);
  });
});

// Graceful shutdown
process.on('SIGTERM', () => {
  logger.info('⚠️ SIGTERM received. Shutting down gracefully...');
  stopAllCronJobs();
  server.close(() => {
    logger.info('✅ Server closed. Process terminated.');
    process.exit(0);
  });
});

process.on('SIGINT', () => {
  logger.info('⚠️ SIGINT received. Shutting down gracefully...');
  stopAllCronJobs();
  server.close(() => {
    logger.info('✅ Server closed. Process terminated.');
    process.exit(0);
  });
});

module.exports = server;

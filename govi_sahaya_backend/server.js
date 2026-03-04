require("dotenv").config(); // .env must be in backend root (D:\govi_sahaya_backend\.env)

const app = require("./src/app");
const { connectDB } = require("./src/config/database");
const logger = require("./src/utils/logger");
const mlService = require("./src/services/mlService");
const { startAllCronJobs, stopAllCronJobs } = require("./src/utils/cronJobs");
const { initializeFirebase } = require("./src/config/firebase"); // ✅ ADD THIS
const path = require("path");
const express = require("express");

// Handle uncaught exceptions
process.on("uncaughtException", (error) => {
  logger.error("UNCAUGHT EXCEPTION! Shutting down...", error);
  process.exit(1);
});

// ✅ Initialize Firebase Admin first (won't crash if missing, but logs warning)
initializeFirebase();

// Connect to database
connectDB();

// Initialize ML service
mlService.initialize().catch((err) => {
  logger.error("ML service initialization failed:", err);
});

/**
 * ✅ Static Files Serving
 * backend එකේ root එකේ ඇති 'uploads' folder එක සර්වර් එක හරහා share කිරීම.
 */
app.use("/uploads", express.static(path.join(__dirname, "uploads")));
logger.info(`📁 Static file serving enabled at: ${path.join(__dirname, "uploads")}`);

// ✅ Start server (use env PORT, default 5000 to avoid clashes)
const PORT = Number(process.env.PORT) || 5000;

const server = app.listen(PORT, () => {
  logger.info(`✅ Server running in ${process.env.NODE_ENV || "development"} mode on port ${PORT}`);
  logger.info(`📚 API Documentation: http://localhost:${PORT}/api-docs`);

  // ✅ START CRON JOBS AFTER SERVER IS READY
  try {
    startAllCronJobs();
  } catch (error) {
    logger.error("❌ Failed to start cron jobs:", error);
  }
});

// Handle unhandled promise rejections
process.on("unhandledRejection", (error) => {
  logger.error("UNHANDLED REJECTION! Shutting down...", error);
  server.close(() => {
    process.exit(1);
  });
});

// Graceful shutdown
const gracefulShutdown = (signal) => {
  logger.info(`⚠️ ${signal} received. Shutting down gracefully...`);
  stopAllCronJobs();
  server.close(() => {
    logger.info("✅ Server closed. Process terminated.");
    process.exit(0);
  });
};

process.on("SIGTERM", () => gracefulShutdown("SIGTERM"));
process.on("SIGINT", () => gracefulShutdown("SIGINT"));

module.exports = server;

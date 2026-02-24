const logger = require('../utils/logger');

// Required environment variables
const REQUIRED_ENV_VARS = [
  'NODE_ENV',
  'PORT',
  'MONGODB_URI',
  'JWT_SECRET',
];

// Validate and get configuration
const validateEnv = () => {
  const missingVars = [];

  REQUIRED_ENV_VARS.forEach((varName) => {
    if (!process.env[varName]) {
      missingVars.push(varName);
    }
  });

  if (missingVars.length > 0) {
    throw new Error(`Missing required environment variables: ${missingVars.join(', ')}`);
  }
};

const getConfig = () => {
  return {
    env: process.env.NODE_ENV || 'development',
    isProduction: process.env.NODE_ENV === 'production',
    server: {
      port: parseInt(process.env.PORT, 10) || 5000,
      host: process.env.HOST || '0.0.0.0',
    },
    database: {
      uri: process.env.MONGODB_URI,
    },
    jwt: {
      secret: process.env.JWT_SECRET,
      expiresIn: process.env.JWT_EXPIRES_IN || '7d',
    },
    // ... (more config)
  };
};

module.exports = { validateEnv, getConfig, printConfig };

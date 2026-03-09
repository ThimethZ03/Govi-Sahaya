const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const mongoSanitize = require('express-mongo-sanitize');
const compression = require('compression');
const morgan = require('morgan');
const swaggerUi = require('swagger-ui-express');
const swaggerJsdoc = require('swagger-jsdoc');
const path = require('path');

const { initializeFirebase } = require('./config/firebase');
initializeFirebase();

const routes = require('./routes');
const { errorHandler, notFound } = require('./middleware/errorHandler');
const { apiLimiter } = require('./middleware/rateLimiter');
const logger = require('./utils/logger');

const app = express();

// Trust proxy
app.set('trust proxy', 1);

// ✅ CORS (ONLY ONCE)
const corsOptions = {
  origin: process.env.CORS_ORIGIN ? process.env.CORS_ORIGIN.split(',') : '*',
  credentials: true,
  optionsSuccessStatus: 200,
};
app.use(cors(corsOptions));

// Swagger configuration
const swaggerOptions = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'Govi Sahaya API',
      version: '1.0.0',
      description: 'Smart Agriculture Advisor Platform API Documentation',
      contact: {
        name: 'Govi Sahaya Team',
        email: 'support@govisahaya.lk',
      },
    },
    servers: [
      {
        url: process.env.API_URL || 'http://localhost:5000',
        description: 'Development server',
      },
    ],
    components: {
      securitySchemes: {
        bearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT',
        },
      },
    },
    security: [{ bearerAuth: [] }],
  },
  apis: ['./src/routes/*.js', './src/models/*.js'],
};

const swaggerSpec = swaggerJsdoc(swaggerOptions);

// Middleware
app.use(
  helmet({
    contentSecurityPolicy: false,
    crossOriginEmbedderPolicy: false,
  })
);

// Body parser
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Data sanitization
app.use(mongoSanitize());

// Compression
app.use(compression());

// Logging
if (process.env.NODE_ENV === 'development') {
  app.use(morgan('dev'));
} else {
  app.use(
    morgan('combined', {
      stream: {
        write: (message) => logger.http(message.trim()),
      },
    })
  );
}

// Rate limiting
app.use('/api', apiLimiter);

// ✅ Static files (ONLY ONCE)
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));
logger.info('📁 Static file serving enabled: /uploads');

// API Documentation
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));

// Health check
app.get('/health', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'Server is healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV,
  });
});

// Root route
app.get('/', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'Welcome to Govi Sahaya API',
    version: '1.0.0',
    documentation: '/api-docs',
  });
});

// ✅ API Routes
app.use('/', routes);

// 404 handler
app.use(notFound);

// Error handler
app.use(errorHandler);

module.exports = app;

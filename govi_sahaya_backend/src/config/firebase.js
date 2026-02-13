const admin = require('firebase-admin');
const logger = require('../utils/logger');

// Initialize Firebase Admin SDK
const initializeFirebase = () => {
  try {
    // Check if Firebase is already initialized
    if (admin.apps.length > 0) {
      logger.info('Firebase Admin already initialized');
      return admin.app();
    }

    // Initialize with service account (for production)
    if (process.env.FIREBASE_SERVICE_ACCOUNT_PATH) {
      const serviceAccount = require(process.env.FIREBASE_SERVICE_ACCOUNT_PATH);
      
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
        storageBucket: process.env.FIREBASE_STORAGE_BUCKET,
      });
      
      logger.info('Firebase Admin initialized with service account');
    } 
    // Initialize with environment variables (for development)
    else if (process.env.FIREBASE_PROJECT_ID) {
      admin.initializeApp({
        credential: admin.credential.cert({
          projectId: process.env.FIREBASE_PROJECT_ID,
          clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
          privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
        }),
        storageBucket: process.env.FIREBASE_STORAGE_BUCKET,
      });
      
      logger.info('Firebase Admin initialized with environment variables');
    } else {
      throw new Error('Firebase configuration not found in environment variables');
    }

    return admin.app();
  } catch (error) {
    logger.error(`Firebase initialization error: ${error.message}`);
    throw error;
  }
};

// Get Firebase services
const getAuth = () => admin.auth();
const getFirestore = () => admin.firestore();
const getStorage = () => admin.storage();
const getMessaging = () => admin.messaging();

// Verify Firebase ID Token
const verifyIdToken = async (idToken) => {
  try {
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    return decodedToken;
  } catch (error) {
    logger.error(`Token verification error: ${error.message}`);
    throw error;
  }
};

// Upload file to Firebase Storage
const uploadToStorage = async (file, destination) => {
  try {
    const bucket = admin.storage().bucket();
    const fileUpload = bucket.file(destination);
    
    await fileUpload.save(file.buffer, {
      metadata: {
        contentType: file.mimetype,
      },
    });
    
    // Make file publicly accessible
    await fileUpload.makePublic();
    
    const publicUrl = `https://storage.googleapis.com/${bucket.name}/${destination}`;
    return publicUrl;
  } catch (error) {
    logger.error(`Storage upload error: ${error.message}`);
    throw error;
  }
};

// Delete file from Firebase Storage
const deleteFromStorage = async (filePath) => {
  try {
    const bucket = admin.storage().bucket();
    await bucket.file(filePath).delete();
    logger.info(`File deleted from storage: ${filePath}`);
  } catch (error) {
    logger.error(`Storage deletion error: ${error.message}`);
    throw error;
  }
};

module.exports = {
  initializeFirebase,
  getAuth,
  getFirestore,
  getStorage,
  getMessaging,
  verifyIdToken,
  uploadToStorage,
  deleteFromStorage,
  admin,
};

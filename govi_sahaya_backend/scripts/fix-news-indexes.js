const mongoose = require('mongoose');
const path = require('path');

// Load environment variables from parent directory
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });

const News = require('../src/models/News');

async function fixIndexes() {
  try {
    // Check if MONGODB_URI exists
    if (!process.env.MONGODB_URI) {
      console.error('❌ MONGODB_URI not found in .env file');
      console.log('💡 Make sure .env file exists in:', path.join(__dirname, '..'));
      process.exit(1);
    }

    console.log('📡 Connecting to MongoDB...');
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    // Drop all indexes except _id
    console.log('🗑️  Dropping all indexes...');
    await News.collection.dropIndexes();
    console.log('✅ Dropped all indexes');

    // Recreate indexes from schema
    console.log('🔨 Recreating indexes...');
    await News.createIndexes();
    console.log('✅ Recreated indexes');

    // Show current indexes
    const indexes = await News.collection.getIndexes();
    console.log('📋 Current indexes:');
    console.log(JSON.stringify(indexes, null, 2));

    await mongoose.disconnect();
    console.log('✅ Done! Indexes fixed successfully');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

fixIndexes();

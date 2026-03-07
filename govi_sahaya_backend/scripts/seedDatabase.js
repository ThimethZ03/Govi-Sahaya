require('dotenv').config();
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const logger = require('../src/utils/logger');

const seedDatabase = async () => {
  try {
    console.log('🌱 Govi Sahaya - Database Setup\n');
    console.log('=' .repeat(50));

    // Connect to MongoDB
    const uri = process.env.MONGODB_URI || 'mongodb://10.33.185.104/govi-sahaya';
    console.log('\n📡 Connecting to MongoDB...');
    console.log('URI:', uri);
    
    await mongoose.connect(uri);
    console.log('✅ Connected successfully!\n');

    const db = mongoose.connection.db;

    // Create collections
    console.log('📦 Creating collections...');
    const collections = [
      'users', 'diseases', 'crops', 'detections',
      'forumposts', 'forumcomments', 'shopitems',
      'orders', 'knowledgearticles', 'weatherlogs'
    ];

    for (const collectionName of collections) {
      try {
        await db.createCollection(collectionName);
        console.log(`  ✅ ${collectionName}`);
      } catch (err) {
        if (err.code === 48) {
          console.log(`  ℹ️  ${collectionName} (already exists)`);
        }
      }
    }

    // Seed Admin User
    console.log('\n👤 Creating admin user...');
    const usersCollection = db.collection('users');
    const adminExists = await usersCollection.findOne({ email: 'admin@govisahaya.lk' });
    
    if (!adminExists) {
      const hashedPassword = await bcrypt.hash('Admin@123456', 12);
      await usersCollection.insertOne({
        name: 'Admin',
        email: 'admin@govisahaya.lk',
        password: hashedPassword,
        role: 'admin',
        phone: '+94771234567',
        location: { district: 'Colombo', province: 'Western' },
        isEmailVerified: true,
        isPhoneVerified: true,
        createdAt: new Date(),
        updatedAt: new Date()
      });
      console.log('✅ Admin created: admin@govisahaya.lk');
    } else {
      console.log('ℹ️  Admin already exists');
    }

    // Seed Diseases
    console.log('\n🦠 Seeding diseases...');
    const diseasesCollection = db.collection('diseases');
    
    const diseases = [
      {
        name: 'Early Blight', scientificName: 'Alternaria solani',
        cropType: 'tomato', severity: 'moderate',
        symptoms: 'Circular brown spots with concentric rings',
        cause: 'Fungal infection', affectedCrops: ['tomato', 'potato'],
        treatment: {
          organic: ['Neem oil spray', 'Copper fungicide'],
          chemical: ['Chlorothalonil', 'Mancozeb'],
          preventive: ['Crop rotation', 'Remove infected debris']
        },
        createdAt: new Date()
      },
      {
        name: 'Purple Blotch', scientificName: 'Alternaria porri',
        cropType: 'onion', severity: 'high',
        symptoms: 'Purple spots with yellow margins on leaves',
        cause: 'Fungal disease in warm humid weather',
        affectedCrops: ['onion', 'garlic'],
        treatment: {
          organic: ['Neem oil', 'Garlic spray'],
          chemical: ['Mancozeb', 'Chlorothalonil'],
          preventive: ['Crop rotation', 'Avoid overhead watering']
        },
        createdAt: new Date()
      },
      {
        name: 'Downy Mildew', scientificName: 'Peronospora destructor',
        cropType: 'onion', severity: 'high',
        symptoms: 'Pale yellow spots, purple mold growth',
        cause: 'Fungal organism in cool wet conditions',
        affectedCrops: ['onion', 'garlic'],
        treatment: {
          organic: ['Copper fungicides'],
          chemical: ['Metalaxyl fungicides'],
          preventive: ['Good air circulation', 'Proper spacing']
        },
        createdAt: new Date()
      }
    ];

    let diseaseCount = 0;
    for (const disease of diseases) {
      const exists = await diseasesCollection.findOne({ 
        name: disease.name, 
        cropType: disease.cropType 
      });
      if (!exists) {
        await diseasesCollection.insertOne(disease);
        console.log(`  ✅ ${disease.name}`);
        diseaseCount++;
      }
    }
    if (diseaseCount === 0) console.log('  ℹ️  All diseases already exist');

    // Seed Crops
    console.log('\n🌾 Seeding crops...');
    const cropsCollection = db.collection('crops');
    
    const crops = [
      {
        name: 'Tomato', scientificName: 'Solanum lycopersicum',
        category: 'vegetable', growthDuration: '60-80 days',
        idealTemperature: '20-30°C', waterRequirement: 'moderate',
        soilType: 'well-drained, pH 6.0-6.8',
        commonDiseases: ['Early Blight', 'Late Blight'],
        harvestSeason: ['December-March', 'June-August'],
        createdAt: new Date()
      },
      {
        name: 'Onion', scientificName: 'Allium cepa',
        category: 'vegetable', growthDuration: '90-120 days',
        idealTemperature: '15-25°C', waterRequirement: 'moderate',
        soilType: 'well-drained, pH 6.0-7.0',
        commonDiseases: ['Purple Blotch', 'Downy Mildew', 'Rust'],
        harvestSeason: ['February-April'],
        createdAt: new Date()
      },
      {
        name: 'Potato', scientificName: 'Solanum tuberosum',
        category: 'vegetable', growthDuration: '90-120 days',
        idealTemperature: '15-20°C', waterRequirement: 'high',
        soilType: 'well-drained, pH 5.0-6.5',
        commonDiseases: ['Early Blight', 'Late Blight'],
        harvestSeason: ['December-February'],
        createdAt: new Date()
      }
    ];

    let cropCount = 0;
    for (const crop of crops) {
      const exists = await cropsCollection.findOne({ name: crop.name });
      if (!exists) {
        await cropsCollection.insertOne(crop);
        console.log(`  ✅ ${crop.name}`);
        cropCount++;
      }
    }
    if (cropCount === 0) console.log('  ℹ️  All crops already exist');

    // Summary
    console.log('\n' + '='.repeat(50));
    console.log('✅ DATABASE SETUP COMPLETE!\n');
    console.log('📊 Summary:');
    console.log(`  • Users: ${await usersCollection.countDocuments()}`);
    console.log(`  • Diseases: ${await diseasesCollection.countDocuments()}`);
    console.log(`  • Crops: ${await cropsCollection.countDocuments()}`);
    
    console.log('\n🔐 Admin Login:');
    console.log('  Email: admin@govisahaya.lk');
    console.log('  Password: Admin@123456');
    
    console.log('\n🎯 Next Steps:');
    console.log('  1. npm run dev (start backend)');
    console.log('  2. Open MongoDB Compass to view data');
    console.log('  3. Test API at http://localhost:5000\n');

    await mongoose.disconnect();
    console.log('✅ Disconnected from MongoDB\n');
    
  } catch (error) {
    console.error('\n❌ Error:', error.message);
    console.error('Stack:', error.stack);
    process.exit(1);
  }
};

seedDatabase();

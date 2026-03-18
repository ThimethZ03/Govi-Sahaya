const mongoose = require('mongoose');
const News = require('../src/models/News');

describe('News Model - Validation Tests', () => {

  // TEST 1 - valid news article
  it('should create a valid news article successfully', async () => {
    const news = new News({
      title: 'Rice Harvest Season Begins in Sri Lanka',
      description: 'Farmers across Sri Lanka begin the annual rice harvest.',
      content: 'Full article content here.',
      category: 'general',
      language: 'en',
    });
    const error = news.validateSync();
    expect(error).toBeUndefined();
  });

  // TEST 2 - missing title
  it('should fail validation when title is missing', async () => {
    const news = new News({
      description: 'Test description',
      content: 'Test content',
      category: 'general',
    });
    const error = news.validateSync();
    expect(error.errors.title).toBeDefined();
  });

  // TEST 3 - missing description
  it('should fail validation when description is missing', async () => {
    const news = new News({
      title: 'Test Title',
      content: 'Test content',
      category: 'general',
    });
    const error = news.validateSync();
    expect(error.errors.description).toBeDefined();
  });

  // TEST 4 - invalid category
  it('should fail validation for invalid category', async () => {
    const news = new News({
      title: 'Test Title',
      description: 'Test description',
      content: 'Test content',
      category: 'invalid_category',
    });
    const error = news.validateSync();
    expect(error.errors.category).toBeDefined();
  });

  // TEST 5 - title too long
  it('should fail validation when title exceeds 200 characters', async () => {
    const news = new News({
      title: 'A'.repeat(201),
      description: 'Test description',
      content: 'Test content',
      category: 'general',
    });
    const error = news.validateSync();
    expect(error.errors.title).toBeDefined();
  });

  // TEST 6 - valid category enum
  it('should accept valid category values', async () => {
    const validCategories = [
      'general', 'market_prices', 'government_policy',
      'technology', 'weather', 'success_stories', 'events'
    ];
    validCategories.forEach((category) => {
      const news = new News({
        title: 'Test Title',
        description: 'Test description',
        content: 'Test content',
        category,
      });
      const error = news.validateSync();
      expect(error).toBeUndefined();
    });
  });

});
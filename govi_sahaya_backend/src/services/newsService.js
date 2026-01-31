const axios = require('axios');
const logger = require('../utils/logger');
const { NEWS } = require('../config/constants');

// News API configuration
const newsAPI = axios.create({
  baseURL: NEWS.BASE_URL,
  timeout: 10000,
  headers: {
    'X-Api-Key': NEWS.API_KEY,
  },
});

// Fetch agriculture news
exports.fetchAgriNews = async (options = {}) => {
  try {
    const {
      country = 'lk',
      category = 'agriculture',
      pageSize = NEWS.PAGE_SIZE,
      page = 1,
    } = options;

    const params = {
      q: 'agriculture OR farming OR crops',
      language: NEWS.LANGUAGE,
      pageSize,
      page,
      sortBy: 'publishedAt',
    };

    const response = await newsAPI.get('/everything', { params });
    const articles = response.data.articles;

    // Transform articles to our format
    const transformedArticles = articles.map((article) => ({
      title: article.title,
      description: article.description || article.content?.substring(0, 200),
      content: article.content,
      coverImage: {
        url: article.urlToImage,
        alt: article.title,
      },
      author: {
        name: article.author,
        source: article.source.name,
      },
      sourceUrl: article.url,
      publishedDate: new Date(article.publishedAt),
      category: this.categorizeNews(article.title + ' ' + article.description),
      tags: this.extractTags(article.title + ' ' + article.description),
      language: NEWS.LANGUAGE,
      externalSource: {
        name: 'NewsAPI',
        apiId: article.url,
        fetchedAt: new Date(),
      },
    }));

    return transformedArticles;
  } catch (error) {
    logger.error('Fetch agri news error:', error.message);
    throw new Error('Failed to fetch agriculture news');
  }
};

// Fetch news by topic
exports.fetchNewsByTopic = async (topic, limit = 10) => {
  try {
    const params = {
      q: topic,
      language: NEWS.LANGUAGE,
      pageSize: limit,
      sortBy: 'publishedAt',
    };

    const response = await newsAPI.get('/everything', { params });
    return response.data.articles;
  } catch (error) {
    logger.error('Fetch news by topic error:', error.message);
    throw error;
  }
};

// Fetch top headlines
exports.fetchTopHeadlines = async (country = 'lk') => {
  try {
    const params = {
      country,
      category: 'general',
      pageSize: 10,
    };

    const response = await newsAPI.get('/top-headlines', { params });
    return response.data.articles;
  } catch (error) {
    logger.error('Fetch top headlines error:', error.message);
    throw error;
  }
};

// Categorize news article
exports.categorizeNews = (text) => {
  const lowerText = text.toLowerCase();

  if (lowerText.includes('price') || lowerText.includes('market') || lowerText.includes('trade')) {
    return 'market_prices';
  }
  if (lowerText.includes('government') || lowerText.includes('policy') || lowerText.includes('subsidy')) {
    return 'government_policy';
  }
  if (lowerText.includes('technology') || lowerText.includes('innovation') || lowerText.includes('ai')) {
    return 'technology';
  }
  if (lowerText.includes('weather') || lowerText.includes('climate') || lowerText.includes('rain')) {
    return 'weather';
  }
  if (lowerText.includes('success') || lowerText.includes('achievement') || lowerText.includes('award')) {
    return 'success_stories';
  }
  if (lowerText.includes('event') || lowerText.includes('conference') || lowerText.includes('exhibition')) {
    return 'events';
  }

  return 'general';
};

// Extract tags from text
exports.extractTags = (text) => {
  const keywords = [
    'rice', 'wheat', 'corn', 'tomato', 'potato', 'pumpkin', 'onion',
    'organic', 'fertilizer', 'pesticide', 'irrigation', 'harvest',
    'climate', 'weather', 'technology', 'market', 'price', 'export',
    'government', 'subsidy', 'loan', 'insurance',
  ];

  const lowerText = text.toLowerCase();
  const foundTags = keywords.filter((keyword) => lowerText.includes(keyword));

  return foundTags.slice(0, 5);
};

// Search news
exports.searchNews = async (query, options = {}) => {
  try {
    const {
      pageSize = 10,
      page = 1,
      sortBy = 'publishedAt',
      language = NEWS.LANGUAGE,
    } = options;

    const params = {
      q: query,
      language,
      pageSize,
      page,
      sortBy,
    };

    const response = await newsAPI.get('/everything', { params });
    return response.data.articles;
  } catch (error) {
    logger.error('Search news error:', error.message);
    throw error;
  }
};

// Get news by date range
exports.getNewsByDateRange = async (from, to, topic = 'agriculture') => {
  try {
    const params = {
      q: topic,
      from: from.toISOString(),
      to: to.toISOString(),
      language: NEWS.LANGUAGE,
      sortBy: 'publishedAt',
    };

    const response = await newsAPI.get('/everything', { params });
    return response.data.articles;
  } catch (error) {
    logger.error('Get news by date range error:', error.message);
    throw error;
  }
};

// Get trending topics
exports.getTrendingTopics = async () => {
  try {
    // Fetch recent agriculture news
    const news = await this.fetchAgriNews({ pageSize: 50 });

    // Extract and count topics
    const topicCounts = {};
    news.forEach((article) => {
      article.tags.forEach((tag) => {
        topicCounts[tag] = (topicCounts[tag] || 0) + 1;
      });
    });

    // Sort by frequency
    const trending = Object.entries(topicCounts)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 10)
      .map(([topic, count]) => ({ topic, count }));

    return trending;
  } catch (error) {
    logger.error('Get trending topics error:', error.message);
    return [];
  }
};

// Scrape specific agriculture websites (optional)
exports.scrapeAgriWebsites = async () => {
  // Placeholder for custom web scraping
  // You can implement scraping for Sri Lankan agriculture websites
  logger.info('Custom website scraping not implemented yet');
  return [];
};

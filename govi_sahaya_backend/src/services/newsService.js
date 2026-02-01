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

// ✅ Categorize news article
const categorizeNews = (text = '') => {
  const lowerText = String(text).toLowerCase();

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

// ✅ Extract tags from text
const extractTags = (text = '') => {
  const keywords = [
    'rice', 'wheat', 'corn', 'tomato', 'potato', 'pumpkin', 'onion',
    'organic', 'fertilizer', 'pesticide', 'irrigation', 'harvest',
    'climate', 'weather', 'technology', 'market', 'price', 'export',
    'government', 'subsidy', 'loan', 'insurance',
  ];

  const lowerText = String(text).toLowerCase();
  const foundTags = keywords.filter((keyword) => lowerText.includes(keyword));

  return foundTags.slice(0, 5);
};

// ✅ Fetch agriculture news
const fetchAgriNews = async (options = {}) => {
  try {
    const {
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
    const articles = response.data.articles || [];

    const transformedArticles = articles.map((article) => {
      const mixText = `${article.title || ''} ${article.description || ''}`;

      return {
        title: article.title || 'No Title',
        description: article.description || article.content?.substring(0, 200) || '',
        content: article.content || article.description || '',
        coverImage: {
          url: article.urlToImage || '',
          alt: article.title || '',
        },
        author: {
          name: article.author || '',
          source: article.source?.name || 'NewsAPI',
        },
        sourceUrl: article.url || '',
        publishedDate: article.publishedAt ? new Date(article.publishedAt) : new Date(),
        category: categorizeNews(mixText),
        tags: extractTags(mixText),
        language: NEWS.LANGUAGE,
        isPublished: true,
        isFeatured: false,
        externalSource: {
          name: 'NewsAPI',
          apiId: article.url || String(Date.now()),
          fetchedAt: new Date(),
        },
      };
    });

    return transformedArticles;
  } catch (error) {
    logger.error('Fetch agri news error:', error.message);
    throw new Error('Failed to fetch agriculture news');
  }
};

// other functions kept as you had (but fixed to use helpers)
const fetchNewsByTopic = async (topic, limit = 10) => {
  try {
    const params = {
      q: topic,
      language: NEWS.LANGUAGE,
      pageSize: limit,
      sortBy: 'publishedAt',
    };

    const response = await newsAPI.get('/everything', { params });
    return response.data.articles || [];
  } catch (error) {
    logger.error('Fetch news by topic error:', error.message);
    throw error;
  }
};

const fetchTopHeadlines = async (country = 'lk') => {
  try {
    const params = {
      country,
      category: 'general',
      pageSize: 10,
    };

    const response = await newsAPI.get('/top-headlines', { params });
    return response.data.articles || [];
  } catch (error) {
    logger.error('Fetch top headlines error:', error.message);
    throw error;
  }
};

const searchNews = async (query, options = {}) => {
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
    return response.data.articles || [];
  } catch (error) {
    logger.error('Search news error:', error.message);
    throw error;
  }
};

const getNewsByDateRange = async (from, to, topic = 'agriculture') => {
  try {
    const params = {
      q: topic,
      from: from.toISOString(),
      to: to.toISOString(),
      language: NEWS.LANGUAGE,
      sortBy: 'publishedAt',
    };

    const response = await newsAPI.get('/everything', { params });
    return response.data.articles || [];
  } catch (error) {
    logger.error('Get news by date range error:', error.message);
    throw error;
  }
};

const getTrendingTopics = async () => {
  try {
    const news = await fetchAgriNews({ pageSize: 50 });

    const topicCounts = {};
    news.forEach((article) => {
      (article.tags || []).forEach((tag) => {
        topicCounts[tag] = (topicCounts[tag] || 0) + 1;
      });
    });

    return Object.entries(topicCounts)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 10)
      .map(([topic, count]) => ({ topic, count }));
  } catch (error) {
    logger.error('Get trending topics error:', error.message);
    return [];
  }
};

const scrapeAgriWebsites = async () => {
  logger.info('Custom website scraping not implemented yet');
  return [];
};

module.exports = {
  fetchAgriNews,
  fetchNewsByTopic,
  fetchTopHeadlines,
  searchNews,
  getNewsByDateRange,
  getTrendingTopics,
  scrapeAgriWebsites,
  categorizeNews,
  extractTags,
};

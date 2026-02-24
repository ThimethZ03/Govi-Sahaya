const axios = require('axios');
const logger = require('../utils/logger');
const agriKeywords = require('../config/agriKeywords');

const ESANA_API_URL = 'https://esena-news-api-v3.vercel.app/';

// categories we should NOT use to decide "agriculture"
const SKIP_CATEGORIES = new Set([
  'sri_lanka_specific_sinhala',
  'sri_lanka_specific_english',
]);

const normalizeKeyword = (k) => {
  if (!k) return null;
  const kw = String(k).trim().toLowerCase();

  // too short => too many false positives
  if (kw.length < 2) return null;

  // must include a letter (english) OR sinhala letter
  if (!/[a-z\u0D80-\u0DFF]/i.test(kw)) return null;

  // block Sinhala junk words that match everything
  const blocked = new Set(['මේ']);
  if (blocked.has(kw)) return null;

  return kw;
};

const escapeRegex = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

const getAllKeywords = () => {
  const all = [];

  Object.entries(agriKeywords).forEach(([category, arr]) => {
    if (SKIP_CATEGORIES.has(category)) return;
    if (Array.isArray(arr)) all.push(...arr);
  });

  const cleaned = all.map(normalizeKeyword).filter(Boolean);
  return [...new Set(cleaned)];
};

const buildMatchers = (keywords) => {
  const sinhala = [];
  const english = [];

  for (const k of keywords) {
    if (/[\u0D80-\u0DFF]/.test(k)) {
      // Sinhala keyword must be >= 3 characters to avoid false positives
      if (k.length >= 3) sinhala.push(k);
    } else {
      // English keyword must be >= 3 characters
      if (k.length >= 3) english.push(k);
    }
  }

  const englishRegex =
    english.length > 0
      ? new RegExp(`\\b(${english.map(escapeRegex).join('|')})\\b`, 'i')
      : null;

  return { sinhala, englishRegex };
};

const AGRI_KEYWORDS = getAllKeywords();
const AGRI_MATCHERS = buildMatchers(AGRI_KEYWORDS);

logger.info(`✅ Loaded ${AGRI_KEYWORDS.length} agriculture keywords for filtering`);

// ✅ FETCH ALL NEWS FROM ESANA
exports.fetchEsanaNews = async () => {
  try {
    const response = await axios.get(ESANA_API_URL, {
      headers: { Accept: 'application/json' },
      timeout: 15000,
    });

    const allNews = response?.data?.news_data?.data;
    if (Array.isArray(allNews)) {
      logger.info(`📰 Fetched ${allNews.length} news articles from Helakuru Esana`);
      return allNews;
    }

    logger.warn('⚠️ No news data found in Esana response');
    return [];
  } catch (error) {
    logger.error('❌ Esana fetch error:', error.message);
    throw new Error('Failed to fetch news from Helakuru Esana API');
  }
};

// ✅ CHECK IF NEWS IS AGRICULTURE-RELATED
exports.isAgricultureNews = (newsItem) => {
  const titleSi = newsItem.titleSi || '';
  const titleEn = newsItem.titleEn || '';
  const description = newsItem.description || newsItem.desc || '';

  const text = `${titleSi} ${titleEn} ${description}`.toLowerCase();

  // English: word boundary regex
  if (AGRI_MATCHERS.englishRegex && AGRI_MATCHERS.englishRegex.test(text)) {
    logger.debug(`✅ Agriculture news detected: ${titleEn || titleSi}`);
    return true;
  }

  // Sinhala: contains match
  for (const kw of AGRI_MATCHERS.sinhala) {
    if (text.includes(kw)) {
      logger.debug(`✅ Agriculture news detected: ${titleEn || titleSi}`);
      return true;
    }
  }

  return false;
};

// ✅ CATEGORIZE NEWS BASED ON CONTENT
exports.categorizeNews = (newsItem) => {
  const text = `${newsItem.titleSi || ''} ${newsItem.titleEn || ''} ${newsItem.description || ''}`.toLowerCase();

  if (
    text.includes('ආණ්ඩුව') || text.includes('government') ||
    text.includes('අමාත්‍යාංශය') || text.includes('ministry') ||
    text.includes('ප්‍රතිපත්ති') || text.includes('policy') ||
    text.includes('සහනාධාර') || text.includes('subsidy') ||
    text.includes('රජය') || text.includes('අමාත්‍ය')
  ) return 'government_policy';

  if (
    text.includes('මිල') || text.includes('price') ||
    text.includes('වෙළඳපොල') || text.includes('market') ||
    text.includes('අලෙවිය') || text.includes('trade') ||
    text.includes('විකුණුම') || text.includes('sale')
  ) return 'market_prices';

  if (
    text.includes('පළිබෝධ') || text.includes('pest') ||
    text.includes('රෝග') || text.includes('disease') ||
    text.includes('අනතුරු') || text.includes('alert') ||
    text.includes('කාලගුණය') || text.includes('weather') ||
    text.includes('වැසි') || text.includes('rain') ||
    text.includes('නියඟය') || text.includes('drought')
  ) return 'weather';

  if (
    text.includes('තාක්ෂණය') || text.includes('technology') ||
    text.includes('ඩ්‍රෝන්') || text.includes('drone') ||
    text.includes('නවෝත්පාදන') || text.includes('innovation') ||
    text.includes('ස්මාර්ට්') || text.includes('smart')
  ) return 'technology';

  if (
    text.includes('සාර්ථක') || text.includes('success') ||
    text.includes('ජයග්‍රහණය') || text.includes('achievement') ||
    text.includes('සම්මානය') || text.includes('award') ||
    text.includes('විශිෂ්ට') || text.includes('excellent')
  ) return 'success_stories';

  if (
    text.includes('සිදුවීම') || text.includes('event') ||
    text.includes('ප්‍රදර්ශනය') || text.includes('exhibition') ||
    text.includes('සම්මන්ත්‍රණය') || text.includes('conference') ||
    text.includes('workshop') || text.includes('වැඩමුළු')
  ) return 'events';

  return 'general';
};

// ✅ EXTRACT TAGS
exports.extractTags = (newsItem) => {
  const text = `${newsItem.titleSi || ''} ${newsItem.titleEn || ''} ${newsItem.description || ''}`.toLowerCase();
  const foundTags = [];

  const tagKeywords = {
    rice: ['rice', 'වී', 'paddy', 'නෙල්'],
    fertilizer: ['fertilizer', 'පොහොර', 'urea', 'යූරියා'],
    pest: ['pest', 'පළිබෝධ', 'disease', 'රෝග'],
    organic: ['organic', 'කාබනික', 'bio', 'ජෛව'],
    technology: ['technology', 'තාක්ෂණය', 'smart', 'ස්මාර්ට්'],
    price: ['price', 'මිල', 'cost', 'මිල ගණන්'],
    farmer: ['farmer', 'ගොවි', 'cultivation', 'වගාව'],
    weather: ['weather', 'කාලගුණය', 'rain', 'වැසි'],
    drought: ['drought', 'නියඟය', 'dry', 'වියළි'],
    flood: ['flood', 'ගංවතුර', 'water', 'ජලය'],
  };

  Object.entries(tagKeywords).forEach(([tag, keywords]) => {
    if (keywords.some((keyword) => text.includes(String(keyword).toLowerCase()))) {
      foundTags.push(tag);
    }
  });

  return foundTags.slice(0, 5);
};

// ✅ PARSE DATE (Esana often gives `published`)
exports.parseDate = (newsItem) => {
  const raw =
    newsItem?.published ||
    newsItem?.date ||
    newsItem?.time ||
    newsItem?.publishedDate;

  if (!raw) return new Date();

  const parsed = new Date(raw);
  if (!isNaN(parsed.getTime())) return parsed;

  return new Date();
};

// ✅ IMPROVED: Extract cover image with better validation
const getCoverImageFromEsana = (newsItem) => {
  // Helper function to validate URL
  const isValidUrl = (url) => {
    if (!url || typeof url !== 'string') return false;
    const trimmed = url.trim();
    return trimmed.startsWith('http://') || trimmed.startsWith('https://');
  };

  // 1) thumb is the best
  if (isValidUrl(newsItem?.thumb)) {
    return newsItem.thumb;
  }

  // 2) first image in contentSi blocks
  if (Array.isArray(newsItem?.contentSi)) {
    const imgBlock = newsItem.contentSi.find((b) => b?.type === 'image' && isValidUrl(b?.data));
    if (imgBlock?.data) {
      return imgBlock.data;
    }
  }

  // 3) fallback common keys (with validation)
  if (isValidUrl(newsItem?.imageUrl)) return newsItem.imageUrl;
  if (isValidUrl(newsItem?.image)) return newsItem.image;

  // 4) Return empty string if no valid URL found
  return '';
};

// ✅ IMPROVED: Extract ALL images from Esana contentSi with validation
const extractImagesFromEsana = (newsItem) => {
  if (!Array.isArray(newsItem?.contentSi)) return [];

  const isValidUrl = (url) => {
    if (!url || typeof url !== 'string') return false;
    const trimmed = url.trim();
    return trimmed.startsWith('http://') || trimmed.startsWith('https://');
  };

  return newsItem.contentSi
    .filter((b) => b?.type === 'image' && isValidUrl(b?.data))
    .map((b) => ({
      url: b.data,
      caption: newsItem?.titleEn || newsItem?.titleSi || '',
    }))
    .slice(0, 10);
};

// ✅ Build readable content from Esana blocks
const buildContentFromEsana = (newsItem) => {
  // if description exists, use it
  const base = newsItem?.description || newsItem?.desc || '';

  // also append clean text blocks from contentSi
  if (!Array.isArray(newsItem?.contentSi)) return base || (newsItem?.titleSi || '');

  const texts = newsItem.contentSi
    .filter((b) => b?.type === 'text' && b?.data)
    .map((b) => String(b.data).replace(/<[^>]*>?/gm, '').trim())
    .filter(Boolean);

  const merged = [base, ...texts].filter(Boolean).join('\n\n');
  return merged || (newsItem?.titleSi || '');
};

// ✅ TRANSFORM ESANA FORMAT TO DB FORMAT (IMPROVED IMAGE HANDLING)
exports.transformEsanaNews = (esanaNews) => {
  const category = exports.categorizeNews(esanaNews);
  const tags = exports.extractTags(esanaNews);

  const coverUrl = getCoverImageFromEsana(esanaNews);
  const gallery = extractImagesFromEsana(esanaNews);

  // Build a proper source URL
  let sourceUrl = '';
  if (esanaNews.share_url) {
    sourceUrl = esanaNews.share_url;
  } else if (esanaNews.url) {
    sourceUrl = esanaNews.url;
  } else if (esanaNews.id) {
    sourceUrl = `https://www.helakuru.lk/esana/p/${esanaNews.id}/`;
  }

  return {
    title: esanaNews.titleEn || esanaNews.titleSi || 'No Title',
    description: (esanaNews.titleSi || esanaNews.description || esanaNews.desc || '').substring(0, 500),
    content: buildContentFromEsana(esanaNews),

    category,
    tags,

    author: { name: 'Helakuru Esana', source: 'Helakuru News Network' },

    coverImage: {
      url: coverUrl, // Will be empty string if no valid URL
      alt: esanaNews.titleEn || esanaNews.titleSi || '',
    },

    images: gallery,

    sourceUrl,
    publishedDate: exports.parseDate(esanaNews),

    language: 'si',
    isPublished: true,
    isFeatured: false,

    externalSource: {
      name: 'Helakuru Esana',
      apiId: String(esanaNews.id || esanaNews.share_url || Date.now()),
      fetchedAt: new Date(),
    },
  };
};

// ✅ FETCH + FILTER AGRI NEWS
exports.fetchAgriNewsFromEsana = async () => {
  const allNews = await exports.fetchEsanaNews();
  if (!allNews.length) return [];

  const agriNews = allNews.filter(exports.isAgricultureNews);
  logger.info(`✅ Filtered ${agriNews.length} agriculture news from ${allNews.length} total articles`);

  return agriNews.map(exports.transformEsanaNews);
};

// ✅ FETCH ALL ESANA NEWS (NO FILTER) - for testing
exports.fetchAllNewsFromEsana = async () => {
  const allNews = await exports.fetchEsanaNews();
  if (!allNews.length) return [];
  logger.info(`✅ Transforming ${allNews.length} Esana news without filtering`);
  return allNews.map(exports.transformEsanaNews);
};

// ✅ KEYWORD STATS
exports.getKeywordStats = () => {
  const stats = {};
  Object.entries(agriKeywords).forEach(([category, keywords]) => {
    stats[category] = Array.isArray(keywords) ? keywords.length : 0;
  });
  stats.total = AGRI_KEYWORDS.length;
  return stats;
};
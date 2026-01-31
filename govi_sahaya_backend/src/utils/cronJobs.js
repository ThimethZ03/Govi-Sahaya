const cron = require('node-cron');
const { fetchAgriNewsFromEsana } = require('../services/esanaNewsService');
const News = require('../models/News');
const logger = require('./logger');

// ✅ SYNC HELAKURU ESANA NEWS EVERY 2 HOURS
exports.startEsanaNewsCron = () => {
  // Run every 2 hours: 0 */2 * * *
  // For testing, use: */5 * * * * (every 5 minutes)
  cron.schedule('0 */2 * * *', async () => {
    logger.info('🔄 [CRON] Starting Helakuru Esana news auto-sync...');
    
    try {
      const startTime = Date.now();
      const esanaNews = await fetchAgriNewsFromEsana();
      
      if (!esanaNews || esanaNews.length === 0) {
        logger.info('⚠️ [CRON] No agriculture news found from Esana');
        return;
      }

      let newCount = 0;
      let skipCount = 0;
      let errorCount = 0;

      for (const newsItem of esanaNews) {
        try {
          const exists = await News.findOne({
            'externalSource.apiId': newsItem.externalSource.apiId,
          });

          if (!exists) {
            await News.create(newsItem);
            newCount++;
            logger.debug(`✅ [CRON] Saved: ${newsItem.title.substring(0, 50)}...`);
          } else {
            skipCount++;
          }
        } catch (error) {
          errorCount++;
          logger.error(`❌ [CRON] Failed to save news: ${error.message}`);
        }
      }

      const duration = ((Date.now() - startTime) / 1000).toFixed(2);
      logger.info(
        `✅ [CRON] Auto-sync complete in ${duration}s: ` +
        `${newCount} new, ${skipCount} skipped, ${errorCount} errors`
      );
    } catch (error) {
      logger.error('❌ [CRON] Auto-sync error:', error.message);
    }
  });

  logger.info('✅ Helakuru Esana news cron job started (runs every 2 hours)');
};

// ✅ CLEANUP OLD NEWS (OPTIONAL - Runs daily at 2 AM)
exports.startNewsCleanupCron = () => {
  cron.schedule('0 2 * * *', async () => {
    logger.info('🧹 [CRON] Starting old news cleanup...');
    
    try {
      // Delete unpublished news older than 30 days
      const thirtyDaysAgo = new Date();
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

      const result = await News.deleteMany({
        isPublished: false,
        createdAt: { $lt: thirtyDaysAgo },
      });

      logger.info(`🧹 [CRON] Cleanup complete: ${result.deletedCount} old news deleted`);
    } catch (error) {
      logger.error('❌ [CRON] Cleanup error:', error.message);
    }
  });

  logger.info('✅ News cleanup cron job started (runs daily at 2 AM)');
};

// ✅ START ALL CRON JOBS
exports.startAllCronJobs = () => {
  logger.info('🚀 Initializing cron jobs...');
  
  this.startEsanaNewsCron();
  this.startNewsCleanupCron();
  
  logger.info('✅ All cron jobs initialized successfully');
};

// ✅ STOP ALL CRON JOBS (For graceful shutdown)
exports.stopAllCronJobs = () => {
  cron.getTasks().forEach((task) => {
    task.stop();
  });
  logger.info('⏹️ All cron jobs stopped');
};

const { createClient } = require('redis');

let redisClient;

const connectRedis = async () => {
  redisClient = createClient({ url: process.env.REDIS_URL || 'redis://redis:6379' });

  redisClient.on('error', (err) => console.error('[Cart Service] Redis error:', err));
  redisClient.on('connect', () => console.log('[Cart Service] Redis connected'));

  await redisClient.connect();
};

const getRedisClient = () => redisClient;

module.exports = { connectRedis, getRedisClient };

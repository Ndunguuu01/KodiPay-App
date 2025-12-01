const dotenv = require('dotenv');
dotenv.config();

const isExternal = process.env.DB_HOST && process.env.DB_HOST.includes('.');
const useSSL = process.env.DB_SSL === 'true' || (process.env.DB_SSL !== 'false' && isExternal);

module.exports = {
  HOST: process.env.DB_HOST,
  USER: process.env.DB_USER,
  PASSWORD: process.env.DB_PASSWORD,
  DB: process.env.DB_NAME,
  dialect: process.env.DB_DIALECT || "sqlite",
  storage: "./database.sqlite",
  pool: {
    max: 5,
    min: 0,
    acquire: 30000,
    idle: 10000
  },
  dialectOptions: process.env.DB_DIALECT === 'postgres' && useSSL ? {
    ssl: {
      require: true,
      rejectUnauthorized: false
    }
  } : {}
};

console.log("DB Config:", {
  HOST: process.env.DB_HOST,
  DIALECT: process.env.DB_DIALECT,
  SSL_ENABLED: useSSL,
  IS_EXTERNAL: isExternal
});

const mysql = require('mysql2/promise');
const dotenv = require('dotenv');
dotenv.config();

async function createDb() {
    const { DB_HOST, DB_USER, DB_PASSWORD, DB_NAME } = process.env;
    console.log(`Connecting to ${DB_HOST} as ${DB_USER}...`);

    try {
        // Connect to MySQL server (without specifying database)
        const connection = await mysql.createConnection({
            host: DB_HOST,
            user: DB_USER,
            password: DB_PASSWORD,
        });

        await connection.query(`CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`;`);
        console.log(`Database '${DB_NAME}' created or already exists.`);
        await connection.end();
    } catch (error) {
        console.error('Error creating database:', error.message);
        if (error.code === 'ER_ACCESS_DENIED_ERROR') {
            console.error('Please check your DB_USER and DB_PASSWORD in .env file.');
        }
    }
}

createDb();

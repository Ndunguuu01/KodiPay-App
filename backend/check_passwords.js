const mysql = require('mysql2/promise');

const passwords = ['root', 'password', 'admin', '123456', 'mysql', 'kodipay'];

async function checkPasswords() {
    console.log("Testing common passwords...");
    for (const password of passwords) {
        try {
            const connection = await mysql.createConnection({
                host: 'localhost',
                user: 'root',
                password: password
            });
            console.log(`\nSUCCESS! The password is: '${password}'`);
            await connection.end();
            return;
        } catch (err) {
            process.stdout.write('.');
        }
    }
    console.log("\n\nFailed to find password in common list.");
}

checkPasswords();

const db = require("./models");
const User = db.users;

db.sequelize.sync().then(async () => {
    const users = await User.findAll();
    console.log("--- USERS START ---");
    users.forEach(u => {
        console.log(`ID: ${u.id}, Name: ${u.name}, Email: ${u.email}, Role: ${u.role}`);
    });
    console.log("--- USERS END ---");
    process.exit();
});

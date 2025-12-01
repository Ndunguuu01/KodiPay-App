const axios = require('axios');

const API_URL = 'http://localhost:8080/api';

async function testAPIs() {
    try {
        console.log('--- Testing Registration ---');
        const randomInt = Math.floor(Math.random() * 10000);
        const email = `landlord${randomInt}@test.com`;

        const registerRes = await axios.post(`${API_URL}/auth/register`, {
            name: "Test Landlord",
            email: email,
            password: "password123",
            role: "landlord",
            phone: "0712345678"
        });
        console.log('Register Success:', registerRes.data);

        console.log('\n--- Testing Login ---');
        const loginRes = await axios.post(`${API_URL}/auth/login`, {
            email: email,
            password: "password123"
        });
        console.log('Login Success. Token received.');
        const token = loginRes.data.accessToken;

        console.log('\n--- Testing Create Property ---');
        const propertyRes = await axios.post(`${API_URL}/properties`, {
            name: "Sunset Apartments",
            location: "Nairobi",
            floors_count: 4,
            landlord_id: loginRes.data.id
        }, {
            headers: { 'x-access-token': token }
        });
        console.log('Create Property Success:', propertyRes.data);

        console.log('\n--- Testing Get Properties ---');
        const getPropsRes = await axios.get(`${API_URL}/properties`, {
            headers: { 'x-access-token': token }
        });
        console.log('Get Properties Success. Count:', getPropsRes.data.length);

    } catch (error) {
        if (error.response) {
            console.error('API Error:', error.response.status, error.response.data);
        } else {
            console.error('Connection Error:', error.message);
        }
    }
}

testAPIs();

const axios = require('axios');

const API_URL = 'http://localhost:8080/api';

async function testUnitLifecycle() {
    try {
        console.log('--- Starting Unit Lifecycle Test ---');
        const randomInt = Math.floor(Math.random() * 10000);
        const email = `landlord_unit${randomInt}@test.com`;

        // 1. Register & Login
        console.log('1. Registering Landlord...');
        await axios.post(`${API_URL}/auth/register`, {
            name: "Unit Tester",
            email: email,
            password: "password123",
            role: "landlord",
            phone: "0712345678"
        });

        console.log('2. Logging in...');
        const loginRes = await axios.post(`${API_URL}/auth/login`, {
            email: email,
            password: "password123"
        });
        const token = loginRes.data.accessToken;
        const landlordId = loginRes.data.id;
        console.log('   > Login successful.');

        // 2. Create Property
        console.log('3. Creating Property...');
        const propertyRes = await axios.post(`${API_URL}/properties`, {
            name: "Unit Test Heights",
            location: "Test City",
            floors_count: 2,
            landlord_id: landlordId
        }, { headers: { 'x-access-token': token } });
        const propertyId = propertyRes.data.id;
        console.log(`   > Property created (ID: ${propertyId})`);

        // 3. Create Unit
        console.log('4. Creating Unit...');
        const unitRes = await axios.post(`${API_URL}/units`, {
            unit_number: "T1",
            rent_amount: 10000,
            floor_number: 1,
            room_number: "101",
            property_id: propertyId
        }, { headers: { 'x-access-token': token } });
        const unitId = unitRes.data.id;
        console.log(`   > Unit created (ID: ${unitId}, Rent: ${unitRes.data.rent_amount})`);

        // 4. Update Unit
        console.log('5. Updating Unit...');
        await axios.put(`${API_URL}/units/${unitId}`, {
            rent_amount: 12000,
            status: "vacant"
        }, { headers: { 'x-access-token': token } });
        console.log('   > Unit updated.');

        // Verify Update
        // Note: We don't have a direct "get unit by id" endpoint in the routes I saw (only get by property).
        // So we fetch all units for property and find ours.
        const unitsRes = await axios.get(`${API_URL}/properties/${propertyId}/units`, {
            headers: { 'x-access-token': token }
        });
        const updatedUnit = unitsRes.data.find(u => u.id === unitId);
        if (updatedUnit && parseFloat(updatedUnit.rent_amount) === 12000) {
            console.log('   > Verification: Rent updated to 12000 successfully.');
        } else {
            console.error('   > Verification FAILED: Rent is ' + (updatedUnit ? updatedUnit.rent_amount : 'unknown'));
        }

        // 5. Delete Unit
        console.log('6. Deleting Unit...');
        await axios.delete(`${API_URL}/units/${unitId}`, {
            headers: { 'x-access-token': token }
        });
        console.log('   > Unit deleted.');

        // Verify Deletion
        const unitsResAfter = await axios.get(`${API_URL}/properties/${propertyId}/units`, {
            headers: { 'x-access-token': token }
        });
        const deletedUnit = unitsResAfter.data.find(u => u.id === unitId);
        if (!deletedUnit) {
            console.log('   > Verification: Unit no longer exists in list.');
        } else {
            console.error('   > Verification FAILED: Unit still exists.');
        }

        console.log('--- Test Completed Successfully ---');

    } catch (error) {
        if (error.response) {
            console.error('API Error:', error.response.status, error.response.data);
        } else {
            console.error('Connection Error:', error.message);
        }
    }
}

testUnitLifecycle();

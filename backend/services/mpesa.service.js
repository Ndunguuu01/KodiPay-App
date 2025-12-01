const axios = require('axios');
const datetime = require('node-datetime');

class MpesaService {
    constructor() {
        this.consumerKey = process.env.MPESA_CONSUMER_KEY;
        this.consumerSecret = process.env.MPESA_CONSUMER_SECRET;
        this.shortCode = process.env.MPESA_SHORTCODE || '174379'; // Sandbox Test Shortcode
        this.passkey = process.env.MPESA_PASSKEY;
        this.env = process.env.MPESA_ENV || 'sandbox'; // sandbox or production

        this.baseUrl = this.env === 'production'
            ? 'https://api.safaricom.co.ke'
            : 'https://sandbox.safaricom.co.ke';
    }

    async getAccessToken() {
        const auth = Buffer.from(`${this.consumerKey}:${this.consumerSecret}`).toString('base64');
        try {
            const response = await axios.get(`${this.baseUrl}/oauth/v1/generate?grant_type=client_credentials`, {
                headers: {
                    Authorization: `Basic ${auth}`
                }
            });
            return response.data.access_token;
        } catch (error) {
            console.error("M-Pesa Access Token Error Details:", {
                message: error.message,
                response: error.response ? error.response.data : 'No Response',
                status: error.response ? error.response.status : 'No Status',
                config: error.config
            });
            throw new Error(`Failed to get M-Pesa Access Token: ${error.message}`);
        }
    }

    async stkPush(phoneNumber, amount, accountReference, transactionDesc) {
        const token = await this.getAccessToken();
        const dt = datetime.create();
        const timestamp = dt.format('YmdHMS');

        const password = Buffer.from(`${this.shortCode}${this.passkey}${timestamp}`).toString('base64');

        // Format phone number (must start with 254)
        let formattedPhone = phoneNumber;
        if (phoneNumber.startsWith('0')) {
            formattedPhone = '254' + phoneNumber.substring(1);
        } else if (phoneNumber.startsWith('+254')) {
            formattedPhone = phoneNumber.substring(1);
        }

        const payload = {
            "BusinessShortCode": this.shortCode,
            "Password": password,
            "Timestamp": timestamp,
            "TransactionType": "CustomerPayBillOnline",
            "Amount": Math.floor(amount), // Amount must be integer
            "PartyA": formattedPhone,
            "PartyB": this.shortCode,
            "PhoneNumber": formattedPhone,
            "CallBackURL": process.env.MPESA_CALLBACK_URL || "https://mydomain.com/api/payments/callback",
            "AccountReference": accountReference,
            "TransactionDesc": transactionDesc
        };

        try {
            const response = await axios.post(`${this.baseUrl}/mpesa/stkpush/v1/processrequest`, payload, {
                headers: {
                    Authorization: `Bearer ${token}`
                }
            });
            return response.data;
        } catch (error) {
            console.error("M-Pesa STK Push Error:", error.response ? error.response.data : error.message);
            throw error;
        }
    }
}

module.exports = new MpesaService();

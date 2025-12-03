const twilio = require('twilio');

const accountSid = process.env.TWILIO_ACCOUNT_SID;
const authToken = process.env.TWILIO_AUTH_TOKEN;
const twilioPhoneNumber = process.env.TWILIO_PHONE_NUMBER;

const client = new twilio(accountSid, authToken);

exports.sendSMS = async (to, body) => {
    try {
        const message = await client.messages.create({
            body: body,
            from: twilioPhoneNumber,
            to: to
        });
        console.log(`SMS sent to ${to}: ${message.sid}`);
        return { success: true, sid: message.sid };
    } catch (error) {
        console.error(`Error sending SMS to ${to}:`, error);
        return { success: false, error: error.message };
    }
};

exports.sendWhatsApp = async (to, body) => {
    try {
        // Twilio WhatsApp numbers require 'whatsapp:' prefix
        const message = await client.messages.create({
            body: body,
            from: `whatsapp:${twilioPhoneNumber}`,
            to: `whatsapp:${to}`
        });
        console.log(`WhatsApp sent to ${to}: ${message.sid}`);
        return { success: true, sid: message.sid };
    } catch (error) {
        console.error(`Error sending WhatsApp to ${to}:`, error);
        return { success: false, error: error.message };
    }
};

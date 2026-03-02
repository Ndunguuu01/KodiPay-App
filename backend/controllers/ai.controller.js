const { GoogleGenerativeAI } = require('@google/generative-ai');
const logger = require('../middleware/logger');

// Gemini API key stays on the server — NEVER sent to client
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
const model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash' });

exports.chat = async (req, res, next) => {
    try {
        const { message, context } = req.body;

        if (!message || typeof message !== 'string' || message.trim().length === 0) {
            return res.status(400).json({ message: 'Message is required.' });
        }

        // Sanitize context fields — only allow known keys to prevent prompt injection
        const safeContext = {
            userName: typeof context?.userName === 'string' ? context.userName.slice(0, 100) : 'Tenant',
            rentAmount: typeof context?.rentAmount === 'number' ? context.rentAmount : null,
            bills: Array.isArray(context?.bills) ? context.bills.slice(0, 20) : []
        };

        const billSummary = safeContext.bills.map(b =>
            `- ${String(b.type || '').slice(0, 50)}: KES ${Number(b.amount) || 0} (${String(b.status || '').slice(0, 20)})`
        ).join('\n') || 'No bills found.';

        // Sanitize user message to prevent prompt injection
        const sanitizedMessage = message.replace(/[<>]/g, '').slice(0, 500);

        const prompt = `
You are a helpful assistant for KodiPay, a real estate management platform. 
You are talking to a tenant named ${safeContext.userName}.

Context:
- Rent Amount: KES ${safeContext.rentAmount || 'Unknown'}
- Bills:
${billSummary}

User Question: "${sanitizedMessage}"

Respond helpfully and concisely (under 3 sentences). Only discuss rent, bills, and tenancy topics. Refuse requests unrelated to KodiPay.
`.trim();

        const result = await model.generateContent(prompt);
        const response = result.response.text();

        res.json({ response });
    } catch (err) {
        logger.error('AI proxy error:', err);
        next(err);
    }
};

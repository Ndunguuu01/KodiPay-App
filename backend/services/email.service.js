const nodemailer = require('nodemailer');

class EmailService {
    constructor() {
        this.transporter = nodemailer.createTransport({
            host: process.env.SMTP_HOST,
            port: process.env.SMTP_PORT,
            secure: process.env.SMTP_PORT == 465, // true for 465, false for other ports
            auth: {
                user: process.env.SMTP_USER,
                pass: process.env.SMTP_PASS,
            },
        });
    }

    async sendEmail(to, subject, htmlContent) {
        try {
            const info = await this.transporter.sendMail({
                from: `"${process.env.SMTP_FROM_NAME || 'KodiPay'}" <${process.env.SMTP_USER}>`,
                to: to,
                subject: subject,
                html: htmlContent,
            });
            console.log("Email sent: %s", info.messageId);
            return { success: true, messageId: info.messageId };
        } catch (error) {
            console.error("Error sending email:", error);
            return { success: false, error: error.message };
        }
    }

    getRentReminderTemplate(tenantName, amount, dueDate, propertyName) {
        const logoUrl = "https://res.cloudinary.com/ddz4jhrfi/image/upload/v1/kodipay_assets/logo.png"; // Replace with actual logo URL if available, or use a placeholder

        return `
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body { font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; line-height: 1.6; color: #333; background-color: #f4f4f4; margin: 0; padding: 0; }
                .container { max-width: 600px; margin: 20px auto; background-color: #ffffff; border-radius: 8px; overflow: hidden; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
                .header { background-color: #1A237E; padding: 30px 20px; text-align: center; }
                .header h1 { color: #ffffff; margin: 0; font-size: 24px; letter-spacing: 1px; }
                .content { padding: 30px; }
                .greeting { font-size: 18px; font-weight: bold; margin-bottom: 20px; color: #1A237E; }
                .message { margin-bottom: 25px; font-size: 16px; color: #555; }
                .details-box { background-color: #e8eaf6; border-left: 5px solid #1A237E; padding: 15px; margin-bottom: 25px; border-radius: 4px; }
                .details-row { display: flex; justify-content: space-between; margin-bottom: 10px; }
                .details-label { font-weight: bold; color: #1A237E; }
                .details-value { font-weight: bold; color: #333; }
                .cta-button { display: block; width: 200px; margin: 0 auto; padding: 15px 0; background-color: #1A237E; color: #ffffff !important; text-align: center; text-decoration: none; border-radius: 5px; font-weight: bold; font-size: 16px; transition: background-color 0.3s; }
                .cta-button:hover { background-color: #0d1245; }
                .footer { background-color: #eeeeee; padding: 20px; text-align: center; font-size: 12px; color: #777; border-top: 1px solid #ddd; }
                .footer a { color: #1A237E; text-decoration: none; }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>KodiPay</h1>
                </div>
                <div class="content">
                    <div class="greeting">Hello ${tenantName},</div>
                    <div class="message">
                        This is a friendly reminder that your rent payment is due in <strong>5 days</strong>. Please ensure your payment is made on or before the due date to avoid any late fees or service interruptions.
                    </div>
                    
                    <div class="details-box">
                        <div class="details-row">
                            <span class="details-label">Property:</span>
                            <span class="details-value">${propertyName}</span>
                        </div>
                        <div class="details-row">
                            <span class="details-label">Amount Due:</span>
                            <span class="details-value">KES ${amount}</span>
                        </div>
                        <div class="details-row">
                            <span class="details-label">Due Date:</span>
                            <span class="details-value">${dueDate}</span>
                        </div>
                    </div>

                    <a href="kodipay://payment" class="cta-button">Pay Now via App</a>
                </div>
                <div class="footer">
                    <p>Thank you for being a valued tenant.</p>
                    <p>&copy; ${new Date().getFullYear()} KodiPay. All rights reserved.</p>
                    <p>Need help? Contact us at <a href="mailto:support@kodipay.com">support@kodipay.com</a></p>
                </div>
            </div>
        </body>
        </html>
        `;
    }
}

module.exports = new EmailService();

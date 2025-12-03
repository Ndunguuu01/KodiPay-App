const db = require("../models");
const Payment = db.payments;
const Lease = db.leases;
const Op = db.Sequelize.Op;

class FraudService {
    /**
     * Analyze a transaction for fraud risk.
     * @param {Object} transaction - { tenantId, amount, unitId }
     * @returns {Object} - { riskScore: number, flags: string[], status: 'approved' | 'review' | 'rejected' }
     */
    async analyze(transaction) {
        const { tenantId, amount, unitId } = transaction;
        let riskScore = 0;
        const flags = [];

        // 1. Fetch historical data
        const lease = await Lease.findOne({
            where: { tenant_id: tenantId, status: 'active' }
        });

        // Rule 1: High Value Transaction (> 200% of rent)
        if (lease && amount > lease.rent_amount * 2) {
            riskScore += 50;
            flags.push('High Value: Transaction exceeds 200% of rent amount.');
        }

        // Rule 2: Velocity Check (> 3 transactions in 1 hour)
        const oneHourAgo = new Date(new Date() - 60 * 60 * 1000);
        const recentPayments = await Payment.count({
            where: {
                tenant_id: tenantId,
                created_at: {
                    [Op.gte]: oneHourAgo
                }
            }
        });

        if (recentPayments >= 3) {
            riskScore += 40;
            flags.push('Velocity: High transaction frequency in the last hour.');
        }

        // Rule 3: Round Number Check (Often suspicious if very large)
        if (amount > 10000 && amount % 1000 === 0) {
            riskScore += 10;
            flags.push('Pattern: Large round number transaction.');
        }

        // Determine Status
        let status = 'approved';
        if (riskScore >= 80) {
            status = 'rejected';
        } else if (riskScore >= 40) {
            status = 'review';
        }

        return { riskScore, flags, status };
    }
}

module.exports = new FraudService();

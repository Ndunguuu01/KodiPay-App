const db = require("../models");
const Property = db.properties;
const Unit = db.units;
const Lease = db.leases;
const Maintenance = db.maintenance;
const Payment = db.payments;
const Op = db.Sequelize.Op;

exports.getLandlordInsights = async (req, res) => {
    const landlordId = req.userId;

    let totalProperties = 0;
    let totalUnits = 0;
    let occupiedUnits = 0;
    let occupancyRate = 0;
    let monthlyRevenue = 0;
    let pendingMaintenance = 0;
    let fraudAlerts = [];

    try {
        // 1. Total Properties
        try {
            totalProperties = await Property.count({ where: { landlord_id: landlordId } });
        } catch (e) { console.error("Error fetching properties:", e); }

        // 2. Total Units & Occupied Units
        let propertyIds = [];
        try {
            const properties = await Property.findAll({
                where: { landlord_id: landlordId },
                attributes: ['id']
            });
            propertyIds = properties.map(p => p.id);

            if (propertyIds.length > 0) {
                totalUnits = await Unit.count({ where: { property_id: propertyIds } });

                const activeLeases = await Lease.findAll({
                    where: { status: 'active' },
                    include: [{
                        model: Unit,
                        as: 'unit',
                        where: { property_id: propertyIds },
                        attributes: []
                    }]
                });
                occupiedUnits = activeLeases.length;
                occupancyRate = totalUnits > 0 ? Math.round((occupiedUnits / totalUnits) * 100) : 0;

                // 4. Monthly Revenue
                activeLeases.forEach(lease => {
                    monthlyRevenue += parseFloat(lease.rent_amount || 0);
                });
            }
        } catch (e) { console.error("Error fetching units/leases:", e); }

        // 5. Pending Maintenance
        try {
            pendingMaintenance = await Maintenance.count({
                where: { status: 'pending' },
                include: [{
                    model: Unit,
                    as: 'unit',
                    required: true,
                    include: [{
                        model: Property,
                        as: 'property',
                        where: { landlord_id: landlordId },
                        required: true
                    }]
                }]
            });
        } catch (e) { console.error("Error fetching maintenance:", e); }

        // 6. Fraud Alerts
        try {
            // Check if fraud_status column exists before querying (basic check via try-catch)
            fraudAlerts = await Payment.findAll({
                where: {
                    fraud_status: { [Op.ne]: 'approved' }
                },
                include: [{
                    model: Unit,
                    as: 'unit',
                    required: true,
                    include: [{
                        model: Property,
                        as: 'property',
                        where: { landlord_id: landlordId },
                        required: true
                    }]
                }],
                order: [['created_at', 'DESC']],
                limit: 5
            });
        } catch (e) {
            console.error("Error fetching fraud alerts:", e);
            // Fallback if fraud_status column missing
            fraudAlerts = [];
        }

        res.status(200).send({
            totalProperties,
            totalUnits,
            occupiedUnits,
            occupancyRate,
            monthlyRevenue,
            pendingMaintenance,
            fraudAlerts
        });

    } catch (err) {
        console.error("Critical Dashboard Error:", err);
        res.status(500).send({
            message: err.message || "Some error occurred while fetching dashboard insights."
        });
    }
};

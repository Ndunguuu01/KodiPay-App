const db = require("../models");
const Property = db.properties;
const Unit = db.units;
const Lease = db.leases;
const Maintenance = db.maintenance;
const Op = db.Sequelize.Op;

exports.getLandlordInsights = async (req, res) => {
    const landlordId = req.userId; // From authJwt middleware

    try {
        // 1. Total Properties
        const totalProperties = await Property.count({
            where: { landlord_id: landlordId }
        });

        // 2. Total Units & Occupied Units
        // We need to find all properties first to get their IDs
        const properties = await Property.findAll({
            where: { landlord_id: landlordId },
            attributes: ['id']
        });
        const propertyIds = properties.map(p => p.id);

        const totalUnits = await Unit.count({
            where: { property_id: propertyIds }
        });

        // Find occupied units (those with active leases)
        // We can count active leases linked to units in these properties
        const activeLeases = await Lease.findAll({
            where: {
                status: 'active'
            },
            include: [{
                model: Unit,
                as: 'unit',
                where: { property_id: propertyIds },
                attributes: [] // We don't need unit details, just the filter
            }]
        });
        const occupiedUnits = activeLeases.length;

        // 3. Occupancy Rate
        const occupancyRate = totalUnits > 0 ? Math.round((occupiedUnits / totalUnits) * 100) : 0;

        // 4. Monthly Expected Revenue (Sum of rent from active leases)
        let monthlyRevenue = 0;
        activeLeases.forEach(lease => {
            monthlyRevenue += parseFloat(lease.rent_amount);
        });

        // 5. Pending Maintenance Requests
        // Maintenance requests are linked to units, which are linked to properties owned by landlord
        // Or we can query Maintenance where unit.property.landlord_id = landlordId
        const pendingMaintenance = await Maintenance.count({
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

        res.status(200).send({
            totalProperties,
            totalUnits,
            occupiedUnits,
            occupancyRate,
            monthlyRevenue,
            pendingMaintenance
        });

    } catch (err) {
        res.status(500).send({
            message: err.message || "Some error occurred while fetching dashboard insights."
        });
    }
};

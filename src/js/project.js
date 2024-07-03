const project = {
    inputs: {
        site_area: 50000,
        FAR: 2.0,
        amenity_GFA_in_FAR: 1400,

        saleable_GFA: function () {
            return this.site_area * this.FAR - this.amenity_GFA_in_FAR;
        },

        commercial_percentage_upper_limit: 0.1,
        commercial_percentage_lower_limit: 0.05,
        management_fee: 0.03,
        sales_fee: 0.25,
        land_cost: 30000,
        land_cost_payment: Array(48)
            .fill(0)
            .map((v, i) => (i === 0 ? 1 : 0)),
        validate_land_cost_payment: function () {
            return this.land_cost_payment.reduce((a, b) => a + b, 0) === 1;
        },
        unsaleable_amenity_cost: 5000,
        unsaleable_amenity_cost_payment: [
            0, 0, 0.1, 0, 0, 0.1, 0, 0, 0.1, 0, 0, 0.1, 0, 0, 0.1, 0, 0, 0.1, 0,
            0, 0.1, 0, 0, 0.1, 0, 0, 0.1, 0, 0, 0.1, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0,
        ],
        validate_unsaleable_amenity_cost_payment: function () {
            return (
                this.unsaleable_amenity_cost_payment.reduce(
                    (a, b) => a + b,
                    0
                ) === 1
            );
        },
        product_baseline_unit_cost_before_allocation: 5500,
        basement_unit_cost_before_allocation: 3400,
        VAT_surchage_rate: 0.0025,
        corp_pretax_gross_profit_rate_threshould: 0.15,
        corp_tax_rate: 0.25,
        LVIT_provisional_rate: 0.02,
    },

    saveToSketchUp: function () {
        const data = JSON.stringify(this);
        window.location = "skp:save_project@" + data;
    },

    loadFromSketchUp: function (data) {
        const parsedData = JSON.parse(data);
        Object.assign(this, parsedData);
        populateForm();
    },
};

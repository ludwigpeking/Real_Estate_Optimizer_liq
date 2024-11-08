module Real_Estate_Optimizer
    module DefaultValues
      PROJECT_DEFAULTS = {
        inputs: {
          site_area: 50000,
          FAR: 2.0,
          discount_rate: 0.09,
          amenity_GFA_in_FAR: 1400,
          commercial_percentage_upper_limit: 0.1,
          commercial_percentage_lower_limit: 0.05,
          management_fee: 0.03,
          sales_fee: 0.025,
          land_cost: 30000,
          land_cost_payment: Array.new(72, 0),
          unsaleable_amenity_cost: 5000,
          unsaleable_amenity_cost_payment: Array.new(72, 0),
          product_baseline_unit_cost_before_allocation: 5500,
          basement_unit_cost_before_allocation: 3400,
          VAT_surchage_rate: 0.0025,
          corp_pretax_gross_profit_rate_threshould: 0.15,
          corp_tax_rate: 0.25,
          LVIT_provisional_rate: 0.02,
          parking_lot_average_price: 120000,
          parking_lot_sales_velocity: 10,
          supervision_fund_release_schedule: [
          0, 0, 0.3, 0, 0, 0, 0.4, 0, 0, 0, 0, 0,
          0, 0, 0, 0, 0, 0, 0.25, 0, 0, 0, 0, 0,
          0.05, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,

          ],
          
          construction_payment_schedule: [
            0.1, 0, 0.2, 0, 0, 0, 0.2, 0, 0, 0, 0, 0,
            0.1, 0, 0, 0, 0, 0, 0.1, 0, 0, 0, 0, 0,
            0.1, 0, 0, 0, 0, 0, 0.1, 0, 0, 0, 0, 0,
            0.1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,

          ],
        }
      }
  
      PROJECT_DEFAULTS[:inputs][:land_cost_payment][0] = 1
      PROJECT_DEFAULTS[:inputs][:unsaleable_amenity_cost_payment] = [0, 0, 0.1, 0, 0, 0.1, 0, 0, 0.1, 0, 0, 0.1, 0, 0, 0.1, 0, 0, 0.1, 0, 0, 0.1, 0, 0, 0.1, 0, 0, 0.1, 0, 0, 0.1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,]
    end
  end
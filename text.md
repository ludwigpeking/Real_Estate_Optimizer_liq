model=Sketchup.active_model
#<Sketchup::Model:0x0001e611f66b68>
data = model.get_attribute('project_data', 'data')
{"building_types":[{"name":"140 18层","floorTypes":[{"number":18,"levelHeight":3,"apartmentTypes":[{"name":"140小高层三室二厅二卫","x":0,"y":0},{"name":"140小高层三室二厅二卫","x":12,"y":0}]}],"standardConstructionTime":{"monthsFromConstructionInitToZeroLevel":2,"monthsFromZeroLevelToRoofLevel":4,"monthsFromRoofLevelToDelivery":6,"monthsFromConstructionInitToSale":2,"supervisionFundPercentage":1},"supervisionFundReleaseSchedule":[0,0,0.3,0,0,0,0.4,0,0,0,0,0,0,0,0,0,0,0,0.25,0,0,0,0,0,0.05,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],"constructionPaymentSchedule":[0.1,0,0.2,0,0,0,0.2,0,0,0,0,0,0.1,0,0,0,0,0,0.1,0,0,0,0,0,0.1,0,0,0,0,0,0.1,0,0,0,0,0,0.1,0,0,0,0,0,0,0,0,0,0,0]},{"name":"110 140 18层","floorTypes":[{"number":1,"levelHeight":4,"apartmentTypes":[{"name":"140商铺商铺","x":0,"y":0},{"name":"140商铺商铺","x":10.5,"y":0}]},{"number":17,"levelHeight":3,"apartmentTypes":[{"name":"110小高层三室二厅二卫","x":0,"y":0},{"name":"110小高层三室二厅二卫","x":10.5,"y":0}]}],"standardConstructionTime":{"monthsFromConstructionInitToZeroLevel":2,"monthsFromZeroLevelToRoofLevel":4,"monthsFromRoofLevelToDelivery":6,"monthsFromConstructionInitToSale":2,"supervisionFundPercentage":1},"supervisionFundReleaseSchedule":[0,0,0.3,0,0,0,0.4,0,0,0,0,0,0,0,0,0,0,0,0.25,0,0,0,0,0,0.05,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],"constructionPaymentSchedule":[0.1,0,0.2,0,0,0,0.2,0,0,0,0,0,0.1,0,0,0,0,0,0.1,0,0,0,0,0,0.1,0,0,0,0,0,0.1,0,0,0,0,0,0.1,0,0,0,0,0,0,0,0,0,0,0]}]}
Available building types: ["140 18层", "110 140 18层"]

project_data = JSON.parse(model.get_attribute('project_data', 'data') || '{}')
{"inputs"=>{"site_area"=>50000, "FAR"=>2, "amenity_GFA_in_FAR"=>1400, "commercial_percentage_upper_limit"=>0.1, "commercial_percentage_lower_limit"=>0.05, "management_fee"=>0.03, "sales_fee"=>0.025, "land_cost"=>10000, "land_cost_payment"=>[1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], "unsaleable_amenity_cost"=>5000, "unsaleable_amenity_cost_payment"=>[0, 0, 0.1, 0, 0, 0.1, 0, 0, 0.1, 0, 0, 0.1, 0, 0, 0.1, 0, 0, 0.1, 0, 0, 0.1, 0, 0, 0.1, 0, 0, 0.1, 0, 0, 0.1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], "product_baseline_unit_cost_before_allocation"=>5500, "basement_unit_cost_before_allocation"=>3400, "VAT_surchage_rate"=>0.0025, "corp_pretax_gross_profit_rate_threshould"=>0.15, "corp_tax_rate"=>0.25, "LVIT_provisional_rate"=>0.02, "parking_lot_average_price"=>120000, "parking_lot_sales_velocity"=>10, "supervision_fund_release_schedule"=>[0, 0, 0.3, 0, 0, 0, 0.4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0.25, 0, 0, 0, 0, 0, 0.05, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], "construction_payment_schedule"=>[0.1, 0, 0.2, 0, 0, 0, 0.2, 0, 0, 0, 0, 0, 0.1, 0, 0, 0, 0, 0, 0.1, 0, 0, 0, 0, 0, 0.1, 0, 0, 0, 0, 0, 0.1, 0, 0, 0, 0, 0, 0.1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]}}

it seems it did not get the percentage right. supervisionFundPercentage is an attribute of the building type, not a global one. Calculated total construction area: 18090.0 m² Attempting to access CashFlowCalculator... CashFlowCalculator is defined. Debug: Building 105 18层   Construction cost: 20790000.0   Supervision fund percentage: 0.0   Construction init time: 0   Total requirement: 0.0   Release schedule: [] Debug: Building 105 160 18层   Construction cost: 26235000.0   Supervision fund percentage: 0.0

it seems it did not get the percentage right. supervisionFundPercentage is an attribute of the building type, not a global one. Calculated total construction area: 18090.0 m² Attempting to access CashFlowCalculator... CashFlowCalculator is defined. Debug: Building 105 18层   Construction cost: 20790000.0   Supervision fund percentage: 0.0   Construction init time: 0   Total requirement: 0.0   Release schedule: [] Debug: Building 105 160 18层   Construction cost: 26235000.0   Supervision fund percentage: 0.0


the release amount of this building is correct. but the rest is not

the required amount is 100% at the construction init, in this building, it is Month 9. the required amount reduces when release happens. the the requirement is reducing over time. 

we should put the supervision fund requirement of all the building instances together, except of the basement, which makes a total required amount, which adds when a building init construction and reduce when they progress over time. 

the next thing would be, the sales income of the apartments (not the parking lot) should go to the supervision account, until the account hits the total required amount at that month. the excessive amount will be paid to the developer and becomes the real income in the cash flow.


for (b of building_instances){
  

}
supervision_requirement = New Array(72)
for (i = 0; i < 72 ; i++){
  supervision_requirement[i] = 0
  
    
  }

}
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

the columns include

收入：计容产品销售收入 apartment sales，预售资金监管要求，资金监管存入，资金监管解活，车位销售收入，总销售收入，总现金流入小计：
支出：土地规费，配套建设费用，计容产品建安费用 apartment construction payment，税费 Fees and Taxes，地下建安费用，总现金流出小计；
月净现金流、累计净现金流

the calculation of supervision fund and release is a bit tricky, but the old formula was correct, don't mess that part. calculate and display the absent columns.

add the key indicator at the top of the report sheet

1、内部收益率 IRR = calculated
2、销售毛利率 = (total income - total expense + total fees and taxes)/total income %
3、销售净利率 = (total income - total expense)/total income %

4, 现金流回正（月）= the month acummulated cashflow reaches negative largest abs number
6、项目总销售额（含税） = total income
7, 项目总投资（含税）= total expenses
10、项目资金峰值 = acummulated cashflow negative largest abs number over time
11、项目净利润 = total income - total expense
12 MOIC = 项目净利润/项目资金峰值

VAT:增值税
=IF(增值比例<20%,0,IF(增值比例<50%,增值额*0.3,IF(增值比例<100%,增值额*0.4-扣除项 *0.05,IF(增值比例<200%,增值额*0.5-扣除项*0.15,增值额*0.6-扣除项）*0.35))))
扣除项 = 不含税费总支出*1.3
增值额 = 销售收入 - 扣除项
增值比例 = 增值额/扣除项

and, we need to add more tax logic in the cash flow.

in the last month, after we get the whole cashflow, we get the gross profit rate.

if the gross profit rate is smaller than 15%, the corporate tax is 0; is its larger than 15%,   the corporate tax = (gross profit rate-15%) * 企业所得税率 Corp Tax Rate from inputs
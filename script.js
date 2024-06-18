//because I am not very familiar with ruby syntax, I am thinking about using a central js object to store all the data, and using js to process the data. this is trying to minimized the ruby operations in sketchup for my better control. but still I have 6 incons in sketchup and they launch seperate dialogs.

const project = {
  inputs: {
    site_area: 50000, //平米
    FAR: 2.0,
    amenity_GFA_in_FAR: 1400, //只计算计容配套；不计容配套不参与计算，计入地价分摊

    saleable_GFA: this.site_area * this.FAR - this.amenity_GFA_in_FAR,

    commercial_percentage_upper_limit: 0.1,
    commercial_percentage_lower_limit: 0.05, //各种指标分配关系只是检查项，不参与现金流计算

    management_fee: 0.03,
    sales_fee: 0.25,

    land_cost: 30000, //万元
    land_cost_payment: [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], //48 months
    // land_cost_payment_valid: land_cost_payment.sum === 1,
    unsaleable_amenity_cost: 5000, //万元
    unsaleable_amenity_cost_payment: [
      0, 0, 0.1, 0, 0, 0.1, 0, 0, 0.1, 0, 0, 0.1, 0, 0, 0.1, 0, 0, 0.1, 0, 0,
      0.1, 0, 0, 0.1, 0, 0, 0.1, 0, 0, 0.1, 0,
    ], //48 months
    // unsaleable_amenity_cost_payment_valid:
    //   land_cost_payment.sum === 1
    //     ? product_baseline_unit_cost_before_allocation
    //     : 5500, //元/平米
    basement_unit_cost_before_allocation: 3400, //元/平米

    VAT_surchage_rate: 0.0025, //增值税附加税，包括城市维护建设税，教育费附加，地方教育附加之类
    corp_pretax_gross_profit_rate_threshould: 0.15, //所得税预征收毛利率
    corp_tax_rate: 0.25, //企业所得税率
    LVIT_provisional_rate: 0.02, //土地增值税预缴税率
  },

  apartment_category_list: ["叠拼", "洋房", "小高层", "大高", "超高"], //按核心筒分类，小于11层为洋房，12到18层为小高，大于18层小于100米为大高，大于100米为超高

  apartment_types: [
    {
      apartment_category: "小高层", //choose from apartment_category_list
      area: 110,
      tag: "标准层",
      apartment_type_name: "110小高层标准层", //area + apartment_category + tag,
      product_baseline_unit_cost_before_allocation: 5500, //元/平米, this value overwrite the value in the input
      width: 10.8, //m
      depth: 11.0, //m
      color: #yellow, //lerp from yellow to blue, 70sqm-160sqm
      sales_scenes: [
        {
          price: 10000, //yuan per sqm
          volumn: 15, //units per month
        },
        {
          price: 11000, //yuan per sqm
          volumn: 11, //units per month
        },
        {
          price: 12000, //yuan per sqm
          volumn: 3, //units per month
        },
      ], //sales_scenes starts from one scene, create a button to add one more scene, and a button to remove the scene, unless there's only one left
    },
    {
      apartment_category: "小高层", //choose from apartment_category_list
      area: 125,
      tag: "标准层",
      apartment_type_name: "125小高层标准层", //area + apartment_category + tag,
      product_baseline_unit_cost_before_allocation: 5500, //元/平米, this value overwrite the value in the input
      width: 12.8, //m
      depth: 11.0, //m
      color: green, //lerp from yellow to blue, 70sqm-160sqm
      sales_scenes: [
        {
          price: 10000, //yuan per sqm
          volumn: 12, //units per month
        },
        {
          price: 11000, //yuan per sqm
          volumn: 9, //units per month
        },
        {
          price: 12000, //yuan per sqm
          volumn: 5, //units per month
        },
      ],
    },
    {
      apartment_category: "小高层", //choose from apartment_category_list
      area: 100,
      tag: "首层",
      apartment_type_name: "100小高层首层", //area + apartment_category + tag,
      product_baseline_unit_cost_before_allocation: 5500, //元/平米, this value overwrite the value in the input
      width: 10.8, //m
      depth: 11.0, //m
      color: yellow, //lerp from yellow to blue, 70sqm-160sqm
      sales_scenes: [
        {
          price: 10000, //yuan per sqm
          volumn: 5, //units per month
        },
        {
          price: 11000, //yuan per sqm
          volumn: 2, //units per month
        },
        {
          price: 12000, //yuan per sqm
          volumn: 1, //units per month
        },
      ],
    },
    {
      apartment_category: "小高层", //choose from apartment_category_list
      area: 110,
      tag: "首层",
      apartment_type_name: "110小高层首层", //area + apartment_category + tag,
      product_baseline_unit_cost_before_allocation: 5500, //元/平米, this value overwrite the value in the input
      width: 12.8, //m
      depth: 11.0, //m
      color: yellow, //lerp from yellow to blue, 70sqm-160sqm
      sales_scenes: [
        {
          price: 10000, //yuan per sqm
          volumn: 5, //units per month
        },
        {
          price: 11000, //yuan per sqm
          volumn: 2, //units per month
        },
        {
          price: 12000, //yuan per sqm
          volumn: 1, //units per month
        },
      ],
    },

    // a dialog deals with one apartment type. clicking the icon creates a new apartment type, and you can load the existing types from a drop list, modify and save the type in the panel.
  ],

  building_types: [
    {
      //serialized from bottom to top
      floor_types: [
        {
          number_of_floors: 1,
          apartments: [
            {
              apartment_type_name: "100小高层首层",
              position_x: 0,
              position_y: 0,
            },
            {
              apartment_type_name: "110小高层首层",
              position_x: 10.8,
              position_y: 0,
            },
          ],
        },
        {
          number_of_floors: 17,
          apartments: [
            {
              apartment_type_name: "110小高层标准层",
              position_x: 0,
              position_y: 0,
            },
            {
              apartment_type_name: "125小高层标准层",
              position_x: 10.8,
              position_y: 0,
            },
          ],
        },
        // the dialog start with the first floor type, there's a button to add one more floor type, and a button to remove the floor type, unless there's only one left
      ],
      building_type_name: "125+110 18层", //there should be a function that calculate the floor types, takes the most prevalent floor's apartment areas(descending order, with plus in between) as the building type's name, adding the number of floors at the end
      standardConstructionTime: {
        monthsFromConstructionInitToZeroLevel: 2, //months, input default value
        monthsFromZeroLevelToRoofLevel: 4, //months, input default value
        monthsFromRoofLevelToDelivery: 6, //months, input default value
        monthsFromConstructionInitToSale: 2, //months, input default value, //adding
        supervisionFundPercentage: 2, //percent, input default value
      },

      supervisionFundReleaseSchedule: [
        0, 0, 0, 0, 0, 0.3, 0, 0, 0, 0, 0, 0.3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0.3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0.1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0,
      ], //input cells 12x4, default value
      constructionPaymentSchedule: [
        0.2, 0, 0, 0.1, 0, 0, 0, 0, 0, 0, 0, 0.2, 0, 0, 0, 0, 0, 0.1, 0, 0, 0,
        0, 0, 0.1, 0, 0, 0, 0, 0, 0.1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0.1, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0.1,
      ], //input cells 12x4, default value
    },
  ],
  building_type_instances: [
    {
      building_type_name: "125+110 18层",
      position_x: 125.42, //from sketchup model
      position_y: 1439.55, //from sketchup model
      position_z: 0, //from sketchup model
      constructionInitMonth: 2,
    },
    {
      building_type_name: "125+110 18层",
      position_x: 155.42, //from sketchup model
      position_y: 1439.55, //from sketchup model
      position_z: 0, //from sketchup model
      constructionInitMonth: 2,
    },
  ],
  basements: [
    {
      basement_name: "basement_A",
      area: 17000,
      constructionInitMonth: 0,
    },
    {
      basement_type_name: "basement_B",
      area: 18000,
      constructionInitMonth: 8,
    },
  ], //basements should be picked from the model and the area should be calculated from the objects in the model, it then creates a dynamic component with the attribute

  property_line_area: 50000, //sqm, picked from the objects in the model

  apartment_stocks: [
    {
      apartment_type_name: "100小高层首层",
      stocks: [], //48 months, the number of apartments that are ready to sell, traverse the building_type_instances in the model, the building type's standardConstructionTime.monthsFromConstructionInitToSale is the time to start selling, adding all its apartments to the stock
    },
    {
      apartment_type_name: "110小高层首层",
      stocks: [], //48 months, the number of apartments that are ready to sell, traverse the building_type_instances in the model, the building type's standardConstructionTime.monthsFromConstructionInitToSale is the time to start selling, adding all its apartments to the stock
    },
    {
      apartment_type_name: "110小高层标准层",
      stocks: [], //48 months, the number of apartments that are ready to sell, traverse the building_type_instances in the model, the building type's standardConstructionTime.monthsFromConstructionInitToSale is the time to start selling, adding all its apartments to the stock
    },
    {
      apartment_type_name: "125小高层标准层",
      stocks: [], //48 months, the number of apartments that are ready to sell, traverse the building_type_instances in the model, the building type's standardConstructionTime.monthsFromConstructionInitToSale is the time to start selling, adding all its apartments to the stock
    },
    //adding stock methods, sales methods, should be added, and these will generate income, tax, and management fee, sales fee, and so on to the cash flow array
  ],

  cashflow: [], //48 months, the cash flow of the project, including land cost, unsaleable amenity cost, basement cost, construction cost, sales income, tax, management fee, sales fee, and so on

  sales: [],
};

function updateNumbersOfApartmentsInTheModel(p) {
  //traverse the building_type_instances in the model, the building type's standardConstructionTime.monthsFromConstructionInitToSale is the time to start selling, adding all its apartments to the stock
  for (let building of project.building_type_instances) {
    for (let buildingType of project.building_types) {
      if (building.building_type_name === buildingType.building_type_name) {
        for (let apartment of buildingType.floor_types) {
          if (
            building.constructionInitMonth +
              apartmentType.standardConstructionTime
                .monthsFromConstructionInitToSale ===
            0
          ) {
            project.apartment_stocks
              .find(
                (stock) => stock.apartment_type_name === apartment_type_name
              )
              .stocks.push(apartment);
          }
        }
      }
    }
  }
}

function stockAdding(apartment_type_name) {
  //traverse the building_type_instances in the model, the building type's standardConstructionTime.monthsFromConstructionInitToSale is the time to start selling, adding all its apartments to the stock
  for (let building of project.building_type_instances) {
    for (let buildingType of project.building_types) {
      if (building.building_type_name === buildingType.building_type_name) {
        for (let apartment of buildingType.floor_types) {
          if (apartment.apartment_type_name === apartment_type_name) {
            if (
              building.constructionInitMonth +
                apartmentType.standardConstructionTime
                  .monthsFromConstructionInitToSale ===
              0
            ) {
              project.apartment_stocks
                .find(
                  (stock) => stock.apartment_type_name === apartment_type_name
                )
                .stocks.push(apartment);
            }
          }
        }
      }
    }
  }
}

// function monthlySales()

// sketchup_model_entities : traverse the model and find all component instances that present in build_type_names

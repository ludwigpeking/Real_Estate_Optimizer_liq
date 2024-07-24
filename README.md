
5个【按钮】
1.【定义/编辑户型】定义过的户型加入户型列表
    form 输入列表:
        面积Tag：
            float 120 m2; 整数变成户型名Tag
        类型Tag：
            list: [叠拼,洋房,小高层,大高,超高]
        备注Tag:
            string
        户型名：string “面积Tag” + “类型Tag” +"备注Tag"
        width 面宽：
            float 10.2.m
        depth 进深：
            float 11.5.m
        市场需求：
            [float 单方价格1，int 月流速1]
            [float 单方价格2，int 月流速2]
            [float 单方价格3，int 月流速3]
        单方成本估值：
            float 5500 RMB； 地价外单方成本
        得房率：
            float 得房率 用户输入%
        自动生成轮廓四点Vertices
        vertices:可以在图中instance里编辑，但是不能在创建时编辑。
        [
            [0, 0], 
            [width, 0], 
            [width, height], 
            [height, 0]
        ]
        
    可以通过复制创建新户型，重新命名即可。
            
2.【定义/编辑楼型（单元）】定义过的楼型加入楼型列表
    form 输入列表:
        标准层：
            标准层个数：
                int 17；
            标准层包含的户型列表:offset为户型相对标准层原点的位移，第一个默认[0, 0], 第二个默认[unit01.width, 0],依次类推
                [
                    {
                        name: "小高120",
                        offset: [0, 0]
                    },
                    {
                        name: "小高120",
                        offset: [10.2, 0]
                    }
                ]
            层高：
                float 2.9.m;
        变异层1：
            变异层个数：
                int 1;
            变异层包含的户型:
                [
                    {
                        name: "小高100首层变异",
                        offset: [0, 0]
                    },
                    {
                        name: "小高120",
                        offset: [10.2, 0]
                    }
                ]
            层高：
                float 3.5.m;
        （变异层可增加个数）
        层数：标准层个数 + 变异层1个数 + ...
    可以通过复制创建新楼型，重新命名即可。

    geometry 几何外形：通过上面几何参数生成：
    标准层户型1面宽*进深方形，轮廓线，顶点
    标准层户型2面宽*进深方形，轮廓线，顶点
    两条轮廓线分别按照层高生成体块，
    (层数 + 层高+0.75.m)和标准层户型2面宽*进深*(层数 + 层高+0.75.m)两个方块并置

    geometry 坐标点：左下角，地面高度为(0, 0, 0)

    form 运营数据：
            开工时间：
                date 开工时间：精确到月
            开工到取销售证时间：
                int 6个月；
            资金监管金额：
                f 5000 RMB;
            资金监管解活时间：
                [0, 0, 0, 0, 0, 0.3, 0, 0, 0, 0, 0, 0.3,
                 0, 0, 0, 0, 0, 0,   0, 0, 0, 0, 0, 0.3,
                 0, 0, 0, 0, 0, 0,   0, 0, 0, 0, 0, 0.1]
                *勾稽检查，所有相加等于1.
            工程付款节奏：
                [0.2, 0, 0, 0.1, 0, 0,
                 0,   0, 0, 0,   0, 0.2,
                 0,   0, 0, 0,   0, 0.1,
                 0,   0, 0, 0,   0, 0.1,
                 0,   0, 0, 0,   0, 0.1,
                 0,   0, 0, 0,   0, 0,
                 0,   0, 0, 0,   0, 0.1,
                 0,   0, 0, 0,   0, 0,
                 0,   0, 0, 0,   0, 0.1]
                 *勾稽检查，所有相加等于1.

3.【保存读取户型/楼型设置】
    保存json文件，格式和变量名参考如下：
    yangfang140 = {
        name: "洋房140",
        area: 140,
        type: "洋房",
        comment: null,
        width: 12.0,
        depth: 11.5,
        marketPrediction:
            [
                [12000, 25],
                [13000, 14],
                [14000, 5]
            ],
        constructionCostPerSqm: 5500,
        netAreaRatio: 0.82
        vertices:
        [
            [0, 0], [12, 0], [12, 11.5], [11.5, 0]
        ]
    };
    ...
    building Type Management Panel
    {
        floorType[0]:{
            number: 1,
            apartmentTypes:[
                {
                    name: "80小高层首层", //select from list
                    x: 0, //input, default 0
                    y: 0 //input, default 0
                },
                {
                    name: "110小高层首层", //select from list
                    x: 8, //input, default: apartmentType['80小高层首层'].width
                    y: 0 //input, default 0
                }
            ],
            levelHeight: 3
        },
        floorType[1]:{
            number: 17,
            apartmentTypes:[
                {
                    name: "90小高层", //select from list
                    x: 0, //input, default 0
                    y: 0 //input, default 0
                },
                {
                    name: "120小高层", //select from list
                    x: 8, //input, default: apartmentType['90小高层'].width
                    y: 0 //input, default 0
                }
            ],
            levelHeight: 3
        },
        floorType[2] : null
        levels : floorType[0].number + floorType[1].number + ... //calculate in background
        name: "90+120 18层" //generated in background, from the most prevail floorType, the areas of the apartment types, connected by "+", blank and levels + "层"
        tag: "" //customerized comment for the building type

        standardConstructionTime: {
            daysFromConstructionInitToZeroLevel: 45, //days, input default value
            daysFromZeroLevelToRoofLevel: 120, //days, input default value
            daysFromRoofLevelToDelivery: 180, //days, input default value
            daysFromConstructionInitToSale: 60, //days, input default value
            supervisionFundPercentage: 60 //percent, input default value
        }
        
        supervisionFundReleaseSchedule:
            [
            0, 0, 0, 0, 0, 0.3, 0, 0, 0, 0, 0, 0.3,
            0, 0, 0, 0, 0, 0,   0, 0, 0, 0, 0, 0.3,
            0, 0, 0, 0, 0, 0,   0, 0, 0, 0, 0, 0.1
            ], //input cells 12x3, default value
        constructionPaymentSchedule:
            [
            0.2, 0, 0, 0.1, 0, 0,
            0,   0, 0, 0,   0, 0.2,
            0,   0, 0, 0,   0, 0.1,
            0,   0, 0, 0,   0, 0.1,
            0,   0, 0, 0,   0, 0.1,
            0,   0, 0, 0,   0, 0,
            0,   0, 0, 0,   0, 0.1,
            0,   0, 0, 0,   0, 0,
            0,   0, 0, 0,   0, 0.1
            ] //input cells 12x3, default value
    }
    button to save the building type , auto named: name+tag
    button to load building type  from name list
    ...
4.【放置楼栋】
    从楼型列表选择楼栋
    点击到图上，添加带数值的动态组件。轮廓线可以编辑。

5.【SU中编辑组件数值】（非按钮，为动态组件）

    1）在图上的组件中部分参数中可以改变, 可以改变的参数只有：
        * 开工时间。改变开工时间不改变楼型本身。只改变本组件的该属性。
        ** 楼座本身的坐标，随模型改变和更新。

    在图上，组件的其他参数不可改变，只能在组件里更新。
    2）在图上，动态组件里面户型轮廓线可以手动改变，改变的轮廓线会改变楼型的默认设置。vertices更新。户型面宽和进深参数会跟着轮廓线的修改更新。
    会更新所有相同组件的几何性状。
    3）不能图上改层高、层数，只能通过编辑楼型参数改层高。
    

6.【数据输出】
    点击按钮，可以选择输出范围：
        1）所有选中物体；
        2）图中所有物体。
    保存json文件
        保存户型、楼型信息，此外，保存每个楼栋数量。
        inventory = {
            {
                name: "小高18层120+120" ,
                constructionInitTime: [8, 2003],
                coordinate: [85.25, 235.70, 1.5]
            }，
            {
                name: "小高18层120+120" ,
                constructionInitTime: [8, 2003],
                coordinate: [185.25, 235.70, 1.2]
            }，
            {
                name: "小高18层120+120" ,
                constructionInitTime: [8, 2003],
                coordinate: [185.25, 235.70, 1.2]
            }

        }


    

project = {
    inputs:{
        site_area: 50000; //平米
        FAR:2.0;
        amenity_GFA_in_FAR: 1400; //只计算计容配套；不计容配套不参与计算，计入地价分摊

        saleable_GFA : site_area * FAR - amenity_GFA_in_FAR;

        commercial_percentage_upper_limit: 0.1;
        commercial_percentage_lower_limit: 0.05; //各种指标分配关系只是检查项，不参与现金流计算        

        management_fee:0.03
        sales_fee:0.25

        land_cost: 30000; //万元
        land_cost_payment:[1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,.....,0]; //48 months
        land_cost_payment_valid: land_cost_payment.sum ===1;
        unsaleable_amenity_cost: 5000; //万元
        unsaleable_amenity_cost_payment: [0,0,0.1,0,0,0.1,0,0,0.1,0,0,0.1,0,0,0.1,0,0,0.1,0,0,0.1,0,0,0.1,0,0,0.1,0,0,0.1,....,0] ; //48 months
        unsaleable_amenity_cost_payment_valid: land_cost_payment.sum ===1?


        product_baseline_unit_cost_before_allocation: 5500, //元/平米
        basement_unit_cost_before_allocation: 3400; //元/平米

        VAT_surchage_rate: 0.0025; //增值税附加税，包括城市维护建设税，教育费附加，地方教育附加之类
        corp_pretax_gross_profit_rate_threshould: 0.15; //所得税预征收毛利率
        corp_tax_rate:0.25; //企业所得税率
        LVIT_provisional_rate:0.02; //土地增值税预缴税率
    };

    apartment_category_list: ["叠拼","洋房","小高层","大高","超高"] //按核心筒分类，小于11层为洋房，12到18层为小高，大于18层小于100米为大高，大于100米为超高

    apartment_types:[
        {
            apartment_category: "小高层"; //choose from apartment_category_list
            area: 110;
            tag: "标准层";
            apartment_type_name:  area + apartment_category + tag; 
            product_baseline_unit_cost_before_allocation: 5500, //元/平米, this value overwrite the value in the input
            width: 10.8; //m
            depth: 11.0; //m
            color: #yellow; //lerp from yellow to blue, 70sqm-160sqm
            sales_scenes:[
                {
                    price: 10000; //yuan per sqm
                    volumn: 15; //units per month
                }, 
                {
                    price: 11000; //yuan per sqm
                    volumn: 11; //units per month
                },
                {
                    price: 12000; //yuan per sqm
                    volumn: 3; //units per month
                }
            ]; //sales_scenes starts from one scene, create a button to add one more scene, and a button to remove the scene, unless there's only one left
        },
        // a dialog deals with one apartment type. clicking the icon creates a new apartment type, and you can load the existing types from a drop list, modify and save the type in the panel.  
        {}
    ];

    building_types:[
        {
            floor_types:[
                {
                    
                },
            ]
        }
    ]

}

sketchup_model_entities : traverse the model and find all component instances that present in build_type_names 

            

monthlyIncome = function();

stock = [];
stock[0] = 0;

<!-- apartment types,  -->
monthlyOutcome

cashflow = []  <!-- Array of 48 month -->

accumulated_cashflow = []

地价分摊简化版，按品类，比如：
    商业类*3
    洋房*1.5
    小高*1
    持有/3
跨期公摊，合并给地价

traverse the model, find all instances of the building types, check when the apartments each contains are added to the stock. n = Construction Init Time + Sales Permit Time. at month[n], all the apartment stocks are added to the current stock, the apartment stocks should be counted type by type. 

the apartment stock should be an array of 48 month, it has actually three values for each type of apartment: one, the reminding stock from the last month, for month[0], it starts with 0. two, its stock added this month, if there's a building acquires sales permit this month ( n = Construction Init Time + Sales Permit Time), and remember, each type of apartment has one or more sales scene. the current apartment stock are sold to the customer at the speed of the first scene. you can sell more than you have in the stock. so the actual sales is no greater than the current stock. we sell the apartments, which reduces the current stock and create a positive cash flow inward, at the unit prices * area of each apartment type.

each_apartment_type_stock

income_each_period = 

I have a few apartment types, show me a code to calculate the stock added and sold for each period. you take consideration of when the building instance inits construction, when it gets selling permit (added to sellable stock). and at what velocity is the stock sold (per sales scene). give me a way to calculate this, as a part of the cashflow code. the sales income should be the number_of_unit_of_the_apartment * area_per_apartment  apartment_unit_price ** velocity_of_selling, which is an income cashflow

ok, so now, using a similar logic, we can put the sales income and expenses for the basement. the parking lots are generic, having a price (requiring adding an entry in the input dialog"parking lot average price"), the basement object add parking lot stocks when it receives sales permit (construction init months + sales permit months), and they sell at a velocity (requiring adding an entry in the input dialog"parking lot sales velocity"). sales activity consumes parking lot stock until depletion. the basement also requires construction cost = basement area * Basement Unit Cost(input) . its payment happen as a lampsum at the construction init time. 

you should modify the input dialog to accomodate the new input, add stock logic, income and expense logic of the basements in the cashflow code. and put them into the output along with the existing items.

we need to add a logic, which is:

when we need to allocate the total land cost to all apartment types. 

each apartment types has a width and a category, which is one of the following,

the land cost weight of an apartment type should be width/categoty_factor:

type: categoty_factor;

联排: 0.6

叠拼: 0.8

洋房: 1.4

小高层: 2.0

大高: 3.0

超高: 6

商铺: 1

办公: 5

公寓: 4

you should can't the total area of each apartment type in the stock, find out its categoy, multiply its total area to the category factor, to get the total weight, then you get the total landcost the apartment type is allocated to. apartment_type_land_cost =  allocated_land_cost_on_type/apartment_type_total_number. 

this apartment_type_land_cost is a changing attribute to the apartment type which has to do with the whole situation in the model. It should be updated when the output dialog is called.

buy getting the nominal landcost of each apartment type. we can calculate the landcost on the sold unit in each peroid and be able to calculate the profit and taxation.

### supervision

I need to add a logic of fund supervision. each building instance in the model is required a fund in the government. which is the supervisionFundPercentage * the building's construction cost. this fund is release back to the developer based on its supervisionFundReleaseSchedule, which is the number of months after its construction init. so the supervised fund sum reduced over time. when buyers buy apartments (not parking lots), the money by default goes to the supervision fund, and a comparison is made to see if the total fund has reached its required amount. the fund collects the money from the buyers first until it reaches it required amount, then the money can go to the developer. it will also be released to the developer when the construction carries on.

do you understand this logic. it has a lot to do with the de facto cashflow of the developer, and should be considered in the formula.
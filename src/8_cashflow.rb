require_relative '8_land_cost_allocator'
require_relative '0_default_values'

module Real_Estate_Optimizer
  module CashFlowCalculator

    def self.calculate_irr(cashflow, precision = 0.00001, max_iterations = 100)
      # Check if IRR can be calculated
      return nil unless irr_calculable?(cashflow)
    
      rate1 = 0.1
      rate2 = 0.2
      npv1 = npv(cashflow, rate1)
      npv2 = npv(cashflow, rate2)
      max_iterations.times do |iteration|
        if (npv2 - npv1).abs < precision
          return rate2
        end
        rate_new = rate2 - npv2 * (rate2 - rate1) / (npv2 - npv1)
        if (rate_new - rate2).abs < precision
          return rate_new
        end
        rate1, rate2 = rate2, rate_new
        npv1, npv2 = npv2, npv(cashflow, rate2)
      end
      puts "IRR calculation did not converge"
      nil
    end
    
    def self.npv(cashflow, rate)
      npv = 0
      cashflow.each_with_index do |cf, t|
        npv += cf / ((1 + rate) ** t)
      end
      npv
    end
    
    def self.irr_calculable?(cashflow)
      # Check if there's at least one positive and one negative cash flow
      pos = neg = false
      cashflow.each do |cf|
        pos = true if cf > 0
        neg = true if cf < 0
        break if pos && neg
      end
      
      if pos && neg
        puts "Cashflow has both positive and negative values. IRR can be calculated."
        return true
      else
        puts "Cashflow does not have both positive and negative values. IRR cannot be calculated."
        return false
      end
    end
    
    def self.format_number(number)
      whole_number = number.to_i
      whole_number.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
    end

    def self.get_land_cost_payment_schedule
      model = Sketchup.active_model
      project_data = JSON.parse(model.get_attribute('project_data', 'data') || '{}')
      land_cost_payment_schedule = project_data['inputs'] && project_data['inputs']['land_cost_payment'] || []
      
      puts "Land Cost Payment Schedule: #{land_cost_payment_schedule.inspect}"
      land_cost_payment_schedule
    end

    def self.get_land_cost_payments
      project_data = get_project_data_with_defaults
      inputs = project_data['inputs']
      
      land_cost = inputs['land_cost'] * 10000
      payment_schedule = inputs['land_cost_payment']
      
      # Calculate payments
      payments = payment_schedule.map { |percentage| land_cost * percentage }
      
      puts "Land Cost: #{land_cost}"
      puts "Payment Schedule: #{payment_schedule.inspect}"
      puts "Land Cost Payments: #{payments.inspect}"
      
      payments
    end

    def self.get_project_data_with_defaults
      model = Sketchup.active_model
      project_data = JSON.parse(model.get_attribute('project_data', 'data', '{}'))
      
      # Merge with defaults
      default_inputs = Real_Estate_Optimizer::DefaultValues::PROJECT_DEFAULTS[:inputs]
      project_data['inputs'] = default_inputs.merge(project_data['inputs'] || {})
      
      project_data
    end

    def self.print_building_instances_properties
      model = Sketchup.active_model
      entities = model.active_entities
    
      puts "Traversing building instances in the model:"
      
      entities.grep(Sketchup::ComponentInstance).each do |instance|
        puts "\nBuilding Instance: #{instance.definition.name}"
        
        # Check if it's a building instance
        if instance.definition.attribute_dictionaries && instance.definition.attribute_dictionaries['building_data']
          puts "  This is a confirmed building instance."
          
          # Print building data
          building_data = instance.definition.attribute_dictionary('building_data')
          building_data.each do |key, value|
            puts "  #{key}: #{value}"
          end
          
          # Print dynamic attributes
          dynamic_attrs = instance.attribute_dictionary('dynamic_attributes')
          if dynamic_attrs
            puts "  Dynamic Attributes:"
            dynamic_attrs.each do |key, value|
              puts "    #{key}: #{value}"
            end
          else
            puts "  No dynamic attributes found."
          end
        else
          puts "  This is not a building instance (no 'building_data' attribute dictionary)."
        end
      end
    end

    def self.calculate_and_print_stocks_table
      model = Sketchup.active_model
      project_data = JSON.parse(model.get_attribute('project_data', 'data') || '{}')
      building_instances = model.active_entities.grep(Sketchup::ComponentInstance).select do |instance|
        instance.definition.attribute_dictionaries && instance.definition.attribute_dictionaries['building_data']
      end

      stocks_table = Hash.new { |h, k| h[k] = Array.new(72, 0) }

      building_instances.each do |instance|
        building_data = instance.definition.attribute_dictionary('building_data')
        dynamic_attrs = instance.attribute_dictionary('dynamic_attributes')

        next unless building_data && dynamic_attrs

        apartment_stocks = JSON.parse(building_data['apartment_stocks'])
        construction_init_time = dynamic_attrs['construction_init_time'].to_i
        sales_permit_time = dynamic_attrs['sales_permit_time'].to_i

        market_entry_month = construction_init_time + sales_permit_time
        next if market_entry_month >= 72

        apartment_stocks.each do |apt_type, count|
          stocks_table[apt_type][market_entry_month] += count
        end
      end

      puts "Apartment Stocks Table (72 months):"
      puts "Month | " + stocks_table.keys.join(" | ")
      
      (0...72).each do |month|
        row = [month.to_s.rjust(5)]
        stocks_table.each_value do |stocks|
          row << stocks[month].to_s.rjust(5)
        end
        puts row.join(" | ")
      end

      stocks_table
    end

 
    def self.calculate_and_print_construction_cost_table
      model = Sketchup.active_model
      building_instances = model.active_entities.grep(Sketchup::ComponentInstance).select do |instance|
        instance.definition.attribute_dictionaries && instance.definition.attribute_dictionaries['building_data']
      end
    
      construction_payments = Array.new(72, 0)
    
      building_instances.each do |instance|
        building_data = instance.definition.attribute_dictionary('building_data')
        dynamic_attrs = instance.attribute_dictionary('dynamic_attributes')
    
        next unless building_data && dynamic_attrs
    
        total_cost = building_data['total_cost'].to_f
        construction_init_time = dynamic_attrs['construction_init_time'].to_i
    
        # Fetch the construction payment schedule
        project_data = JSON.parse(model.get_attribute('project_data', 'data') || '{}')
        payment_schedule = if project_data['inputs'] && project_data['inputs']['construction_payment_schedule']
                              project_data['inputs']['construction_payment_schedule']
                            else
                              Real_Estate_Optimizer::DefaultValues::PROJECT_DEFAULTS[:inputs][:construction_payment_schedule]
                            end
    
        payment_schedule.each_with_index do |percentage, month|
          payment_month = construction_init_time + month
          break if payment_month >= 72
          construction_payments[payment_month] += total_cost * percentage
        end
      end
    
      puts "Construction Cost Payment Table (72 months):"
      puts "Month | Payment"
      construction_payments.each_with_index do |payment, month|
        puts "#{month.to_s.rjust(5)} | #{payment.round(2)}"
      end
    
      construction_payments
    end

    def self.calculate_and_print_sales_table
      model = Sketchup.active_model
      building_instances = model.active_entities.grep(Sketchup::ComponentInstance).select do |instance|
        instance.definition.attribute_dictionaries && instance.definition.attribute_dictionaries['building_data']
      end

      # Initialize sales and stock tables
      sales_table = Hash.new { |h, k| h[k] = Array.new(72, 0) }
      stock_table = Hash.new { |h, k| h[k] = Array.new(72, 0) }

      # Populate stock table
      building_instances.each do |instance|
        building_data = instance.definition.attribute_dictionary('building_data')
        dynamic_attrs = instance.attribute_dictionary('dynamic_attributes')

        next unless building_data && dynamic_attrs

        apartment_stocks = JSON.parse(building_data['apartment_stocks'])
        construction_init_time = dynamic_attrs['construction_init_time'].to_i
        sales_permit_time = dynamic_attrs['sales_permit_time'].to_i

        market_entry_month = construction_init_time + sales_permit_time
        next if market_entry_month >= 72

        apartment_stocks.each do |apt_type, count|
          stock_table[apt_type][market_entry_month] += count
        end
      end

      # Calculate sales based on stock and sales scenes
      stock_table.each do |apt_type, stocks|
        apt_data = JSON.parse(model.get_attribute('aparment_type_data', apt_type) || '{}')
        sales_scene = apt_data['sales_scenes'] && apt_data['sales_scenes'].first

        if sales_scene
          monthly_sales_volume = sales_scene['volumn'].to_i
          current_stock = 0

          (0...72).each do |month|
            current_stock += stocks[month]
            actual_sales = [current_stock, monthly_sales_volume].min
            sales_table[apt_type][month] = actual_sales
            current_stock -= actual_sales
          end
        end
      end

      # Print sales table
      puts "Apartment Sales Table (72 months):"
      puts "Month | " + sales_table.keys.join(" | ")
      
      (0...72).each do |month|
        row = [month.to_s.rjust(5)]
        sales_table.each_value do |sales|
          row << sales[month].to_s.rjust(5)
        end
        puts row.join(" | ")
      end

      sales_table
    end


    def self.calculate_and_print_income_table
      model = Sketchup.active_model
      building_instances = model.active_entities.grep(Sketchup::ComponentInstance).select do |instance|
        instance.definition.attribute_dictionaries && instance.definition.attribute_dictionaries['building_data']
      end

      # Initialize sales, stock, and income tables
      sales_table = Hash.new { |h, k| h[k] = Array.new(72, 0) }
      stock_table = Hash.new { |h, k| h[k] = Array.new(72, 0) }
      income_table = Hash.new { |h, k| h[k] = Array.new(72, 0) }
      total_income = Array.new(72, 0)

      # Populate stock table
      building_instances.each do |instance|
        building_data = instance.definition.attribute_dictionary('building_data')
        dynamic_attrs = instance.attribute_dictionary('dynamic_attributes')

        next unless building_data && dynamic_attrs

        apartment_stocks = JSON.parse(building_data['apartment_stocks'])
        construction_init_time = dynamic_attrs['construction_init_time'].to_i
        sales_permit_time = dynamic_attrs['sales_permit_time'].to_i

        market_entry_month = construction_init_time + sales_permit_time
        next if market_entry_month >= 72

        apartment_stocks.each do |apt_type, count|
          stock_table[apt_type][market_entry_month] += count
        end
      end

      # Calculate sales and income based on stock and sales scenes
      stock_table.each do |apt_type, stocks|
        apt_data = JSON.parse(model.get_attribute('aparment_type_data', apt_type) || '{}')
        sales_scene = apt_data['sales_scenes'] && apt_data['sales_scenes'].first

        if sales_scene
          monthly_sales_volume = sales_scene['volumn'].to_i
          unit_price = sales_scene['price'].to_f
          area = apt_data['area'].to_f
          current_stock = 0

          (0...72).each do |month|
            current_stock += stocks[month]
            actual_sales = [current_stock, monthly_sales_volume].min
            sales_table[apt_type][month] = actual_sales
            income_table[apt_type][month] = actual_sales * unit_price * area
            total_income[month] += income_table[apt_type][month]
            current_stock -= actual_sales
          end
        end
      end

      # Print income table
      puts "Monthly Income Table (72 months):"
      puts "Month | " + income_table.keys.join(" | ") + " | Total"
      
      (0...72).each do |month|
        row = [month.to_s.rjust(5)]
        income_table.each_value do |income|
          row << income[month].round(2).to_s.rjust(10)
        end
        row << total_income[month].round(2).to_s.rjust(10)
        puts row.join(" | ")
      end

      {income_table: income_table, total_income: total_income}
    end

    def self.calculate_supervision_fund_requirement(building_instances)
      total_fund_requirement = Array.new(72, 0)

      building_instances.each do |instance|
        building_data = instance.definition.attribute_dictionary('building_data')
        dynamic_attrs = instance.attribute_dictionary('dynamic_attributes')
        next unless building_data && dynamic_attrs
        next if dynamic_attrs['basement_type'] # Skip basement instances

        construction_cost = building_data['total_cost'].to_f
        supervision_fund_percentage = building_data['supervisionFundPercentage'].to_f
        construction_init_time = dynamic_attrs['construction_init_time'].to_i
        release_schedule = building_data['supervisionFundReleaseSchedule'] || []

        total_instance_requirement = construction_cost * supervision_fund_percentage
        instance_requirement = Array.new(72, 0)

        puts "\nDebug: Building #{instance.definition.name}"
        puts "  Construction cost: #{construction_cost}"
        puts "  Supervision fund percentage: #{supervision_fund_percentage}"
        puts "  Construction init time: #{construction_init_time}"
        puts "  Total requirement: #{total_instance_requirement}"
        puts "  Release schedule: #{release_schedule.inspect}"

        # Set initial requirement
        (construction_init_time...72).each do |month|
          instance_requirement[month] = total_instance_requirement
        end

        # Apply releases
        release_schedule.each_with_index do |percentage, month|
          actual_month = construction_init_time + month
          break if actual_month >= 72
          release_amount = total_instance_requirement * percentage
          ((actual_month + 1)...72).each do |m|
            instance_requirement[m] -= release_amount
          end
        end

        # Add this instance's requirement to the total
        total_fund_requirement = total_fund_requirement.zip(instance_requirement).map { |a, b| a + b }
      end

      total_fund_requirement
    end

    def self.calculate_and_print_full_cashflow_table
      model = Sketchup.active_model
      project_data = get_project_data_with_defaults
      inputs = project_data['inputs']
    
      land_cost = (inputs['land_cost'] || 0) * 10000
      land_cost_payment_schedule = inputs['land_cost_payment'] || Array.new(72, 0)
      unsaleable_amenity_cost = (inputs['unsaleable_amenity_cost'] || 0) * 10000
      unsaleable_amenity_cost_payment_schedule = inputs['unsaleable_amenity_cost_payment'] || Array.new(72, 0)
    
      building_instances = model.active_entities.grep(Sketchup::ComponentInstance).select do |instance|
        instance.definition.attribute_dictionaries && instance.definition.attribute_dictionaries['building_data']
      end
    
      supervision_fund_requirements = calculate_supervision_fund_requirement(building_instances)
      supervision_fund_balance = 0
    
      income_data = calculate_sales_income
      apartment_income = income_data[:income_table].values.transpose.map { |month_incomes| month_incomes.inject(0, :+) }
      construction_payments = calculate_construction_payments
      basement_cashflows = calculate_basement_cashflows
    
      monthly_cashflow = Array.new(72, 0)
      accumulated_cashflow = Array.new(72, 0)
    
      puts "Month | Apartment Sales | Fund Requirement | Fund Balance | Fund Contribution | Fund Release | Other Income | Expenses | Net Cashflow | Accumulated Cashflow"
    
      (0...72).each do |month|
        current_requirement = supervision_fund_requirements[month]
        
        # Check if fund balance exceeds the requirement and release excess
        fund_release = 0
        if supervision_fund_balance > current_requirement
          fund_release = supervision_fund_balance - current_requirement
          supervision_fund_balance = current_requirement
        end
    
        apartment_sales = apartment_income[month] || 0
        
        # Calculate fund contribution
        fund_contribution = 0
        if supervision_fund_balance < current_requirement
          fund_contribution = [current_requirement - supervision_fund_balance, apartment_sales].min
          supervision_fund_balance += fund_contribution
        end
    
        land_payment = land_cost * (land_cost_payment_schedule[month] || 0)
        unsaleable_amenity_payment = unsaleable_amenity_cost * (unsaleable_amenity_cost_payment_schedule[month] || 0)
        construction_payment = construction_payments[month] || 0
        basement_income = basement_cashflows[:income][month] || 0
        basement_expense = basement_cashflows[:expenses][month] || 0
    
        other_income = basement_income
        expenses = land_payment + unsaleable_amenity_payment + construction_payment + basement_expense
    
        net_income = apartment_sales + other_income + fund_release - fund_contribution - expenses
        monthly_cashflow[month] = net_income
        accumulated_cashflow[month] = (month > 0 ? accumulated_cashflow[month-1] : 0) + monthly_cashflow[month]
    
        puts "#{month.to_s.rjust(3)} | #{format_number(apartment_sales).rjust(15)} | #{format_number(current_requirement).rjust(16)} | #{format_number(supervision_fund_balance).rjust(12)} | #{format_number(fund_contribution).rjust(18)} | #{format_number(fund_release).rjust(12)} | #{format_number(other_income).rjust(12)} | #{format_number(expenses).rjust(8)} | #{format_number(net_income).rjust(12)} | #{format_number(accumulated_cashflow[month]).rjust(21)}"

      end
      puts "Monthly cashflow: #{monthly_cashflow.inspect}"
      monthly_irr = calculate_irr(monthly_cashflow)
      if monthly_irr
        yearly_irr = (1 + monthly_irr)**12 - 1
        puts "Monthly IRR: #{monthly_irr}"
        puts "Yearly IRR: #{(yearly_irr * 100).round(2)}%"
      else
        puts "IRR could not be calculated"
      end

      discount_rate = inputs['discount_rate'] || 0.09
      monthly_discount_rate = (1 + discount_rate)**(1.0/12) - 1
      puts "Discount rate: #{discount_rate}, Monthly discount rate: #{monthly_discount_rate}"
      npv = npv(monthly_cashflow, monthly_discount_rate)

      puts "Project Financial Analysis:"
      puts "NPV: #{format_number(npv)}"
      puts "Yearly IRR: #{monthly_irr ? "#{(yearly_irr * 100).round(2)}%" : 'N/A'}"
    
      {
        monthly_cashflow: monthly_cashflow,
        accumulated_cashflow: accumulated_cashflow,
        supervision_fund_balance: supervision_fund_balance,
        total_fund_requirement: supervision_fund_requirements.last
      }
      
    end
    
    def self.calculate_basement_cashflows
      model = Sketchup.active_model
      project_data = JSON.parse(model.get_attribute('project_data', 'data') || '{}')
      inputs = project_data['inputs'] || {}
    
      parking_lot_price = (inputs['parking_lot_average_price'] || 0) 
      parking_lot_velocity = inputs['parking_lot_sales_velocity'] || 0
      basement_unit_cost = inputs['basement_unit_cost_before_allocation'] || 0
    
      income = Array.new(72, 0)
      expenses = Array.new(72, 0)
      parking_lot_stock = Array.new(72, 0)
    
      model.active_entities.grep(Sketchup::ComponentInstance).each do |instance|
        next unless instance.definition.get_attribute('dynamic_attributes', 'basement_type')
    
        construction_init_time = instance.definition.get_attribute('dynamic_attributes', 'construction_init_time').to_i
        sales_permit_time = instance.definition.get_attribute('dynamic_attributes', 'sales_permit_time').to_i
        parking_lots = instance.definition.get_attribute('dynamic_attributes', 'parking_lot_number').to_i
        basement_area = instance.definition.get_attribute('dynamic_attributes', 'basement_area').to_f
    
        # Calculate basement construction cost
        basement_cost = basement_area * basement_unit_cost
    
        # Add basement construction cost as a one-time expense at Construction Init Time
        expenses[construction_init_time] += basement_cost if construction_init_time < 72
    
        # Add parking lots to stock when sales permit is obtained
        market_entry_month = construction_init_time + sales_permit_time
        parking_lot_stock[market_entry_month] += parking_lots if market_entry_month < 72
    
        # Calculate parking lot sales
        (market_entry_month...72).each do |month|
          available_stock = parking_lot_stock[month]
          sales = [available_stock, parking_lot_velocity].min
          income[month] += sales * parking_lot_price
          parking_lot_stock[month + 1] = available_stock - sales if month < 47
        end
      end
    
      {income: income, expenses: expenses, parking_lot_stock: parking_lot_stock}
    end


    def self.calculate_construction_payments
      model = Sketchup.active_model
      building_instances = model.active_entities.grep(Sketchup::ComponentInstance).select do |instance|
        instance.definition.attribute_dictionaries && instance.definition.attribute_dictionaries['building_data']
      end
    
      construction_payments = Array.new(72, 0)
    
      building_instances.each do |instance|
        building_data = instance.definition.attribute_dictionary('building_data')
        dynamic_attrs = instance.attribute_dictionary('dynamic_attributes')
    
        next unless building_data && dynamic_attrs
    
        total_cost = building_data['total_cost'].to_f
        construction_init_time = dynamic_attrs['construction_init_time'].to_i
    
        project_data = JSON.parse(model.get_attribute('project_data', 'data') || '{}')
        payment_schedule = if project_data['inputs'] && project_data['inputs']['construction_payment_schedule']
                             project_data['inputs']['construction_payment_schedule']
                           else
                             [0.1, 0, 0.2, 0, 0, 0, 0.2, 0, 0, 0, 0, 0, 0.1, 0, 0, 0, 0, 0, 0.1, 0, 0, 0, 0, 0, 0.1, 0, 0, 0, 0, 0, 0.1, 0, 0, 0, 0, 0, 0.1]
                           end
    
        payment_schedule.each_with_index do |percentage, month|
          payment_month = construction_init_time + month
          break if payment_month >= 72
          construction_payments[payment_month] += total_cost * percentage
        end
      end
    
      construction_payments
    end
    
    def self.calculate_sales_income
      model = Sketchup.active_model
      building_instances = model.active_entities.grep(Sketchup::ComponentInstance).select do |instance|
        instance.definition.attribute_dictionaries && instance.definition.attribute_dictionaries['building_data']
      end
    
      sales_table = Hash.new { |h, k| h[k] = Array.new(72, 0) }
      stock_table = Hash.new { |h, k| h[k] = Array.new(72, 0) }
      income_table = Hash.new { |h, k| h[k] = Array.new(72, 0) }
      total_income = Array.new(72, 0)
    
      building_instances.each do |instance|
        building_data = instance.definition.attribute_dictionary('building_data')
        dynamic_attrs = instance.attribute_dictionary('dynamic_attributes')
    
        next unless building_data && dynamic_attrs
    
        apartment_stocks = JSON.parse(building_data['apartment_stocks'])
        construction_init_time = dynamic_attrs['construction_init_time'].to_i
        sales_permit_time = dynamic_attrs['sales_permit_time'].to_i
    
        market_entry_month = construction_init_time + sales_permit_time
        next if market_entry_month >= 72
    
        apartment_stocks.each do |apt_type, count|
          stock_table[apt_type][market_entry_month] += count
        end
      end
    
      stock_table.each do |apt_type, stocks|
        apt_data = JSON.parse(model.get_attribute('aparment_type_data', apt_type) || '{}')
        sales_scene = apt_data['sales_scenes'] && apt_data['sales_scenes'].first
    
        if sales_scene
          monthly_sales_volume = sales_scene['volumn'].to_i
          unit_price = sales_scene['price'].to_f
          area = apt_data['area'].to_f
          current_stock = 0
    
          (0...72).each do |month|
            current_stock += stocks[month]
            actual_sales = [current_stock, monthly_sales_volume].min
            sales_table[apt_type][month] = actual_sales
            income_table[apt_type][month] = actual_sales * unit_price * area
            total_income[month] += income_table[apt_type][month]
            current_stock -= actual_sales
          end
        end
      end
    
      {income_table: income_table, total_income: total_income, sales_table: sales_table}
    end

    def self.calculate_monthly_land_cost(sales_table, unit_land_costs)
      monthly_land_cost = Array.new(72, 0)
    
      sales_table.each do |apt_type, monthly_sales|
        unit_land_cost = unit_land_costs[apt_type]
        apartment_data = get_apartment_data(apt_type)
        
        monthly_sales.each_with_index do |sales, month|
          monthly_land_cost[month] += unit_land_cost * apartment_data['area'] * sales
        end
      end
    
      monthly_land_cost
    end
    
    def self.calculate_cashflow
      model = Sketchup.active_model
      cashflow = initialize_cashflow
      building_instances = find_building_instances(model)
      
      puts "Starting calculation of cashflow"
      puts "Total building instances found: #{building_instances.length}"

      building_instances.each do |instance|
        process_building(instance, cashflow)
      end

      
      calculate_sales_and_income(cashflow)
      add_land_cost_payment(cashflow)
      display_cashflow(cashflow)
    end
    
    def self.initialize_cashflow
      {
        expenses: Array.new(72, 0),
        income: Array.new(72, 0),
        apartment_stock: {},
        apartment_sales: {},
        net_cashflow: Array.new(72, 0)
      }
    end

    def self.add_land_cost_payment(cashflow)
      model = Sketchup.active_model
      project_data = JSON.parse(model.get_attribute('project_data', 'data'))
      land_cost = project_data['inputs']['land_cost']
      land_cost_payment_schedule = project_data['inputs']['land_cost_payment']
      
      land_cost_payment_schedule.each_with_index do |percentage, month|
        payment = land_cost * percentage
        cashflow[:expenses][month] += payment
      end
    end
    
    def self.find_building_instances(model)
      puts "Searching for building instances..."
      instances = model.active_entities.grep(Sketchup::ComponentInstance)
      puts "Found #{instances.length} component instances in total."
      
      instances.each do |instance|
        puts "Instance name: #{instance.definition.name}"
        puts "Has 'building_data' attribute dictionary: #{instance.definition.attribute_dictionaries && instance.definition.attribute_dictionaries.include?('building_data')}"
        puts "Has 'apartment_stocks' attribute: #{!instance.definition.get_attribute('building_data', 'apartment_stocks').nil?}"
        puts "---"
      end
    
      building_instances = instances.select do |instance|
        instance.definition.attribute_dictionaries && 
        instance.definition.attribute_dictionaries.include?('building_data') &&
        !instance.definition.get_attribute('building_data', 'apartment_stocks').nil?
      end
      
      puts "Found #{building_instances.length} building instances with required attributes."
      building_instances
    end
    
    def self.process_building(instance, cashflow)
      puts "Processing building instance: #{instance.definition.name}"
      
      building_data = get_building_data(instance)
      construction_init_time = instance.get_attribute('dynamic_attributes', 'construction_init_time').to_i
      sales_permit_time = instance.get_attribute('dynamic_attributes', 'sales_permit_time').to_i
      
      add_building_expenses(cashflow, building_data, construction_init_time)
      add_apartment_stock(cashflow, building_data, construction_init_time + sales_permit_time)
    end
    
    def self.get_building_data(instance)
      building_def = instance.definition
      total_cost = building_def.get_attribute('building_data', 'total_cost')
      apartment_stocks = building_def.get_attribute('building_data', 'apartment_stocks')
      
      building_type_name = building_def.name
      model = Sketchup.active_model
      project_data = JSON.parse(model.get_attribute('project_data', 'data'))
      building_type = project_data['building_types'].find { |bt| bt['name'] == building_type_name }
      
      {
        total_cost: total_cost,
        apartments: apartment_stocks,
        construction_payment_schedule: building_type['constructionPaymentSchedule']
      }
    end
    
    def self.add_building_expenses(cashflow, building_data, construction_init_time)
      total_cost = building_data[:total_cost]
      construction_payment_schedule = building_data[:construction_payment_schedule]
      
      construction_payment_schedule.each_with_index do |percentage, month|
        actual_month = construction_init_time + month
        next if actual_month >= 72
        payment = total_cost * percentage
        cashflow[:expenses][actual_month] += payment
      end
    end
    
    def self.add_apartment_stock(cashflow, building_data, sales_permit_time)
      return if sales_permit_time >= 72
      
      building_data[:apartments].each do |apt_type, count|
        cashflow[:apartment_stock][apt_type] ||= Array.new(72, 0)
        cashflow[:apartment_stock][apt_type][sales_permit_time] += count
      end
    end
    
    def self.calculate_sales_and_income(cashflow)
      cashflow[:apartment_stock].each do |apt_type, stocks|
        apt_data = get_apartment_data(apt_type)
        sales_scene = apt_data['sales_scenes'].first
        area = apt_data['area']
        
        cashflow[:apartment_sales][apt_type] = Array.new(72, 0)
        
        (0...72).each do |month|
          current_stock = stocks[month]
          potential_sales = [current_stock, sales_scene['volumn']].min
          actual_sales = potential_sales # You might want to add some randomness or other factors here
          
          cashflow[:apartment_sales][apt_type][month] = actual_sales
          revenue = actual_sales * sales_scene['price'] * area
          
          cashflow[:income][month] += revenue
          stocks[month] -= actual_sales
          stocks[month + 1] += stocks[month] if month < 47
        end
      end
    end

    def self.display_cashflow(cashflow)
      puts "Month | Expenses | Income | Net Cash Flow | Apartment Stock | Apartment Sales"
      (0...72).each do |month|
        net = cashflow[:income][month] - cashflow[:expenses][month]
        cashflow[:net_cashflow][month] = net
        stock_info = cashflow[:apartment_stock].map { |type, stocks| "#{type}: #{stocks[month]}" }.join(", ")
        sales_info = cashflow[:apartment_sales].map { |type, sales| "#{type}: #{sales[month]}" }.join(", ")
        puts "#{month} | #{cashflow[:expenses][month]} | #{cashflow[:income][month]} | #{net} | #{stock_info} | #{sales_info}"
      end
    end
    
    def self.get_apartment_data(apt_type)
      model = Sketchup.active_model
      JSON.parse(model.get_attribute('aparment_type_data', apt_type, '{}'))
    end

    def self.get_unsaleable_amenity_cost_payments
      model = Sketchup.active_model
      project_data = JSON.parse(model.get_attribute('project_data', 'data') || '{}')
      
      unsaleable_amenity_cost = project_data['inputs'] && project_data['inputs']['unsaleable_amenity_cost'] || 0
      payment_schedule = project_data['inputs'] && project_data['inputs']['unsaleable_amenity_cost_payment'] || []
      
      # Ensure the payment schedule has 72 elements
      payment_schedule = payment_schedule.fill(0, payment_schedule.length...72)
      
      # Calculate payments
      payments = payment_schedule.map { |percentage| unsaleable_amenity_cost * percentage }
      
      puts "Unsaleable Amenity Cost: #{unsaleable_amenity_cost}"
      puts "Payment Schedule: #{payment_schedule.inspect}"
      puts "Unsaleable Amenity Cost Payments: #{payments.inspect}"
      
      payments
    end

  end
  puts "Finished loading CashFlowCalculator module."
end
puts "Finished loading Real_Estate_Optimizer module."
require_relative '8_land_cost_allocator'
require_relative '0_default_values'

module Real_Estate_Optimizer
  module CashFlowCalculator


    def self.get_land_cost_payment_schedule
      model = Sketchup.active_model
      project_data = JSON.parse(model.get_attribute('project_data', 'data') || '{}')
      land_cost_payment_schedule = project_data['inputs'] && project_data['inputs']['land_cost_payment'] || []
      
      puts "Land Cost Payment Schedule: #{land_cost_payment_schedule.inspect}"
      land_cost_payment_schedule
    end

    def self.get_land_cost_payments
      model = Sketchup.active_model
      project_data = JSON.parse(model.get_attribute('project_data', 'data') || '{}')
      
      land_cost = project_data['inputs'] && project_data['inputs']['land_cost'] || 0
      payment_schedule = project_data['inputs'] && project_data['inputs']['land_cost_payment'] || []
      
      # Ensure the payment schedule has 72 elements
      payment_schedule = payment_schedule.fill(0, payment_schedule.length...72)
      
      # Calculate payments
      payments = payment_schedule.map { |percentage| land_cost * percentage }
      
      puts "Land Cost: #{land_cost}"
      puts "Payment Schedule: #{payment_schedule.inspect}"
      puts "Land Cost Payments: #{payments.inspect}"
      
      payments
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
        apt_data = JSON.parse(model.get_attribute('property_data', apt_type) || '{}')
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
        apt_data = JSON.parse(model.get_attribute('property_data', apt_type) || '{}')
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
      fund_requirement = Array.new(72, 0)
      
      building_instances.each do |instance|
        building_data = instance.definition.attribute_dictionary('building_data')
        dynamic_attrs = instance.attribute_dictionary('dynamic_attributes')
        next unless building_data && dynamic_attrs
    
        construction_cost = building_data['total_cost'].to_f
        supervision_fund_percentage = building_data['supervisionFundPercentage'].to_f
        construction_init_time = dynamic_attrs['construction_init_time'].to_i
        release_schedule = building_data['supervisionFundReleaseSchedule'] || []
    
        total_instance_requirement = construction_cost * supervision_fund_percentage
    
        puts "Debug: Building #{instance.definition.name}"
        puts "  Construction cost: #{construction_cost}"
        puts "  Supervision fund percentage: #{supervision_fund_percentage}"
        puts "  Construction init time: #{construction_init_time}"
        puts "  Total requirement: #{total_instance_requirement}"
        puts "  Release schedule: #{release_schedule.inspect}"
    
        # Add the initial requirement at the construction start time
        fund_requirement[construction_init_time] += total_instance_requirement
    
        release_schedule.each_with_index do |percentage, month|
          actual_month = construction_init_time + month
          break if actual_month >= 72
          release_amount = total_instance_requirement * percentage
          fund_requirement[actual_month] -= release_amount
        end
      end
    
      fund_requirement
    end

    def self.calculate_and_print_full_cashflow_table
      model = Sketchup.active_model
      project_data = JSON.parse(model.get_attribute('project_data', 'data') || '{}')
    
      # Get land cost and payment schedule
      inputs = project_data['inputs'] || {}
      land_cost = (inputs['land_cost'] || 0) * 10000 # Convert from wan to yuan
      land_cost_payment_schedule = inputs['land_cost_payment'] || Array.new(72, 0)


      building_instances = model.active_entities.grep(Sketchup::ComponentInstance).select do |instance|
        instance.definition.attribute_dictionaries && instance.definition.attribute_dictionaries['building_data']
      end
    
      supervision_fund_requirements = Array.new(72, 0)
      supervision_fund_releases = Array.new(72, 0)
      supervision_fund_balance = 0
      total_fund_contribution = 0
      total_fund_release = 0
    
      # Calculate initial supervision fund requirements and releases
      building_instances.each do |instance|
        building_data = instance.definition.attribute_dictionary('building_data')
        dynamic_attrs = instance.attribute_dictionary('dynamic_attributes')
        next unless building_data && dynamic_attrs

        construction_cost = building_data['total_cost'].to_f
        supervision_fund_percentage = dynamic_attrs['supervisionFundPercentage'].to_f
        construction_init_time = dynamic_attrs['construction_init_time'].to_i
        release_schedule = dynamic_attrs['supervisionFundReleaseSchedule'] || []

        total_requirement = construction_cost * supervision_fund_percentage
        supervision_fund_requirements[construction_init_time] += total_requirement

        puts "Debug: Building #{instance.definition.name}"
        puts "  Construction cost: #{construction_cost}"
        puts "  Supervision fund percentage: #{supervision_fund_percentage}"
        puts "  Construction init time: #{construction_init_time}"
        puts "  Total requirement: #{total_requirement}"
        puts "  Release schedule: #{release_schedule.inspect}"

        release_schedule.each_with_index do |percentage, month|
          actual_month = construction_init_time + month
          break if actual_month >= 72
          release_amount = total_requirement * percentage
          supervision_fund_releases[actual_month] += release_amount
          puts "  Month #{actual_month}: Release amount: #{release_amount}"
        end
      end

      puts "Debug: Final supervision fund requirements: #{supervision_fund_requirements.inspect}"
      puts "Debug: Final supervision fund releases: #{supervision_fund_releases.inspect}"
    
      # Calculate construction payments
      construction_payments = calculate_construction_payments
    
      # Calculate sales income
      income_data = calculate_sales_income
      total_income = income_data[:total_income] || Array.new(72, 0)
    
      # Calculate basement-related cashflows
      basement_cashflows = calculate_basement_cashflows
    
      # Get unsaleable amenity cost and payment schedule
      unsaleable_amenity_cost = (inputs['unsaleable_amenity_cost'] || 0) * 10000 # Convert from wan to yuan
      unsaleable_amenity_cost_payment_schedule = inputs['unsaleable_amenity_cost_payment'] || Array.new(72, 0)
    
      # Calculate land cost for sold units (for reporting purposes only)
      unit_land_costs = LandCostAllocator.calculate_unit_land_costs
      monthly_land_cost_for_sold_units = calculate_monthly_land_cost(income_data[:sales_table], unit_land_costs)
    
      # Initialize cashflow arrays
      monthly_cashflow = Array.new(72, 0)
      accumulated_cashflow = Array.new(72, 0)
    
      # Calculate cashflow
      (0...72).each do |month|
        land_payment = land_cost * (land_cost_payment_schedule[month] || 0)
        unsaleable_amenity_payment = unsaleable_amenity_cost * (unsaleable_amenity_cost_payment_schedule[month] || 0)
        construction_payment = construction_payments[month] || 0
        income = total_income[month] || 0
        basement_income = basement_cashflows[:income][month] || 0
        basement_expense = basement_cashflows[:expenses][month] || 0
    
        # Calculate supervision fund contribution and release
        required_contribution = [supervision_fund_requirements[month], income].min
        actual_contribution = [required_contribution, supervision_fund_requirements[month] - supervision_fund_balance].min
        supervision_fund_balance += actual_contribution
        total_fund_contribution += actual_contribution
        income -= actual_contribution
    
        fund_release = supervision_fund_releases[month]
        supervision_fund_balance -= fund_release
        total_fund_release += fund_release
        income += fund_release
    
        monthly_cashflow[month] = income + basement_income - land_payment - unsaleable_amenity_payment - construction_payment - basement_expense
        accumulated_cashflow[month] = (month > 0 ? accumulated_cashflow[month-1] : 0) + monthly_cashflow[month]
    
        # Debug print for each month
        puts "Month #{month}: Fund Balance: #{supervision_fund_balance.round(2)}, Contribution: #{actual_contribution.round(2)}, Release: #{fund_release.round(2)}, Requirement: #{supervision_fund_requirements[month].round(2)}"
      end
    
      # Final debug prints
      puts "Total Fund Contribution: #{total_fund_contribution.round(2)}"
      puts "Total Fund Release: #{total_fund_release.round(2)}"
      puts "Final Fund Balance: #{supervision_fund_balance.round(2)}"
    
      # Print cashflow table
      puts "Full Cashflow Table (72 months):"
      puts "Month | Land Payment | Unsaleable Amenity Payment | Construction Payment | Sales Income | Basement Income | Basement Expense | Supervision Fund Balance | Supervision Fund Release | Monthly Cashflow | Accumulated Cashflow"

      (0...72).each do |month|
        land_payment = land_cost * (land_cost_payment_schedule[month] || 0)
        unsaleable_amenity_payment = unsaleable_amenity_cost * (unsaleable_amenity_cost_payment_schedule[month] || 0)
        construction_payment = construction_payments[month] || 0
        income = total_income[month] || 0
        basement_income = basement_cashflows[:income][month] || 0
        basement_expense = basement_cashflows[:expenses][month] || 0
        land_cost_for_sold_units_info = monthly_land_cost_for_sold_units[month] || 0
        fund_release = supervision_fund_releases[month] || 0  # Add this line

        row = [
          month.to_s.rjust(5),
          land_payment.round(2).to_s.rjust(12),
          unsaleable_amenity_payment.round(2).to_s.rjust(26),
          construction_payment.round(2).to_s.rjust(21),
          income.round(2).to_s.rjust(12),
          basement_income.round(2).to_s.rjust(15),
          basement_expense.round(2).to_s.rjust(16),
          supervision_fund_balance.round(2).to_s.rjust(26),
          fund_release.round(2).to_s.rjust(27),
          monthly_cashflow[month].round(2).to_s.rjust(16),
          accumulated_cashflow[month].round(2).to_s.rjust(21)
        ]
        puts row.join(" | ")
      end
    
      result = {
        :monthly_cashflow => monthly_cashflow,
        :accumulated_cashflow => accumulated_cashflow,
        :land_payments => land_cost_payment_schedule.map { |percentage| land_cost * (percentage || 0) },
        :unsaleable_amenity_payments => unsaleable_amenity_cost_payment_schedule.map { |percentage| unsaleable_amenity_cost * (percentage || 0) },
        :construction_payments => construction_payments,
        :total_income => total_income,
        :basement_income => basement_cashflows[:income],
        :basement_expenses => basement_cashflows[:expenses],
        :basement_parking_lot_stock => basement_cashflows[:parking_lot_stock],
        :land_cost_for_sold_units => monthly_land_cost_for_sold_units,
        :supervision_fund_balance => supervision_fund_balance,
        :supervision_fund_release => supervision_fund_releases
      }
    
      # For debugging
      puts "Cashflow data structure:"
      # puts result.inspect
    
      result
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
        apt_data = JSON.parse(model.get_attribute('property_data', apt_type) || '{}')
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
      JSON.parse(model.get_attribute('property_data', apt_type, '{}'))
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
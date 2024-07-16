puts "Starting to load Real_Estate_Optimizer module..."
module Real_Estate_Optimizer
  puts "Starting to load CashFlowCalculator module..."
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
      
      # Ensure the payment schedule has 48 elements
      payment_schedule = payment_schedule.fill(0, payment_schedule.length...48)
      
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
      building_instances = model.active_entities.grep(Sketchup::ComponentInstance).select do |instance|
        instance.definition.attribute_dictionaries && instance.definition.attribute_dictionaries['building_data']
      end

      stocks_table = Hash.new { |h, k| h[k] = Array.new(48, 0) }

      building_instances.each do |instance|
        building_data = instance.definition.attribute_dictionary('building_data')
        dynamic_attrs = instance.attribute_dictionary('dynamic_attributes')

        next unless building_data && dynamic_attrs

        apartment_stocks = JSON.parse(building_data['apartment_stocks'])
        construction_init_time = dynamic_attrs['construction_init_time'].to_i
        sales_permit_time = dynamic_attrs['sales_permit_time'].to_i

        market_entry_month = construction_init_time + sales_permit_time
        next if market_entry_month >= 48

        apartment_stocks.each do |apt_type, count|
          stocks_table[apt_type][market_entry_month] += count
        end
      end

      puts "Apartment Stocks Table (48 months):"
      puts "Month | " + stocks_table.keys.join(" | ")
      
      (0...48).each do |month|
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

      construction_payments = Array.new(48, 0)

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
                              [0.1, 0, 0.2, 0, 0, 0, 0.2, 0, 0, 0, 0, 0, 0.1, 0, 0, 0, 0, 0, 0.1, 0, 0, 0, 0, 0, 0.1, 0, 0, 0, 0, 0, 0.1, 0, 0, 0, 0, 0, 0.1]
                            end

        payment_schedule.each_with_index do |percentage, month|
          payment_month = construction_init_time + month
          break if payment_month >= 48
          construction_payments[payment_month] += total_cost * percentage
        end
      end

      puts "Construction Cost Payment Table (48 months):"
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
      sales_table = Hash.new { |h, k| h[k] = Array.new(48, 0) }
      stock_table = Hash.new { |h, k| h[k] = Array.new(48, 0) }

      # Populate stock table
      building_instances.each do |instance|
        building_data = instance.definition.attribute_dictionary('building_data')
        dynamic_attrs = instance.attribute_dictionary('dynamic_attributes')

        next unless building_data && dynamic_attrs

        apartment_stocks = JSON.parse(building_data['apartment_stocks'])
        construction_init_time = dynamic_attrs['construction_init_time'].to_i
        sales_permit_time = dynamic_attrs['sales_permit_time'].to_i

        market_entry_month = construction_init_time + sales_permit_time
        next if market_entry_month >= 48

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

          (0...48).each do |month|
            current_stock += stocks[month]
            actual_sales = [current_stock, monthly_sales_volume].min
            sales_table[apt_type][month] = actual_sales
            current_stock -= actual_sales
          end
        end
      end

      # Print sales table
      puts "Apartment Sales Table (48 months):"
      puts "Month | " + sales_table.keys.join(" | ")
      
      (0...48).each do |month|
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
      sales_table = Hash.new { |h, k| h[k] = Array.new(48, 0) }
      stock_table = Hash.new { |h, k| h[k] = Array.new(48, 0) }
      income_table = Hash.new { |h, k| h[k] = Array.new(48, 0) }
      total_income = Array.new(48, 0)

      # Populate stock table
      building_instances.each do |instance|
        building_data = instance.definition.attribute_dictionary('building_data')
        dynamic_attrs = instance.attribute_dictionary('dynamic_attributes')

        next unless building_data && dynamic_attrs

        apartment_stocks = JSON.parse(building_data['apartment_stocks'])
        construction_init_time = dynamic_attrs['construction_init_time'].to_i
        sales_permit_time = dynamic_attrs['sales_permit_time'].to_i

        market_entry_month = construction_init_time + sales_permit_time
        next if market_entry_month >= 48

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

          (0...48).each do |month|
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
      puts "Monthly Income Table (48 months):"
      puts "Month | " + income_table.keys.join(" | ") + " | Total"
      
      (0...48).each do |month|
        row = [month.to_s.rjust(5)]
        income_table.each_value do |income|
          row << income[month].round(2).to_s.rjust(10)
        end
        row << total_income[month].round(2).to_s.rjust(10)
        puts row.join(" | ")
      end

      {income_table: income_table, total_income: total_income}
    end



    def self.calculate_and_print_full_cashflow_table
      model = Sketchup.active_model
      project_data = JSON.parse(model.get_attribute('project_data', 'data') || '{}')

      # Get land cost and payment schedule
      inputs = project_data['inputs'] || {}
      land_cost = (inputs['land_cost'] || 0) * 10000 # Convert from wan to yuan
      land_cost_payment_schedule = inputs['land_cost_payment'] || Array.new(48, 0)

      # Calculate construction payments
      construction_payments = calculate_construction_payments

      # Calculate sales income
      income_data = calculate_sales_income
      total_income = income_data[:total_income]

      # Initialize cashflow arrays
      monthly_cashflow = Array.new(48, 0)
      accumulated_cashflow = Array.new(48, 0)

      # Calculate cashflow
      (0...48).each do |month|
        land_payment = land_cost * land_cost_payment_schedule[month]
        construction_payment = construction_payments[month]
        income = total_income[month]

        monthly_cashflow[month] = income - land_payment - construction_payment
        accumulated_cashflow[month] = (month > 0 ? accumulated_cashflow[month-1] : 0) + monthly_cashflow[month]
      end

      # Print cashflow table (you can keep or remove this part)
      puts "Full Cashflow Table (48 months):"
      puts "Month | Land Payment | Construction Payment | Sales Income | Monthly Cashflow | Accumulated Cashflow"
      
      (0...48).each do |month|
        land_payment = land_cost * land_cost_payment_schedule[month]
        construction_payment = construction_payments[month]
        income = total_income[month]

        row = [
          month.to_s.rjust(5),
          land_payment.round(2).to_s.rjust(12),
          construction_payment.round(2).to_s.rjust(21),
          income.round(2).to_s.rjust(12),
          monthly_cashflow[month].round(2).to_s.rjust(16),
          accumulated_cashflow[month].round(2).to_s.rjust(21)
        ]
        puts row.join(" | ")
      end

      result = {
        :monthly_cashflow => monthly_cashflow || [],
        :accumulated_cashflow => accumulated_cashflow || [],
        :land_payments => land_cost_payment_schedule.map { |percentage| land_cost * percentage },
        :construction_payments => construction_payments || [],
        :total_income => total_income || []
      }

      # For debugging
      puts "Cashflow data structure:"
      puts result.inspect

      result
    end
    
   


    def self.calculate_construction_payments
      model = Sketchup.active_model
      building_instances = model.active_entities.grep(Sketchup::ComponentInstance).select do |instance|
        instance.definition.attribute_dictionaries && instance.definition.attribute_dictionaries['building_data']
      end
    
      construction_payments = Array.new(48, 0)
    
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
          break if payment_month >= 48
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
    
      sales_table = Hash.new { |h, k| h[k] = Array.new(48, 0) }
      stock_table = Hash.new { |h, k| h[k] = Array.new(48, 0) }
      income_table = Hash.new { |h, k| h[k] = Array.new(48, 0) }
      total_income = Array.new(48, 0)
    
      building_instances.each do |instance|
        building_data = instance.definition.attribute_dictionary('building_data')
        dynamic_attrs = instance.attribute_dictionary('dynamic_attributes')
    
        next unless building_data && dynamic_attrs
    
        apartment_stocks = JSON.parse(building_data['apartment_stocks'])
        construction_init_time = dynamic_attrs['construction_init_time'].to_i
        sales_permit_time = dynamic_attrs['sales_permit_time'].to_i
    
        market_entry_month = construction_init_time + sales_permit_time
        next if market_entry_month >= 48
    
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
    
          (0...48).each do |month|
            current_stock += stocks[month]
            actual_sales = [current_stock, monthly_sales_volume].min
            sales_table[apt_type][month] = actual_sales
            income_table[apt_type][month] = actual_sales * unit_price * area
            total_income[month] += income_table[apt_type][month]
            current_stock -= actual_sales
          end
        end
      end
    
      {income_table: income_table, total_income: total_income}
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
        expenses: Array.new(48, 0),
        income: Array.new(48, 0),
        apartment_stock: {},
        apartment_sales: {},
        net_cashflow: Array.new(48, 0)
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
        next if actual_month >= 48
        payment = total_cost * percentage
        cashflow[:expenses][actual_month] += payment
      end
    end
    
    def self.add_apartment_stock(cashflow, building_data, sales_permit_time)
      return if sales_permit_time >= 48
      
      building_data[:apartments].each do |apt_type, count|
        cashflow[:apartment_stock][apt_type] ||= Array.new(48, 0)
        cashflow[:apartment_stock][apt_type][sales_permit_time] += count
      end
    end
    
    def self.calculate_sales_and_income(cashflow)
      cashflow[:apartment_stock].each do |apt_type, stocks|
        apt_data = get_apartment_data(apt_type)
        sales_scene = apt_data['sales_scenes'].first
        area = apt_data['area']
        
        cashflow[:apartment_sales][apt_type] = Array.new(48, 0)
        
        (0...48).each do |month|
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
      (0...48).each do |month|
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

    #  -- TESTS --

    def self.run_tests
      test_find_building_instances
      test_process_building
      test_add_apartment_stock
      test_calculate_sales_and_income
      test_add_land_cost_payment
      test_full_cashflow
    end

    def self.test_find_building_instances
      model = Sketchup.active_model
      instances = find_building_instances(model)
      puts "Test: Find Building Instances"
      puts "Found #{instances.length} building instances"
      instances.each { |instance| puts "  - #{instance.definition.name}" }
      puts
    end

    def self.test_process_building
      model = Sketchup.active_model
      instances = find_building_instances(model)
      return if instances.empty?

      puts "Test: Process Building"
      cashflow = initialize_cashflow
      process_building(instances.first, cashflow)
      puts "Processed building: #{instances.first.definition.name}"
      puts "Expenses: #{cashflow[:expenses].sum}"
      puts "Apartment Stock: #{cashflow[:apartment_stock]}"
      puts
    end

    def self.test_add_apartment_stock
      puts "Test: Add Apartment Stock"
      cashflow = initialize_cashflow
      building_data = {apartments: {"110小高层" => 10, "90洋房" => 5}}
      add_apartment_stock(cashflow, building_data, 3)
      puts "Apartment Stock after adding:"
      cashflow[:apartment_stock].each do |type, stock|
        puts "  #{type}: #{stock.join(', ')}"
      end
      puts
    end

    def self.test_calculate_sales_and_income
      puts "Test: Calculate Sales and Income"
      cashflow = initialize_cashflow
      cashflow[:apartment_stock] = {
        "110小高层" => Array.new(48, 10),
        "90洋房" => Array.new(48, 5)
      }
      calculate_sales_and_income(cashflow)
      puts "Income: #{cashflow[:income].sum}"
      puts "Apartment Sales:"
      cashflow[:apartment_sales].each do |type, sales|
        puts "  #{type}: #{sales.join(', ')}"
      end
      puts
    end

    def self.test_add_land_cost_payment
      puts "Test: Add Land Cost Payment"
      cashflow = initialize_cashflow
      add_land_cost_payment(cashflow)
      puts "Land Cost Expenses: #{cashflow[:expenses].sum}"
      puts
    end

    def self.test_full_cashflow
      puts "Test: Full Cashflow Calculation"
      calculate_cashflow
      puts "Full cashflow calculation completed"
      puts
    end
  end
  puts "Finished loading CashFlowCalculator module."
end
puts "Finished loading Real_Estate_Optimizer module."
require_relative '8_land_cost_allocator'
require_relative '0_default_values'
require_relative  '8_traversal_utils'
require_relative '8_financial_calculations'



module Real_Estate_Optimizer
  module CashFlowCalculator
    
    def self.npv(cashflow, rate)
      cashflow.each_with_index.sum do |cf, t|
        cf / ((1 + rate) ** t)
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
      land_cost_payment_schedule
    end

    def self.get_land_cost_payments
      project_data = get_project_data_with_defaults
      inputs = project_data['inputs']
      
      land_cost = inputs['land_cost'] * 10000
      payment_schedule = inputs['land_cost_payment']
      payments = payment_schedule.map { |percentage| land_cost * percentage }
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


    def self.find_property_line_components(model)
      model.active_entities.grep(Sketchup::ComponentInstance).select do |instance|
        instance.definition.name.start_with?('property_line_')
      end
    end

    def self.find_containing_property_line(position, property_lines)
      property_lines.find do |property_line|
        point_in_polygon?(position, property_line)
      end
    end

    def self.get_property_line_data(model)
      property_lines = find_property_line_components(model)
      property_lines.map do |pl|
        {
          name: pl.definition.get_attribute('dynamic_attributes', 'keyword'),
          area: pl.definition.get_attribute('dynamic_attributes', 'property_area').to_f,
          amenity_GFA_in_FAR: pl.definition.get_attribute('dynamic_attributes', 'amenity_GFA_in_FAR').to_f
        }
      end
    end

    def self.point_in_polygon?(point, property_line)
      edges = property_line.definition.entities.grep(Sketchup::Edge)
      vertices = edges.map { |edge| edge.start.position }
      
      x, y = point.x, point.y
      inside = false
      
      j = vertices.size - 1
      (0...vertices.size).each do |i|
        xi, yi = vertices[i].x, vertices[i].y
        xj, yj = vertices[j].x, vertices[j].y
        
        if ((yi > y) != (yj > y)) && (x < (xj - xi) * (y - yi) / (yj - yi) + xi)
          inside = !inside
        end
        
        j = i
      end
      
      inside
    end

    def self.print_building_instances_properties
      model = Sketchup.active_model
      building_instances = TraversalUtils.traverse_building_instances(model)
    
      # puts "Traversing building instances in the model:"
      
      building_instances.each do |instance, transformation|
        # puts "\nBuilding Instance: #{instance.definition.name}"
        # puts "  World Position: #{transformation.origin}"
        
        if instance.definition.attribute_dictionaries && instance.definition.attribute_dictionaries['building_data']
          # puts "  This is a confirmed building instance."
          
          # Print building data
          building_data = instance.definition.attribute_dictionary('building_data')
          building_data.each do |key, value|
            # puts "  #{key}: #{value}"
          end
          
          # Print dynamic attributes
          dynamic_attrs = instance.attribute_dictionary('dynamic_attributes')
          if dynamic_attrs
            # puts "  Dynamic Attributes:"
            dynamic_attrs.each do |key, value|
              # puts "    #{key}: #{value}"
            end
          else
            # puts "  No dynamic attributes found."
          end
    
          # Print associated property line keyword
          property_line_keyword = instance.definition.get_attribute('building_data', 'property_line_keyword')
          # puts "  Associated Property Line: #{property_line_keyword || 'Not associated'}"
        else
          # puts "  This is not a building instance (no 'building_data' attribute dictionary)."
        end
      end
    end
      

    def self.calculate_and_print_income_table
      model = Sketchup.active_model
      building_instances = TraversalUtils.traverse_building_instances(model)

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
        apt_data = JSON.parse(model.get_attribute('apartment_type_data', apt_type) || '{}')
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
      # # puts "Monthly Income Table (72 months):"
      # # puts "Month | " + income_table.keys.join(" | ") + " | Total"
      
      (0...72).each do |month|
        row = [month.to_s.rjust(5)]
        income_table.each_value do |income|
          row << income[month].round(2).to_s.rjust(10)
        end
        row << total_income[month].round(2).to_s.rjust(10)
        # puts row.join(" | ")
      end

      {income_table: income_table, total_income: total_income}
    end

    def self.calculate_supervision_fund_requirement(building_instances)
      total_fund_requirement = Array.new(72, 0)
    
      building_instances.each do |instance, transformation|
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

    def self.generate_standardized_cashflow(monthly_cashflow)
      monthly_cashflow.map { |month| month[:net_cashflow] }
    end

    def self.calculate_fitness_only(schedule, scene_switches, settings)
      # Calculate sales income without UI updates
      income_data = calculate_sales_income(scene_switches)
      return -Float::INFINITY unless income_data
      
      # Calculate cashflow data without HTML generation
      cashflow_data = calculate_core_cashflow(income_data)
      return -Float::INFINITY unless cashflow_data
      
      if settings['optimization_method'] == 'npv'
        monthly_cashflow = cashflow_data[:monthly_cashflow]
        annual_discount_rate = settings['discount_rate']
        monthly_discount_rate = (1 + annual_discount_rate)**(1.0/12) - 1
        CashFlowCalculator.npv(monthly_cashflow, monthly_discount_rate)
      else
        monthly_cashflow = calculate_monthly_cashflow(cashflow_data)
        key_indicators = calculate_key_indicators(monthly_cashflow)
        irr = key_indicators[:yearly_irr] || -100
        moic = key_indicators[:moic] || 0
        scaled_irr = irr/100
        scaled_moic = moic
        (settings['irr_weight'] * scaled_irr + settings['moic_weight'] * scaled_moic)
      end
    end
    
    def self.calculate_core_cashflow(income_data)
      model = Sketchup.active_model
      project_data = get_project_data_with_defaults
      inputs = project_data['inputs']
    
      # Get base financial data
      land_cost = (inputs['land_cost'] || 0) * 10000
      land_cost_payment_schedule = inputs['land_cost_payment'] || Array.new(72, 0)
      unsaleable_amenity_cost = (inputs['unsaleable_amenity_cost'] || 0) * 10000
      unsaleable_amenity_cost_payment_schedule = inputs['unsaleable_amenity_cost_payment'] || Array.new(72, 0)
    
      building_instances = TraversalUtils.traverse_building_instances(model)
      supervision_fund_requirements = calculate_supervision_fund_requirement(building_instances)
      supervision_fund_balance = 0
    
      apartment_income = income_data[:income_table].values.transpose.map { |month_incomes| month_incomes.inject(0, :+) }
      construction_payments = calculate_construction_payments
      basement_cashflows = calculate_basement_cashflows
    
      # Get rates
      management_fee_rate = inputs['management_fee'] || 0
      sales_fee_rate = inputs['sales_fee'] || 0
      lvit_provisional_rate = inputs['LVIT_provisional_rate'] || 0
      vat_surcharge_rate = inputs['VAT_surchage_rate'] || 0
    
      # Initialize arrays
      monthly_cashflow = Array.new(72, 0)
      accumulated_cashflow = Array.new(72, 0)
      fees_and_taxes = Array.new(72, 0)
    
      # Calculate monthly cashflows
      (0...72).each do |month|
        current_requirement = supervision_fund_requirements[month]
        
        # Fund balance adjustments
        fund_release = 0
        if supervision_fund_balance > current_requirement
          fund_release = supervision_fund_balance - current_requirement
          supervision_fund_balance = current_requirement
        end
    
        apartment_sales = apartment_income[month] || 0
        
        fund_contribution = 0
        if supervision_fund_balance < current_requirement
          fund_contribution = [current_requirement - supervision_fund_balance, apartment_sales].min
          supervision_fund_balance += fund_contribution
        end
    
        # Calculate payments and income
        land_payment = land_cost * (land_cost_payment_schedule[month] || 0)
        unsaleable_amenity_payment = unsaleable_amenity_cost * (unsaleable_amenity_cost_payment_schedule[month] || 0)
        construction_payment = construction_payments[month] || 0
        basement_income = basement_cashflows[:income][month] || 0
        basement_expense = basement_cashflows[:expenses][month] || 0
    
        total_income = apartment_sales + basement_income
        
        # Calculate fees
        fees_and_taxes[month] = total_income * (management_fee_rate + sales_fee_rate + 
                                              lvit_provisional_rate + vat_surcharge_rate)
    
        expenses = land_payment + unsaleable_amenity_payment + construction_payment + 
                  basement_expense + fees_and_taxes[month]
    
        # Calculate net cashflow
        net_income = total_income + fund_release - fund_contribution - expenses
        monthly_cashflow[month] = net_income
        accumulated_cashflow[month] = (month > 0 ? accumulated_cashflow[month-1] : 0) + net_income
      end
    
      # Calculate final results including corporate tax
      total_income = apartment_income.sum + basement_cashflows[:income].sum
      total_expenses = fees_and_taxes.sum + construction_payments.sum + 
                      basement_cashflows[:expenses].sum +
                      land_cost_payment_schedule.sum { |p| land_cost * p } +
                      unsaleable_amenity_cost_payment_schedule.sum { |p| unsaleable_amenity_cost * p }
    
      net_profit_before_corporate_tax = total_income - total_expenses
      corporate_tax = [net_profit_before_corporate_tax * 0.25, 0].max
      
      # Apply corporate tax to last month
      monthly_cashflow[71] -= corporate_tax
      accumulated_cashflow[71] -= corporate_tax
    
      {
        monthly_cashflow: monthly_cashflow,
        accumulated_cashflow: accumulated_cashflow,
        corporate_tax: corporate_tax
      }
    end

    def self.calculate_and_print_full_cashflow_table(income_data)
      model = Sketchup.active_model
      project_data = get_project_data_with_defaults
      inputs = project_data['inputs']
    
      land_cost = (inputs['land_cost'] || 0) * 10000
      land_cost_payment_schedule = inputs['land_cost_payment'] || Array.new(72, 0)
      unsaleable_amenity_cost = (inputs['unsaleable_amenity_cost'] || 0) * 10000
      unsaleable_amenity_cost_payment_schedule = inputs['unsaleable_amenity_cost_payment'] || Array.new(72, 0)
    
      building_instances = TraversalUtils.traverse_building_instances(model)
      supervision_fund_requirements = calculate_supervision_fund_requirement(building_instances)
      supervision_fund_balance = 0
    
      apartment_income = income_data[:income_table].values.transpose.map { |month_incomes| month_incomes.inject(0, :+) }
      construction_payments = calculate_construction_payments
      basement_cashflows = calculate_basement_cashflows
      management_fee_rate = inputs['management_fee'] || 0
      sales_fee_rate = inputs['sales_fee'] || 0
      lvit_provisional_rate = inputs['LVIT_provisional_rate'] || 0
      vat_surcharge_rate = inputs['VAT_surchage_rate'] || 0

      monthly_cashflow = Array.new(72, 0)
      accumulated_cashflow = Array.new(72, 0)
      fees_and_taxes = Array.new(72, 0)
      fund_contributions = Array.new(72, 0)
      fund_releases = Array.new(72, 0)
    
      # # puts "Month | Apartment Sales | Fund Requirement | Fund Balance | Fund Contribution | Fund Release | Other Income | Expenses | Fees and Taxes | Net Cashflow | Accumulated Cashflow"

      (0...72).each do |month|
        current_requirement = supervision_fund_requirements[month]
        
        # Check if fund balance exceeds the requirement and release excess
        fund_release = 0
        if supervision_fund_balance > current_requirement
          fund_release = supervision_fund_balance - current_requirement
          supervision_fund_balance = current_requirement
        end
        fund_releases[month] = fund_release

        apartment_sales = apartment_income[month] || 0
        
        # Calculate fund contribution
        fund_contribution = 0
        if supervision_fund_balance < current_requirement
          fund_contribution = [current_requirement - supervision_fund_balance, apartment_sales].min
          supervision_fund_balance += fund_contribution
        end
        fund_contributions[month] = fund_contribution

        land_payment = land_cost * (land_cost_payment_schedule[month] || 0)
        unsaleable_amenity_payment = unsaleable_amenity_cost * (unsaleable_amenity_cost_payment_schedule[month] || 0)
        construction_payment = construction_payments[month] || 0
        basement_income = basement_cashflows[:income][month] || 0
        basement_expense = basement_cashflows[:expenses][month] || 0

        other_income = basement_income
        total_income = apartment_sales + other_income
        management_fee = total_income * management_fee_rate
        sales_fee = total_income * sales_fee_rate
        lvit = total_income * lvit_provisional_rate
        vat_surcharge = total_income * vat_surcharge_rate
        fees_and_taxes[month] = management_fee + sales_fee + lvit + vat_surcharge

        expenses = land_payment + unsaleable_amenity_payment + construction_payment + basement_expense + fees_and_taxes[month]

        net_income = apartment_sales + other_income + fund_release - fund_contribution - expenses
        monthly_cashflow[month] = net_income
        accumulated_cashflow[month] = (month > 0 ? accumulated_cashflow[month-1] : 0) + monthly_cashflow[month]

        print_cashflow_row(
          month,
          apartment_sales,
          current_requirement,
          supervision_fund_balance,
          fund_contribution,
          fund_release,
          other_income,
          expenses,
          fees_and_taxes[month],
          net_income,
          accumulated_cashflow[month]
        )
      end
      
      total_income = apartment_income.sum + basement_cashflows[:income].sum
      total_expenses = land_cost_payment_schedule.sum { |percentage| land_cost * percentage } +
                   unsaleable_amenity_cost_payment_schedule.sum { |percentage| unsaleable_amenity_cost * percentage } +
                   construction_payments.sum +
                   basement_cashflows[:expenses].sum +
                   fees_and_taxes.sum
      
      net_profit_before_corporate_tax = total_income - total_expenses
      corporate_tax = [net_profit_before_corporate_tax * 0.25, 0].max
      
      # Apply corporate tax to the last month
      monthly_cashflow[71] -= corporate_tax
      accumulated_cashflow[71] -= corporate_tax
      
      # # puts "Monthly cashflow: #{monthly_cashflow.inspect}"
      monthly_irr = FinancialCalculations.calculate_irr(monthly_cashflow)
      # # puts "Monthly IRR: #{monthly_irr}"
      if monthly_irr
        yearly_irr = (1 + monthly_irr)**12 - 1
        # # puts "Yearly IRR: #{(yearly_irr * 100).round(2)}%"
      else
        # # puts "IRR could not be calculated"
      end
      
      # Return the data including corporate tax
      {
        monthly_cashflow: monthly_cashflow,
        accumulated_cashflow: accumulated_cashflow,
        supervision_fund_requirements: supervision_fund_requirements,
        fund_contributions: fund_contributions,
        fund_releases: fund_releases,
        income_table: income_data[:income_table],
        basement_income: basement_cashflows[:income],
        land_payments: land_cost_payment_schedule.map { |percentage| land_cost * percentage },
        unsaleable_amenity_payments: unsaleable_amenity_cost_payment_schedule.map { |percentage| unsaleable_amenity_cost * percentage },
        construction_payments: construction_payments,
        fees_and_taxes: fees_and_taxes,
        basement_expenses: basement_cashflows[:expenses],
        corporate_tax: corporate_tax
      }
    end

    def self.print_cashflow_row(*args)
      formatted_args = args.map.with_index do |arg, index|
        width = [3, 15, 16, 12, 18, 12, 12, 8, 13, 12, 21][index]
        format_number(arg).rjust(width)
      end
      # puts formatted_args.join(" | ")
    end

    def self.calculate_monthly_cashflow(cashflow_data)
      total_sales = 0
      total_expenses_without_tax = 0
      total_fees_and_taxes = 0
      corporate_tax = 0
    
      # Change this to force 72 months instead of using map
      monthly_cashflow = Array.new(72) do |month|
        cashflow = cashflow_data[:monthly_cashflow][month] || 0
        apartment_sales = cashflow_data[:income_table].values.inject(0) { |sum, v| sum + v[month] }
        fund_requirement = cashflow_data[:supervision_fund_requirements][month]
        fund_contribution = cashflow_data[:fund_contributions][month]
        fund_release = cashflow_data[:fund_releases][month]
        parking_lot_sales = cashflow_data[:basement_income][month]
        
        total_sales_income = apartment_sales + parking_lot_sales
        total_cash_inflow = total_sales_income + fund_release - fund_contribution
    
        land_fees = cashflow_data[:land_payments][month]
        amenity_cost = cashflow_data[:unsaleable_amenity_payments][month]
        apartment_construction = cashflow_data[:construction_payments][month]
        fees_and_taxes = cashflow_data[:fees_and_taxes][month]
        underground_construction = cashflow_data[:basement_expenses][month]
        
        # Accumulate totals
        total_sales += total_sales_income
        total_expenses_without_tax += land_fees + amenity_cost + apartment_construction + underground_construction
        total_fees_and_taxes += fees_and_taxes
    
        # Calculate VAT re-declaration for the last month
        vat_redeclaration = 0
        if month == 71  # Changed from length-1 to explicit 71
          vat_redeclaration = calculate_vat_redeclaration(total_sales, total_expenses_without_tax)
          fees_and_taxes += vat_redeclaration
        end
    
        total_cash_outflow = land_fees + amenity_cost + apartment_construction + fees_and_taxes + underground_construction
    
        net_cashflow = total_cash_inflow - total_cash_outflow
        accumulated_cashflow = month == 0 ? net_cashflow : cashflow_data[:accumulated_cashflow][month - 1] + net_cashflow
    
        {
          month: month + 1,
          apartment_sales: apartment_sales,
          fund_requirement: fund_requirement,
          fund_contribution: fund_contribution,
          fund_release: fund_release,
          parking_lot_sales: parking_lot_sales,
          total_sales_income: total_sales_income,
          total_cash_inflow: total_cash_inflow,
          land_fees: land_fees,
          amenity_cost: amenity_cost,
          apartment_construction: apartment_construction,
          fees_and_taxes: fees_and_taxes,
          underground_construction: underground_construction,
          total_cash_outflow: total_cash_outflow,
          net_cashflow: net_cashflow,
          accumulated_cashflow: accumulated_cashflow,
          vat_redeclaration: vat_redeclaration,
          corporate_tax: 0  # Removed corporate tax calculation
        }
      end
    
      monthly_cashflow
    end

    def self.calculate_key_indicators(monthly_cashflow)
      # Cache these values since they're used multiple times
      total_income = monthly_cashflow.inject(0) { |sum, month| sum + month[:total_sales_income] }
      total_expense_without_corporate_tax = monthly_cashflow.inject(0) do |sum, month| 
        sum + month[:total_cash_outflow] - month[:corporate_tax]
      end
      total_fees_and_taxes = monthly_cashflow.inject(0) { |sum, month| sum + month[:fees_and_taxes] - month[:corporate_tax] }
      corporate_tax = monthly_cashflow.last[:corporate_tax]
      
      net_profit = total_income - total_expense_without_corporate_tax - corporate_tax
      
      # Optimize IRR calculation
      cashflow_series = monthly_cashflow.map { |month| month[:net_cashflow] }
      monthly_irr = if @last_irr && @last_cashflow_pattern == cashflow_series[0..5]
        # If cashflow pattern similar to last calculation, use last IRR as initial guess
        FinancialCalculations.calculate_irr(cashflow_series)
      else
        # Otherwise calculate normally
        FinancialCalculations.calculate_irr(cashflow_series)
      end
      
      # Cache successful IRR and cashflow pattern for next calculation
      if monthly_irr
        @last_irr = monthly_irr
        @last_cashflow_pattern = cashflow_series[0..5]  # Store first 6 months pattern
      end
      
      yearly_irr = monthly_irr ? ((1 + monthly_irr)**12 - 1) * 100 : nil
      
      # Rest of the calculations remain the same
      gross_profit_margin = ((total_income - total_expense_without_corporate_tax - corporate_tax + total_fees_and_taxes) / total_income * 100).round(2)
      net_profit_margin = (net_profit / total_income * 100).round(2)
      
      cash_flow_positive_month = monthly_cashflow.index { |month| month[:accumulated_cashflow] >= 0 }
      cash_flow_positive_month = cash_flow_positive_month ? cash_flow_positive_month + 1 : 'N/A'
      
      peak_negative_cash_flow = monthly_cashflow.map { |month| month[:accumulated_cashflow] }.min
      
      total_investment = total_expense_without_corporate_tax + corporate_tax
      
      moic = peak_negative_cash_flow < 0 ? (net_profit / peak_negative_cash_flow.abs).round(2) + 1 : nil
    
      {
        monthly_irr: monthly_irr,
        yearly_irr: yearly_irr,
        gross_profit_margin: gross_profit_margin,
        net_profit_margin: net_profit_margin,
        cash_flow_positive_month: cash_flow_positive_month,
        total_sales: total_income,
        total_investment: total_investment,
        peak_negative_cash_flow: peak_negative_cash_flow,
        net_profit: net_profit,
        moic: moic,
        corporate_tax: corporate_tax
      }
    end

    def self.calculate_moic(schedule)
      monthly_cashflow = calculate_monthly_cashflow(schedule)
      total_income = monthly_cashflow.sum { |month| month[:total_sales_income] }
      total_expense = monthly_cashflow.sum { |month| month[:total_cash_outflow] }
      peak_negative_cash_flow = monthly_cashflow.map { |month| month[:accumulated_cashflow] }.min
      net_profit = total_income - total_expense
      
      peak_negative_cash_flow < 0 ? (net_profit / peak_negative_cash_flow.abs).round(2) + 1 : nil
    end
    
    def self.calculate_vat_redeclaration(total_sales, total_expenses_without_tax)
      deductible_items = total_expenses_without_tax * 1.3
      added_value = total_sales - deductible_items
      added_value_ratio = added_value / deductible_items
    
      # # puts "Total Sales: #{total_sales}"
      # # puts "Total Expenses Without Tax: #{total_expenses_without_tax}"
      # # puts "Deductible Items: #{deductible_items}"
      # # puts "Added Value: #{added_value}"
      # # puts "Added Value Ratio: #{added_value_ratio}"
    
      vat = if added_value_ratio < 0.2
              0
            elsif added_value_ratio < 0.5
              added_value * 0.3
            elsif added_value_ratio < 1
              added_value * 0.4 - deductible_items * 0.05
            elsif added_value_ratio < 2
              added_value * 0.5 - deductible_items * 0.15
            else
              added_value * 0.6 - deductible_items * 0.35
            end
    
      # # puts "Calculated VAT: #{vat}"
      vat
    end

    def self.generate_html_report(cashflow_data)
      monthly_cashflow = calculate_monthly_cashflow(cashflow_data)
      key_indicators = calculate_key_indicators(monthly_cashflow)
    
      discount_rate = get_project_data_with_defaults['inputs']['discount_rate'] || 0.09
      monthly_discount_rate = (1 + discount_rate)**(1.0/12) - 1
      npv = npv(cashflow_data[:monthly_cashflow], monthly_discount_rate)
    
      # Generate HTML report
      html = <<-HTML
        <h3>项目关键指标 Key Project Indicators</h3>
        <table>
          <tr><th>指标 Indicator</th><th>值 Value</th></tr>
          <tr><td>内部收益率 IRR</td><td>#{key_indicators[:yearly_irr] ? "#{key_indicators[:yearly_irr].round(2)}%" : 'N/A'}</td></tr>
          <tr><td>销售毛利率 Gross Profit Margin</td><td>#{key_indicators[:gross_profit_margin]}%</td></tr>
          <tr><td>销售净利率 Net Profit Margin</td><td>#{key_indicators[:net_profit_margin]}%</td></tr>
          <tr><td>现金流回正（月） Cash Flow Positive Month</td><td>#{key_indicators[:cash_flow_positive_month]}</td></tr>
          <tr><td>项目总销售额（含税） Total Sales (incl. tax)</td><td>#{format_number(key_indicators[:total_sales])}</td></tr>
          <tr><td>项目总投资（含税） Total Investment (incl. tax)</td><td>#{format_number(key_indicators[:total_investment])}</td></tr>
          <tr><td>项目资金峰值 Peak Negative Cash Flow</td><td>#{format_number(key_indicators[:peak_negative_cash_flow])}</td></tr>
          <tr><td>企业所得税 Corporate Tax</td><td>#{format_number(key_indicators[:corporate_tax])}</td></tr>
          <tr><td>项目净利润（税后） Net Profit (After Tax)</td><td>#{format_number(key_indicators[:net_profit])}</td></tr>
          <tr><td>MOIC</td><td>#{key_indicators[:moic] ? format('%.3f', key_indicators[:moic]) : 'N/A'}</td></tr>
        </table>
        <h3>财务指标 Financial Metrics</h3>
        <p>基于折现率 Discount Rate: #{(discount_rate * 100).round(2)}%净现值 NPV: #{format_number(npv)}</p>
        <p>年化内部收益率 Yearly IRR: #{key_indicators[:yearly_irr] ? "#{key_indicators[:yearly_irr].round(2)}%" : 'N/A'}</p>
        <h3>现金流报告 Cashflow Report</h3>
        <table>
          <tr>
            <th>月份<br>Month</th>
            <th>计容产品销售收入(万)<br>Apartment Sales</th>
            <th>预售资金监管要求(万)<br>Supervision Fund Requirement</th>
            <th>资金监管存入(万)<br>Fund Contribution</th>
            <th>资金监管解活(万)<br>Fund Release</th>
            <th>车位销售收入(万)<br>Parking Lot Sales</th>
            <th>总销售收入(万)<br>Total Sales Income</th>
            <th>总现金流入小计(万)<br>Total Cash Inflow</th>
            <th>土地规费(万)<br>Land Fees</th>
            <th>配套建设费用(万)<br>Amenity Construction Cost</th>
            <th>计容产品建安费用(万)<br>Apartment Construction Payment</th>
            <th>税费(万)<br>Fees and Taxes</th>
            <th>地下建安费用(万)<br>Underground Construction Cost</th>
            <th>总现金流出小计(万)<br>Total Cash Outflow</th>
            <th>月净现金流(万)<br>Monthly Net Cashflow</th>
            <th>累计净现金流(万)<br>Accumulated Net Cashflow</th>
          </tr>
      HTML
    
      monthly_cashflow.each do |month_data|
        html += "<tr>"
        html += "<td>#{month_data[:month]}</td>"
        html += "<td>#{format_number(month_data[:apartment_sales] / 10000)}</td>"
        html += "<td>#{format_number(month_data[:fund_requirement] / 10000)}</td>"
        html += "<td>#{format_number(month_data[:fund_contribution] / 10000)}</td>"
        html += "<td>#{format_number(month_data[:fund_release] / 10000)}</td>"
        html += "<td>#{format_number(month_data[:parking_lot_sales] / 10000)}</td>"
        html += "<td>#{format_number(month_data[:total_sales_income] / 10000)}</td>"
        html += "<td>#{format_number(month_data[:total_cash_inflow] / 10000)}</td>"
        html += "<td>#{format_number(month_data[:land_fees] / 10000)}</td>"
        html += "<td>#{format_number(month_data[:amenity_cost] / 10000)}</td>"
        html += "<td>#{format_number(month_data[:apartment_construction] / 10000)}</td>"
        html += "<td>#{format_number(month_data[:fees_and_taxes] / 10000)}</td>"
        html += "<td>#{format_number(month_data[:underground_construction] / 10000)}</td>"
        html += "<td>#{format_number(month_data[:total_cash_outflow] / 10000)}</td>"
        html += "<td>#{format_number(month_data[:net_cashflow] / 10000)}</td>"
        html += "<td>#{format_number(month_data[:accumulated_cashflow] / 10000)}</td>"
        html += "</tr>"
      end
    
      html += <<-HTML
        </table>
      
      HTML
    
      html
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
      building_instances = TraversalUtils.traverse_building_instances(model)
    
      construction_payments = Array.new(72, 0)
    
      building_instances.each do |instance, transformation|
        building_data = instance.definition.attribute_dictionary('building_data')
        dynamic_attrs = instance.attribute_dictionary('dynamic_attributes')
    
        next unless building_data && dynamic_attrs
    
        total_cost = building_data['total_cost'].to_f
        construction_init_time = dynamic_attrs['construction_init_time'].to_i
    
        project_data = JSON.parse(model.get_attribute('project_data', 'data') || '{}')
        payment_schedule = project_data['inputs']&.fetch('construction_payment_schedule', nil) ||
                           [0.1, 0, 0.2, 0, 0, 0, 0.2, 0, 0, 0, 0, 0, 0.1, 0, 0, 0, 0, 0, 0.1, 0, 0, 0, 0, 0, 0.1, 0, 0, 0, 0, 0, 0.1, 0, 0, 0, 0, 0, 0.1]
    
        payment_schedule.each_with_index do |percentage, month|
          payment_month = construction_init_time + month
          break if payment_month >= 72
          construction_payments[payment_month] += total_cost * percentage
        end
      end
    
      construction_payments
    end
    def self.calculate_sales_income(scene_switches = nil)
      model = Sketchup.active_model
      building_instances = TraversalUtils.traverse_building_instances(model)
      
      # Initialize tables
      stock_table = Hash.new { |h, k| h[k] = Array.new(72, 0) }
      income_table = Hash.new { |h, k| h[k] = Array.new(72, 0) }
      sales_table = Hash.new { |h, k| h[k] = Array.new(72, 0) }
      total_income = Array.new(72, 0)
      current_stock = Hash.new(0)
    
      # Get overlap matrix
      overlap_data = model.attribute_dictionaries['overlap_data']
      overlap_matrix = overlap_data ? JSON.parse(overlap_data['overlap_matrix'] || '{}') : {}
      
      # Debug for Month 12
      puts "\nOverlap Matrix:"
      puts JSON.pretty_generate(overlap_matrix)
    
      # First gather all stock additions
      building_instances.each do |instance, transformation|
        building_data = instance.definition.attribute_dictionary('building_data')
        dynamic_attrs = instance.attribute_dictionary('dynamic_attributes')
        next unless building_data && dynamic_attrs
    
        apartment_stocks = JSON.parse(building_data['apartment_stocks'])
        construction_init_time = dynamic_attrs['construction_init_time'].to_i
        sales_permit_time = dynamic_attrs['sales_permit_time'].to_i
        market_entry_month = construction_init_time + sales_permit_time
    
        next if market_entry_month >= 72
    
        # Add stock at market entry month
        apartment_stocks.each do |apt_type, count|
          stock_table[apt_type][market_entry_month] += count
        end
      end
    
      # Process each month
      (0...72).each do |month|
        # Update current stock with new supply
        stock_table.each do |apt_type, monthly_stocks|
          new_supply = monthly_stocks[month]
          current_stock[apt_type] += new_supply if new_supply > 0
        end
    
        next if current_stock.empty? || current_stock.values.all?(&:zero?)
    
        if month == 12
          puts "\nMonth 12 Debug Information:"
          puts "==================================="
          puts "Current stock levels:"
          current_stock.each do |type, amount|
            puts "#{type}: #{amount}"
          end
        end
    
        # Gather available types and their current scenes
        available_types = {}
        current_stock.each do |apt_type, stock|
          next if stock <= 0
    
          # Get apartment data and scenes
          apt_data = JSON.parse(model.get_attribute('apartment_type_data', apt_type) || '{}')
          sales_scenes = apt_data['sales_scenes'] || []
          next if sales_scenes.empty?
    
          # Determine which scene to use based on scene_switches parameter
          current_scene = if scene_switches&.dig(apt_type) && month >= scene_switches[apt_type] && sales_scenes.length > 1
            if month == 12
              puts "\nApartment Type: #{apt_type}"
              puts "Using Scene 2 (switched at month #{scene_switches[apt_type]})"
              puts "Scene Price: #{sales_scenes[1]['price']}"
              puts "Scene Volume: #{sales_scenes[1]['volumn']}"
            end
            sales_scenes[1]
          else
            if month == 12
              puts "\nApartment Type: #{apt_type}"
              puts "Using Scene 1"
              puts "Scene Price: #{sales_scenes[0]['price']}"
              puts "Scene Volume: #{sales_scenes[0]['volumn']}"
            end
            sales_scenes[0]
          end
    
          available_types[apt_type] = {
            stock: stock,
            volume: current_scene['volumn'].to_i,
            price: current_scene['price'].to_f,
            area: apt_data['area'].to_f
          }
        end
    
        if month == 12
          puts "\nAvailable Types for Overlap Calculation:"
          puts JSON.pretty_generate(available_types)
        end
    
        # Calculate adjusted volumes considering overlap
        adjusted_volumes = calculate_overlap_adjustments(available_types, overlap_matrix)
    
        if month == 12
          puts "\nAdjusted Volumes after Overlap:"
          puts JSON.pretty_generate(adjusted_volumes)
        end
    
        # Apply sales and update remaining stock
        available_types.each do |apt_type, type_data|
          max_volume = adjusted_volumes[apt_type]
          actual_sales = [max_volume, type_data[:stock]].min
          
          # Record sales and calculate income
          sales_table[apt_type][month] = actual_sales
          income_table[apt_type][month] = actual_sales * type_data[:price] * type_data[:area]
          total_income[month] += income_table[apt_type][month]
          
          # Update remaining stock
          current_stock[apt_type] -= actual_sales
    
          if month == 12
            puts "\nFinal Sales for #{apt_type}:"
            puts "Max Volume: #{max_volume}"
            puts "Actual Sales: #{actual_sales}"
            puts "Remaining Stock: #{current_stock[apt_type]}"
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
      
      # # puts "Starting calculation of cashflow"
      # # puts "Total building instances found: #{building_instances.length}"

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
      TraversalUtils.traverse_building_instances(model)
    end

    def self.associate_buildings_with_property_lines
      model = Sketchup.active_model
      property_lines = find_property_line_components(model)
      building_instances = find_building_instances(model)
    
      building_instances.each do |instance, world_transformation|
        position = world_transformation.origin
        associated_property_line = find_containing_property_line(position, property_lines)
        
        if associated_property_line
          keyword = associated_property_line.definition.get_attribute('dynamic_attributes', 'keyword')
          instance.set_attribute('dynamic_attributes', 'property_line_keyword', keyword)
        else
          instance.delete_attribute('dynamic_attributes', 'property_line_keyword')
          # # puts "Building '#{instance.definition.name}' (ID: #{instance.entityID}) is not within any property line"
        end
      end
    end

    
    def self.process_building(instance_data, cashflow)
      instance, transformation = instance_data if instance_data.is_a?(Array)
      
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
      
      # Return data with raw apartment_stocks (will be parsed later)
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
      
      # Parse the apartments data if it's a string
      apartments = building_data[:apartments]
      if apartments.is_a?(String)
        apartments = JSON.parse(apartments)
      end
      
      # Now process the parsed data
      apartments.each do |apt_type, count|
        cashflow[:apartment_stock][apt_type] ||= Array.new(72, 0)
        cashflow[:apartment_stock][apt_type][sales_permit_time] += count
      end
    end

    def self.calculate_sales_and_income(cashflow)
      model = Sketchup.active_model
      price_changes = {}
      
      # Get overlap matrix with debug logging
      overlap_data = model.attribute_dictionaries['overlap_data']
      overlap_matrix = overlap_data ? JSON.parse(overlap_data['overlap_matrix'] || '{}') : {}
      # puts "\n=== OVERLAP MATRIX ===\n#{JSON.pretty_generate(overlap_matrix)}"
      
      # Initialize arrays with logging
      cashflow[:apartment_stock].each do |apt_type, stocks|
        cashflow[:apartment_sales][apt_type] = Array.new(72, 0)
        price_changes[apt_type] = []
      end
      
      # puts "\n=== Processing Sales Month by Month ==="
      
      # Process month by month
      (0..71).each do |month|
        # puts "\nMonth #{month}:"
        
        # Step 1: Determine available types and their base volumes
        available_types = {}
        cashflow[:apartment_stock].each do |apt_type, stocks|
          current_stock = stocks[month].to_i
          next if current_stock <= 0

          apt_data = JSON.parse(model.get_attribute('apartment_type_data', apt_type) || '{}')
          sales_scenes = apt_data['sales_scenes'] || []
          next unless sales_scenes.any?

          scene_index = if sales_scenes.length > 1 && apt_data['scene_change_month'] && 
                        month >= apt_data['scene_change_month']
            1
          else
            0
          end
          
          scene = sales_scenes[scene_index]
          base_volume = scene['volumn'].to_i
          
          available_types[apt_type] = {
            stock: current_stock,
            base_volume: base_volume,
            scene: scene,
            area: apt_data['area'].to_f
          }
          # puts "  #{apt_type}: Stock=#{current_stock}, Base Volume=#{base_volume}"
        end

        # puts "  Available Types: #{available_types.keys.join(', ')}"

        # Step 2: Calculate adjusted volumes
        adjusted_volumes = calculate_adjusted_volumes(available_types, overlap_matrix)
        
        # puts "\n  === Adjusted Volumes ==="
        adjusted_volumes.each do |type, volume|
          # puts "  #{type}: #{volume} (Original: #{available_types[type][:base_volume]})"
        end

        # Step 3: Apply adjusted volumes
        available_types.each do |apt_type, type_data|
          max_volume = adjusted_volumes[apt_type]
          actual_sales = [max_volume, type_data[:stock]].min
          
          # puts "\n  #{apt_type} Sales Decision:"
          # puts "    Max Volume: #{max_volume}"
          # puts "    Available Stock: #{type_data[:stock]}"
          # puts "    Final Sales: #{actual_sales}"

          # Record sales and calculate income
          cashflow[:apartment_sales][apt_type][month] = actual_sales
          income = actual_sales * type_data[:scene]['price'].to_f * type_data[:area]
          cashflow[:income][month] += income
          
          # puts "    Recorded Sales: #{cashflow[:apartment_sales][apt_type][month]}"
          # puts "    Income: #{income}"
        end
      end

      cashflow[:price_changes] = price_changes
      # puts "\n=== Final Apartment Sales ==="
      cashflow[:apartment_sales].each do |apt_type, sales|
        # puts "#{apt_type}: #{sales.inspect}"
      end
      
      cashflow
    end

    def self.calculate_overlap_adjustments(available_types, overlap_matrix)
      return {} if available_types.empty?
    
      # Initialize volume dict with base volumes
      base_volumes = {}
      available_types.each do |type, data|
        base_volumes[type] = data[:volume] # Changed from base_volume to volume to match new structure
      end
      
      # Calculate adjustments
      final_volumes = {}
      available_types.each do |type, type_data|
        demand_i = type_data[:volume] # Changed from base_volume to volume
        adjustment = 0.0
    
        available_types.each do |other_type, other_data|
          next if type == other_type
          
          demand_j = other_data[:volume] # Changed from base_volume to volume
          next if demand_i + demand_j == 0
    
          p_ij = overlap_matrix.dig(type, other_type) || 0.0
          current_adjustment = (p_ij * (demand_j * demand_i)) / (demand_i + demand_j)
          adjustment += current_adjustment
        end
    
        final_volume = demand_i - adjustment
        final_volumes[type] = final_volume > 0 ? final_volume : 0
      end
    
      final_volumes
    end

    def self.calculate_adjusted_volumes(available_types, overlap_matrix)
      return {} if available_types.empty?

      # puts "\nCalculating Adjusted Volumes:"
      
      # Initialize volume dict with base volumes
      base_volumes = {}
      available_types.each do |type, data|
        base_volumes[type] = data[:base_volume]
      end
      # puts "Initial Base Volumes: #{base_volumes.inspect}"

      # Calculate adjustments
      final_volumes = {}
      available_types.each do |type, type_data|
        demand_i = type_data[:base_volume]
        adjustment = 0
        # puts "\nProcessing #{type} (Base Volume: #{demand_i})"

        available_types.each do |other_type, other_data|
          next if type == other_type
          
          demand_j = other_data[:base_volume]
          next if demand_i + demand_j == 0

          p_ij = overlap_matrix.dig(type, other_type) || 0
          current_adjustment = (p_ij * (demand_j * demand_i)) / (demand_i + demand_j)
          adjustment += current_adjustment
          
          # puts "  Overlap with #{other_type}:"
          # puts "    Demand_j: #{demand_j}"
          # puts "    p_ij: #{p_ij}"
          # puts "    Current Adjustment: #{current_adjustment}"
        end

        final_volume = demand_i - adjustment
        final_volumes[type] = final_volume > 0 ? final_volume : 0
        # puts "  Final Volume for #{type}: #{final_volumes[type]} (Total Adjustment: #{adjustment})"
      end

      # puts "\nFinal Adjusted Volumes: #{final_volumes.inspect}"
      final_volumes
    end

    def self.display_cashflow(cashflow)
      # # puts "Month | Expenses | Income | Net Cash Flow | Apartment Stock | Apartment Sales"
      (0...72).each do |month|
        net = cashflow[:income][month] - cashflow[:expenses][month]
        cashflow[:net_cashflow][month] = net
        stock_info = cashflow[:apartment_stock].map { |type, stocks| "#{type}: #{stocks[month]}" }.join(", ")
        sales_info = cashflow[:apartment_sales].map { |type, sales| "#{type}: #{sales[month]}" }.join(", ")
        # # puts "#{month} | #{cashflow[:expenses][month]} | #{cashflow[:income][month]} | #{net} | #{stock_info} | #{sales_info}"
      end
    end
    
    def self.get_apartment_data(apt_type)
      model = Sketchup.active_model
      JSON.parse(model.get_attribute('apartment_type_data', apt_type, '{}'))
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
      
      # # puts "Unsaleable Amenity Cost: #{unsaleable_amenity_cost}"
      # # puts "Payment Schedule: #{payment_schedule.inspect}"
      # # puts "Unsaleable Amenity Cost Payments: #{payments.inspect}"
      
      payments
    end
    
    def self.test_property_line_associations
      model = Sketchup.active_model
      
      # # puts "Testing property line associations..."
      associate_buildings_with_property_lines
      
      building_instances = find_building_instances(model)
      building_instances.each do |instance|
        keyword = instance.get_attribute('dynamic_attributes', 'property_line_keyword')
        # # puts "Building '#{instance.definition.name}' (ID: #{instance.entityID}) associated with property line '#{keyword || 'None'}'"
      end
    end

  end
end

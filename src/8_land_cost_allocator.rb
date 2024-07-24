module Real_Estate_Optimizer
  module LandCostAllocator
    CATEGORY_FACTORS = {
      '联排' => 0.6,
      '叠拼' => 0.8,
      '洋房' => 1.4,
      '小高层' => 2.0,
      '大高' => 3.0,
      '超高' => 6.0,
      '商铺' => 1.0,
      '办公' => 5.0,
      '公寓' => 4.0
    }

    def self.calculate_unit_land_costs
      model = Sketchup.active_model
      project_data = JSON.parse(model.get_attribute('project_data', 'data', '{}'))
      total_land_cost = project_data['inputs']['land_cost'].to_f * 10000  # Convert to yuan

      apartment_stocks = calculate_apartment_stocks(model)
      total_weight = calculate_total_weight(apartment_stocks)

      unit_land_costs = {}
      apartment_stocks.each do |apt_name, data|
        allocated_cost = (data[:weight] / total_weight) * total_land_cost
        unit_land_cost = allocated_cost / data[:count] / data[:area]
        unit_land_costs[apt_name] = unit_land_cost
      end

      update_apartment_types_with_unit_land_cost(model, unit_land_costs)
      unit_land_costs
    end

    def self.calculate_apartment_stocks(model)
      stocks = {}
      
      model.active_entities.grep(Sketchup::ComponentInstance).each do |instance|
        definition = instance.definition
        next unless definition.attribute_dictionaries && definition.attribute_dictionaries['building_data']
        
        apartment_stocks = JSON.parse(definition.get_attribute('building_data', 'apartment_stocks') || '{}')
        apartment_stocks.each do |apt_name, count|
          apt_data = get_apartment_data(apt_name)
          stocks[apt_name] ||= { count: 0, area: apt_data['area'].to_f, category: apt_data['apartment_category'], width: apt_data['width'].to_f }
          stocks[apt_name][:count] += count
        end
      end
    
      stocks.each do |apt_name, data|
        category_factor = CATEGORY_FACTORS[data[:category]] || 1.0
        data[:weight] = data[:width] / category_factor * data[:area] * data[:count]
      end
    
      stocks
    end

    def self.calculate_total_weight(apartment_stocks)
      apartment_stocks.values.inject(0) { |sum, data| sum + data[:weight] }
    end

    def self.update_apartment_types_with_unit_land_cost(model, unit_land_costs)
      model.start_operation('Update Apartment Unit Land Costs', true)
      
      unit_land_costs.each do |apt_name, unit_cost|
        apartment_data = JSON.parse(model.get_attribute('property_data', apt_name, '{}'))
        apartment_data['unit_land_cost'] = unit_cost
        model.set_attribute('property_data', apt_name, apartment_data.to_json)
      end

      model.commit_operation
    end

    def self.get_apartment_data(apt_name)
      model = Sketchup.active_model
      apartment_data = JSON.parse(model.get_attribute('property_data', apt_name, '{}'))
      unless apartment_data['width'] && apartment_data['apartment_category']
        puts "Warning: Apartment '#{apt_name}' is missing width or category data."
        apartment_data['width'] ||= 10.0  # Default width
        apartment_data['apartment_category'] ||= '小高层'  # Default category
      end
      apartment_data
    end

    def self.print_unit_land_costs
      model = Sketchup.active_model
      unit_land_costs = calculate_unit_land_costs
      
      puts "Calculated Unit Land Costs:"
      unit_land_costs.each do |apt_name, unit_cost|
        puts "  #{apt_name}: #{unit_cost.round(2)} yuan/sq.m"
      end
    end
  end
end
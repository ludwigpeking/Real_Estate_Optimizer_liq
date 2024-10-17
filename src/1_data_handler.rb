module Real_Estate_Optimizer
  module DataHandler
    def self.save_project_data(data_json)
      model = Sketchup.active_model
      data = JSON.parse(data_json)
      
      puts "Saving project data: #{data.inspect}"
      
      # Save main project data
      model.set_attribute('project_data', 'data', data_json)
      
      # Save property line data
      if data['propertyLines']
        data['propertyLines'].each do |pl|
          property_line = find_property_line_component(model, pl['name'])
          if property_line
            puts "Saving for property line #{pl['name']}: amenity_GFA_in_FAR = #{pl['amenity_GFA_in_FAR']}"
            property_line.definition.set_attribute('dynamic_attributes', 'amenity_GFA_in_FAR', pl['amenity_GFA_in_FAR'])
          else
            puts "Property line not found: #{pl['name']}"
          end
        end
      else
        puts "No propertyLines data to save"
      end
      puts "Project data saved successfully"
    end

    def self.load_project_data
      model = Sketchup.active_model
      data_json = model.get_attribute('project_data', 'data', nil)

      puts "Retrieved data_json: #{data_json.inspect}"

      if data_json.nil?
        data = DefaultValues::PROJECT_DEFAULTS
        puts "Using default project data"
      else
        stored_data = JSON.parse(data_json, symbolize_names: true)
        puts "Parsed stored_data: #{stored_data.inspect}"
        data = merge_with_defaults(stored_data, DefaultValues::PROJECT_DEFAULTS)
        puts "Merged data: #{data.inspect}"
      end

      # Get property line data from the model
      model_property_lines = get_property_line_data(model)

      # Merge stored property line data with model data if it exists
      if data[:propertyLines]
        merged_property_lines = merge_property_line_data(data[:propertyLines], model_property_lines)
      else
        merged_property_lines = model_property_lines
      end

      data[:propertyLines] = merged_property_lines

      puts "Final data to be returned:"
      puts data.inspect

      data
    end

    def self.get_property_line_data(model)
      property_lines = find_property_line_components(model)
      puts "Number of property lines found: #{property_lines.length}"
      
      unsorted_lines = property_lines.map do |pl|
        name = pl.definition.get_attribute('dynamic_attributes', 'keyword')
        area = pl.definition.get_attribute('dynamic_attributes', 'property_area').to_f
        amenity_GFA = pl.definition.get_attribute('dynamic_attributes', 'amenity_GFA_in_FAR').to_f
        
        puts "Property Line: #{name}"
        puts "  Area: #{area}"
        puts "  Amenity GFA in FAR: #{amenity_GFA}"
        puts "  All attributes: #{pl.definition.attribute_dictionary('dynamic_attributes')&.to_h}"
        
        {
          name: name,
          area: area,
          amenity_GFA_in_FAR: amenity_GFA
        }
      end

      sort_property_lines(unsorted_lines)
    end

    def self.sort_property_lines(property_lines)
      # Filter out entries that are not hashes or do not have a :name key
      filtered_property_lines = property_lines.select do |pl|
        pl.is_a?(Hash) && pl.key?(:name)
      end
    
      filtered_property_lines.sort_by do |pl|
        match = pl[:name].match(/(\d+)([A-Za-z]*)/)
        if match
          [match[1].to_i, match[2]]  # Sort by number first, then by letter
        else
          [Float::INFINITY, pl[:name]]  # Put non-matching names at the end
        end
      end
    end
    

    def self.merge_property_line_data(stored_lines, model_lines)
      merged_lines = model_lines.map do |model_line|
        stored_line = stored_lines.find { |sl| sl[:name] == model_line[:name] }
        if stored_line && stored_line[:amenity_GFA_in_FAR]
          model_line[:amenity_GFA_in_FAR] = stored_line[:amenity_GFA_in_FAR]
        end
        model_line
      end
      merged_lines
    end

    def self.merge_with_defaults(stored_data, default_data)
      merged_data = default_data.dup
      merged_data[:inputs] = default_data[:inputs].merge(stored_data[:inputs] || {})
      merged_data
    end

    def self.find_property_line_components(model)
      model.active_entities.grep(Sketchup::ComponentInstance).select do |instance|
        instance.definition.name.start_with?('property_line_')
      end
    end

    def self.find_property_line_component(model, name)
      model.active_entities.grep(Sketchup::ComponentInstance).find do |instance|
        instance.definition.name.start_with?('property_line_') && 
        instance.definition.get_attribute('dynamic_attributes', 'keyword') == name
      end
    end
  end
end
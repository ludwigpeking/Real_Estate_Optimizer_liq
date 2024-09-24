module Real_Estate_Optimizer
  module DataHandler
    def self.save_project_data(data_json)
      model = Sketchup.active_model
      model.set_attribute('project_data', 'data', data_json)
      
      # Save property line data
      data = JSON.parse(data_json)
      if data['propertyLines']
        data['propertyLines'].each do |pl|
          property_line = model.definitions[pl['name']]
          if property_line
            property_line.set_attribute('dynamic_attributes', 'amenity_GFA_in_FAR', pl['amenity_GFA_in_FAR'])
          end
        end
      end
    end

    def self.load_project_data
      model = Sketchup.active_model
      data_json = model.get_attribute('project_data', 'data', nil)

      if data_json.nil?
        data = DefaultValues::PROJECT_DEFAULTS
      else
        stored_data = JSON.parse(data_json, symbolize_names: true)
        data = merge_with_defaults(stored_data, DefaultValues::PROJECT_DEFAULTS)
      end

      # Load property line data
      data[:propertyLines] = CashFlowCalculator.get_property_line_data(model)

      data
    end

    def self.merge_with_defaults(stored_data, default_data)
      stored_data[:inputs] ||= {}
      default_data[:inputs].merge!(stored_data[:inputs])
      default_data
    end
  end
end

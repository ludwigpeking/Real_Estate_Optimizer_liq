module Real_Estate_Optimizer
  module DataHandler
    def self.save_project_data(data_json)
      model = Sketchup.active_model
      model.set_attribute('project_data', 'data', data_json)
    end

    def self.load_project_data
      model = Sketchup.active_model
      data_json = model.get_attribute('project_data', 'data', nil)

      if data_json.nil?
        DefaultValues::PROJECT_DEFAULTS
      else
        stored_data = JSON.parse(data_json, symbolize_names: true)
        merge_with_defaults(stored_data, DefaultValues::PROJECT_DEFAULTS)
      end
    end

    def self.merge_with_defaults(stored_data, default_data)
      stored_data[:inputs] ||= {}
      default_data[:inputs].merge!(stored_data[:inputs])
      default_data
    end
  end
end

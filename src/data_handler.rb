require 'json'
require 'sketchup'
require_relative 'default_values'

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
        JSON.parse(data_json, symbolize_names: true)
      end
    end
  end
end
require_relative 'apartment_generator'
require_relative 'building_generator'
require_relative 'apartment_manager'

module Urban_Banal
  module Real_Estate_Optimizer
    module Toolbar
        def self.create_toolbar
          toolbar = UI::Toolbar.new "YourPluginName"
  
          # Button for Apartment Type Management
          cmd_apartment_manager = UI::Command.new("Manage Apartment Types") {
            ApartmentManager.add_apartment_type  # Call the method from ApartmentManager module
          }
          cmd_apartment_manager.small_icon = "icons/apartment_icon.png"
          cmd_apartment_manager.large_icon = "icons/apartment_icon.png"
          cmd_apartment_manager.tooltip = "Manage Apartment Types"
          cmd_apartment_manager.status_bar_text = "Add or manage apartment types."
          toolbar.add_item(cmd_apartment_manager)
  
          # Example other buttons (assuming setup similar to previous examples)
          # You can replicate this setup for other functionalities
          cmd_generate_building = UI::Command.new("Generate Building") {
            BuildingGenerator.generate
          }
          cmd_generate_building.small_icon = "icons/building_icon.png"
          cmd_generate_building.large_icon = "icons/building_icon.png"
          cmd_generate_building.tooltip = "Generate Building"
          cmd_generate_building.status_bar_text = "Generates a new building."
          toolbar.add_item(cmd_generate_building)
  
          # Ensure the toolbar is visible
          toolbar.show if toolbar.get_last_state == TB_VISIBLE
        end
      end
    end
  end
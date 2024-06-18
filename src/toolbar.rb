require 'sketchup.rb'
require_relative 'apartment_manager'
require_relative 'building_generator'
require_relative 'input'
require_relative 'basement_pick'
require_relative 'propertyline_pick'
# require_relative 'insert_building'
# require_relative 'output'

module Urban_Banal
  module Real_Estate_Optimizer
    module Toolbar
      def self.create_toolbar
        toolbar = UI::Toolbar.new "Real_Estate_Optimizer"

        cmd_input = UI::Command.new("Input") {
          Input.input
        }
        cmd_input.small_icon = "../icons/input.png"
        cmd_input.large_icon = "../icons/input.png"
        cmd_input.tooltip = "Input"
        cmd_input.status_bar_text = "Input"
        toolbar.add_item(cmd_input)

        cmd_propertyline_pick = UI::Command.new("Propertyline Pick") {
          PropertylinePick.pick
        }
        cmd_propertyline_pick.small_icon = "../icons/propertyline_pick.png"
        cmd_propertyline_pick.large_icon = "../icons/propertyline_pick.png"
        cmd_propertyline_pick.tooltip = "Propertyline Pick"
        cmd_propertyline_pick.status_bar_text = "Propertyline Pick"
        toolbar.add_item(cmd_propertyline_pick)

        cmd_basement_pick = UI::Command.new("Basement Pick") {
          BasementPick.pick
        }
        cmd_basement_pick.small_icon = "../icons/basement_pick.png"
        cmd_basement_pick.large_icon = "../icons/basement_pick.png"
        cmd_basement_pick.tooltip = "Basement Pick"
        cmd_basement_pick.status_bar_text = "Basement Pick"
        toolbar.add_item(cmd_basement_pick)

        cmd_apartment_manager = UI::Command.new("Manage Apartment Types") {
          Urban_Banal::Real_Estate_Optimizer::ApartmentManager.show_dialog  # Ensure the correct namespace
        }
        cmd_apartment_manager.small_icon = "../icons/apartment.png"
        cmd_apartment_manager.large_icon = "../icons/apartment.png"
        cmd_apartment_manager.tooltip = "Manage Apartment Types"
        cmd_apartment_manager.status_bar_text = "Add or manage apartment types."
        toolbar.add_item(cmd_apartment_manager)

        cmd_building_type = UI::Command.new("Manage Building Types") {
          Urban_Banal::Real_Estate_Optimizer::BuildingGenerator.show_dialog  # Ensure the correct method call
        }
        cmd_building_type.small_icon = "../icons/building_type.png"
        cmd_building_type.large_icon = "../icons/building_type.png"
        cmd_building_type.tooltip = "Generate Building"
        cmd_building_type.status_bar_text = "Generates a new building."
        toolbar.add_item(cmd_building_type)

        # Ensure the toolbar is visible
        toolbar.show if toolbar.get_last_state == TB_VISIBLE
      end
    end
  end
end

Urban_Banal::Real_Estate_Optimizer::Toolbar.create_toolbar

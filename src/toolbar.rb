require_relative 'apartment_type'
require_relative 'apartment_manager'
require_relative 'building_generator'  # Add this line

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
          ApartmentManager.add_apartment_type  # Call the method from ApartmentManager module
        }
        cmd_apartment_manager.small_icon = "../icons/apartment.png"
        cmd_apartment_manager.large_icon = "../icons/apartment.png"
        cmd_apartment_manager.tooltip = "Manage Apartment Types"
        cmd_apartment_manager.status_bar_text = "Add or manage apartment types."
        toolbar.add_item(cmd_apartment_manager)

        cmd_building_type = UI::Command.new("Manage Building Types") {
          BuildingGenerator.generate
        }
        cmd_building_type.small_icon = "../icons/building_type.png"
        cmd_building_type.large_icon = "../icons/building_type.png"
        cmd_building_type.tooltip = "Generate Building"
        cmd_building_type.status_bar_text = "Generates a new building."
        toolbar.add_item(cmd_building_type)

        # cmd_insert_building = UI::Command.new("Insert Building") {
        #   InsertBuilding.insert
        # }
        # cmd_insert_building.small_icon = "../icons/insert_building.png"
        # cmd_insert_building.large_icon = "../icons/insert_building.png"
        # cmd_insert_building.tooltip = "Insert Building"
        # cmd_insert_building.status_bar_text = "Insert Building"
        # toolbar.add_item(cmd_insert_building)

        # cmd_output = UI::Command.new("Output") {
        #   Output.output
        # }
        # cmd_output.small_icon = "../icons/output.png"
        # cmd_output.large_icon = "../icons/output.png"
        # cmd_output.tooltip = "Output"
        # cmd_output.status_bar_text = "Output"
        # toolbar.add_item(cmd_output)

        # Ensure the toolbar is visible
        toolbar.show if toolbar.get_last_state == TB_VISIBLE
      end
    end
  end
end

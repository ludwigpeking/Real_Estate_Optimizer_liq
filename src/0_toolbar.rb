require_relative '1_input'
require_relative '2_propertyline_pick'
require_relative '3_basement_pick'
require_relative '4_apartment_manager'
require_relative '5_building_generator'
require_relative '6_insert_building'
require_relative '7_building_attribute_editor'
require_relative '8_output'



module Real_Estate_Optimizer
  module Toolbar
    @toolbar_created = false

    def self.create_toolbar
      return if @toolbar_created
      @toolbar_created = true

      # UI.messagebox("Creating Real_Estate_Optimizer Toolbar")

      toolbar = UI::Toolbar.new "Real_Estate_Optimizer"

      cmd_input = UI::Command.new("Input") {
        Input.show_dialog
      }
      cmd_input.small_icon = "../icons/input.png"
      cmd_input.large_icon = "../icons/input.png"
      cmd_input.tooltip = "项目基本信息输入"
      cmd_input.status_bar_text = "Project Inputs"
      toolbar.add_item(cmd_input)

      cmd_propertyline_pick = UI::Command.new("Propertyline Pick") {
        PropertylinePick.pick
      }
      cmd_propertyline_pick.small_icon = "../icons/propertyline_pick.png"
      cmd_propertyline_pick.large_icon = "../icons/propertyline_pick.png"
      cmd_propertyline_pick.tooltip = "拾取用地红线"
      cmd_propertyline_pick.status_bar_text = "Propertyline Pick"
      toolbar.add_item(cmd_propertyline_pick)

      cmd_basement_pick = UI::Command.new("Basement Pick") {
        BasementPick.pick
      }
      cmd_basement_pick.small_icon = "../icons/basement_pick.png"
      cmd_basement_pick.large_icon = "../icons/basement_pick.png"
      cmd_basement_pick.tooltip = "拾取地下轮廓线"
      cmd_basement_pick.status_bar_text = "Basement Pick"
      toolbar.add_item(cmd_basement_pick)

      cmd_apartment_manager = UI::Command.new("Manage Apartment Types") {
        ApartmentManager.show_dialog
      }
      cmd_apartment_manager.small_icon = "../icons/apartment.png"
      cmd_apartment_manager.large_icon = "../icons/apartment.png"
      cmd_apartment_manager.tooltip = "户型管理"
      cmd_apartment_manager.status_bar_text = "Add or manage apartment types."
      toolbar.add_item(cmd_apartment_manager)

      cmd_building_type = UI::Command.new("Manage Building Types") {
        BuildingGenerator.show_dialog
      }
      cmd_building_type.small_icon = "../icons/building_type.png"
      cmd_building_type.large_icon = "../icons/building_type.png"
      cmd_building_type.tooltip = "楼型管理"
      cmd_building_type.status_bar_text = "Generates a new building."
      toolbar.add_item(cmd_building_type)




      cmd_insert_building = UI::Command.new("Insert Building") {
        InsertBuilding.insert
      }
      cmd_insert_building.small_icon = "../icons/insert_building.png"
      cmd_insert_building.large_icon = "../icons/insert_building.png"
      cmd_insert_building.tooltip = "选择楼型插入模型"
      cmd_insert_building.status_bar_text = "Insert Building"
      toolbar.add_item(cmd_insert_building)

      cmd_edit_building_attributes = UI::Command.new("Edit Building Attributes") {
        BuildingAttributeEditor.show_dialog
      }
      cmd_edit_building_attributes.small_icon = "../icons/building_attribute_editor.png"
      cmd_edit_building_attributes.large_icon = "../icons/building_attribute_editor.png"
      cmd_edit_building_attributes.tooltip = "标段时间计划和属性"
      cmd_edit_building_attributes.status_bar_text = "Edit attributes of selected building components"
      toolbar.add_item(cmd_edit_building_attributes)

      cmd_output = UI::Command.new("Output") {
        Output.show_dialog
      }
      cmd_output.small_icon = "../icons/output.png"
      cmd_output.large_icon = "../icons/output.png"
      cmd_output.tooltip = "输出财务指标和信息"
      cmd_output.status_bar_text = "KPI/cashflow Output"
      toolbar.add_item(cmd_output)

      # Ensure the toolbar is visible
      toolbar.show if toolbar.get_last_state == TB_VISIBLE
    end
  end
end
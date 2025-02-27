require_relative '1_input'
require_relative '2_propertyline_pick'
require_relative '3_basement_pick'
require_relative '4_customer_overlap'
require_relative '5_building_generator'
require_relative '6_insert_building'
require_relative '7_building_attribute_editor'
require_relative '8_output'
require_relative '11_optimization_panel'



module Real_Estate_Optimizer
  module Toolbar
    @toolbar_created = false

    def self.create_toolbar
      return if @toolbar_created
      @toolbar_created = true

      # UI.messagebox("Creating Real_Estate_Optimizer Toolbar")

      toolbar = UI::Toolbar.new "庙算 Decisive - Realestate Optimizer"

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

      cmd_customer_overlap = UI::Command.new("Customer Overlap") {
        CustomerOverlap.show_dialog
      }
      cmd_customer_overlap.small_icon = "../icons/customer_overlap.png"
      cmd_customer_overlap.large_icon = "../icons/customer_overlap.png"
      cmd_customer_overlap.tooltip = "客户重叠计算"
      cmd_customer_overlap.status_bar_text = "Calculate customer overlap between apartment types"
      toolbar.add_item(cmd_customer_overlap)


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

      cmd_optimization = UI::Command.new("Optimization") {
        OptimizationPanel.show_dialog
      }
      cmd_optimization.small_icon = "../icons/optimization.png"
      cmd_optimization.large_icon = "../icons/optimization.png"
      cmd_optimization.tooltip = "优化分期"
      cmd_optimization.status_bar_text = "Optimization"
      toolbar.add_item(cmd_optimization)



      layers = ['liq_color_mass', 'liq_architecture', 'liq_sunlight', 'liq_phasing', 'liq_price']
      layer_names = ['面积色块 Color Mass', '外观设计 Architecture', '日照 Sunlight', '分期 Phasing', '价格系数 Price']

      layers.each_with_index do |layer, index|
        cmd_layer = UI::Command.new(" 切换到图层 Switch to #{layer_names[index]}") {
          ApartmentManager.switch_layer(layer)
        }
        cmd_layer.small_icon = "../icons/layer_#{layer}.png"
        cmd_layer.large_icon = "../icons/layer_#{layer}.png"
        cmd_layer.tooltip = "Switch to #{layer_names[index]} Layer"
        cmd_layer.status_bar_text = "Switch visibility to #{layer_names[index]} layer"
        toolbar.add_item(cmd_layer)

      end

      # cmd_reload = UI::Command.new("Reload Plugin") {
      #   Real_Estate_Optimizer.reload
      # }
      # cmd_reload.small_icon = "../icons/reload.png"
      # cmd_reload.large_icon = "../icons/reload.png"
      # cmd_reload.tooltip = "Reload Real Estate Optimizer Plugin"
      # cmd_reload.status_bar_text = "Reload the entire Real Estate Optimizer plugin"
      # toolbar.add_item(cmd_reload)

      # Ensure the toolbar is visible
      toolbar.show if toolbar.get_last_state == TB_VISIBLE
    end
  end
end

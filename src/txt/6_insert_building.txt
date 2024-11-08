require 'sketchup.rb'

module Real_Estate_Optimizer
  module InsertBuilding
    def self.insert
      model = Sketchup.active_model
      building_types = get_building_types(model)

      if building_types.empty?
        UI.messagebox("还没有创建过任何楼型， 请创建您的楼型。 No building types available. Please create a building type first.")
        return
      end

      # Use the same sorting logic as elsewhere in the codebase
      sorted_building_types = building_types.sort_by do |name|
        match = name.match(/(\d+)([A-Za-z]*)/)
        if match
          [match[1].to_i, match[2]]  # Sort by number first, then by letter
        else
          [Float::INFINITY, name]  # Put non-matching names at the end
        end
      end

      prompts = ["请选择一个要插入模型的楼型 Select Building Type"]
      defaults = [sorted_building_types.first]
      list = [sorted_building_types.join("|")]
      input = UI.inputbox(prompts, defaults, list, "请选择一个要插入模型的楼型 Select Building Type")

      return if input == false

      selected_building_type = input[0]
      model.select_tool(PlaceBuildingTool.new(selected_building_type))
    end

    def self.get_building_types(model)
      model.get_attribute('project_data', BuildingGenerator::BUILDING_TYPE_LIST_KEY, [])
    end

    class PlaceBuildingTool
      def initialize(building_type)
        @building_type = building_type
        @ip = Sketchup::InputPoint.new
      end

      def activate
        @mouse_ip = Sketchup::InputPoint.new
        Sketchup.active_model.active_view.invalidate
      end

      def deactivate(view)
        view.invalidate
      end

      def resume(view)
        view.invalidate
      end

      def onMouseMove(flags, x, y, view)
        @ip.pick(view, x, y)
        view.invalidate
      end

      def onLButtonDown(flags, x, y, view)
        model = view.model
        
        begin
          # Start an operation
          model.start_operation('Place Building', true)
      
          # Get the building definition
          building_def = model.definitions[@building_type]
      
          if building_def.nil?
            UI.messagebox("Building type '#{@building_type}' not found.")
            model.abort_operation
            return
          end
      
          # Create an instance of the building at the clicked point
          transformation = Geom::Transformation.new(@ip.position)
          instance = model.active_entities.add_instance(building_def, transformation)
      
          # Ensure the instance is on the 'liq_0' layer
          instance.layer = model.layers['liq_0'] || model.layers.add('liq_0')
      
          # Set default values for Construction Init Time and Sales Permit Time
          instance.set_attribute('dynamic_attributes', 'construction_init_time', 0)
          instance.set_attribute('dynamic_attributes', 'sales_permit_time', 2)
      
          # Update phasing color if the module is available
          if defined?(Real_Estate_Optimizer::PhasingColorUpdater)
            Real_Estate_Optimizer::PhasingColorUpdater.update_single_building(instance)
          end
      
          # Commit the operation
          model.commit_operation
      
          # Reset the tool
          Sketchup.active_model.select_tool(nil)
      
        rescue => e
          puts "Error placing building: #{e.message}"
          puts e.backtrace
          model.abort_operation
          UI.messagebox("Error placing building. Check Ruby Console for details.")
        end
      end

      def draw(view)
        @ip.draw(view) if @ip.valid?
      end
    end
  end
end
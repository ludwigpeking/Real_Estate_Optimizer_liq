require 'sketchup.rb'

module Real_Estate_Optimizer
  module InsertBuilding
    def self.insert
      model = Sketchup.active_model
      building_types = get_building_types(model)

      if building_types.empty?
        UI.messagebox("No building types available. Please create a building type first.")
        return
      end

      prompts = ["Select Building Type"]
      defaults = [building_types.first]
      list = [building_types.join("|")]
      input = UI.inputbox(prompts, defaults, list, "Select Building Type")

      return if input == false

      selected_building_type = input[0]
      
      # Start the tool to allow the user to click in the model space
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

        # Commit the operation
        model.commit_operation

        # Reset the tool
        Sketchup.active_model.select_tool(nil)
      end

      def draw(view)
        @ip.draw(view) if @ip.valid?
      end
    end
  end
end
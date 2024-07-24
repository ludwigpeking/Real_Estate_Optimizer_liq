module Real_Estate_Optimizer
  module BasementPick
    def self.pick
      model = Sketchup.active_model
      selection = model.selection

      # Prompt user to select a basement type
      choices = ["B1", "B2", "B3"]
      prompts = ["选择地库层编号 Choose Basement Type:"]
      defaults = [choices[0]]
      list = [choices.join("|")]
      input = UI.inputbox(prompts, defaults, list, "选择地库层编号 Select Basement Type")
      return unless input

      basement_type = input[0]

      if selection.empty?
        UI.messagebox("未选择闭合边界或组件 No selection. Please select some edges or a component.")
        return
      end

      model.start_operation('Create Basement', true)

      if selection.length == 1 && selection.first.is_a?(Sketchup::ComponentInstance)
        component = selection.first
        if component_contains_closed_loop?(component)
          area = calculate_component_area(component)
          handle_basement_component(component, area, basement_type)
          UI.messagebox("Area: #{convert_to_square_meters(area).round(2)} square meters")
        else
          UI.messagebox("所选不含闭合边界或组件 The selected component does not contain a valid closed loop of edges.")
        end
      else
        edges = selection.grep(Sketchup::Edge)
        if edges_form_closed_loop?(edges)
          area = calculate_area(edges)
          define_basement_component(edges, area, basement_type)
          UI.messagebox("Area: #{convert_to_square_meters(area).round(2)} square meters")
        else
          UI.messagebox("请选择一个闭合曲线")
        end
      end

      model.commit_operation
    end

    def self.handle_basement_component(component, area, basement_type)
      model = Sketchup.active_model
      definition_name = get_unique_basement_name(model, basement_type)
      existing_definition = model.definitions[definition_name]

      if existing_definition
        # Clear existing definition and redefine it with the new component's entities
        existing_definition.entities.clear!
        component.definition.entities.each do |entity|
          if entity.is_a?(Sketchup::Edge)
            existing_definition.entities.add_edges(entity.start.position, entity.end.position)
          end
        end
      else
        # Rename component definition to the unique basement name
        component.definition.name = definition_name
      end

      set_basement_attributes(component.definition, basement_type, area)
    end

    def self.define_basement_component(edges, area, basement_type)
      model = Sketchup.active_model
      definition_name = get_unique_basement_name(model, basement_type)
      definition = model.definitions[definition_name] || model.definitions.add(definition_name)

      # Clear any existing entities in the definition
      definition.entities.clear!

      # Sort edges to form a closed loop
      sorted_edges = sort_edges_into_loop(edges)

      # Add edges to the definition to ensure a closed loop
      sorted_edges.each do |edge|
        definition.entities.add_edges(edge.start.position, edge.end.position)
      end

      # Add the new instance to the model
      instance = model.active_entities.add_instance(definition, Geom::Transformation.new)
      instance.name = definition_name

      set_basement_attributes(definition, basement_type, area)

      puts "Instance '#{instance.name}' has been created with area: #{convert_to_square_meters(area)}"
    end

    def self.get_unique_basement_name(model, basement_type)
      count = 1
      loop do
        name = "#{basement_type}_#{count}"
        return name unless model.definitions[name]
        count += 1
      end
    end

    def self.set_basement_attributes(definition, basement_type, area)
      definition.set_attribute('dynamic_attributes', '_area_label', 'Basement Area')
      definition.set_attribute('dynamic_attributes', '_area_units', 'square meters')
      definition.set_attribute('dynamic_attributes', 'basement_area', convert_to_square_meters(area))
      definition.set_attribute('dynamic_attributes', 'basement_type', basement_type)
      definition.set_attribute('dynamic_attributes', 'construction_init_time', 0)
      definition.set_attribute('dynamic_attributes', 'sales_permit_time', 2)
      
      # Calculate and set the default parking lot number
      default_parking_lots = (convert_to_square_meters(area) / 34).floor
      definition.set_attribute('dynamic_attributes', 'parking_lot_number', default_parking_lots)
      definition.set_attribute('dynamic_attributes', 'parking_lot_stock', default_parking_lots)
      definition.set_attribute('dynamic_attributes', 'construction_cost', convert_to_square_meters(area) * Sketchup.active_model.get_attribute('project_data', 'basement_unit_cost_before_allocation', 3400))
    end

    def self.edges_form_closed_loop?(edges)
      return false if edges.empty?
      first_vertex = edges.first.start
      connected = edges.first
      visited = [connected]
      loop_count = 1

      begin
        next_edge = edges.find { |e| !visited.include?(e) && (e.start == connected.end || e.end == connected.end) }
        return false unless next_edge
        visited << next_edge
        connected = next_edge
        loop_count += 1
      end until connected.end == first_vertex

      loop_count == edges.size
    end

    def self.sort_edges_into_loop(edges)
      sorted_edges = [edges.shift]
      until edges.empty?
        last_edge = sorted_edges.last
        next_edge = edges.find { |e| e.start == last_edge.end || e.end == last_edge.end }
        if next_edge
          edges.delete(next_edge)
          sorted_edges << next_edge
        else
          break
        end
      end

      # Ensure the loop is closed by checking if the last edge connects back to the first
      if sorted_edges.first.start == sorted_edges.last.end || sorted_edges.first.end == sorted_edges.last.end
        sorted_edges
      else
        []
      end
    end

    def self.calculate_area(edges)
      vertices = edges.map { |e| [e.start.position, e.end.position] }.flatten.uniq

      n = vertices.length
      area = 0.0
      (0...n).each do |i|
        j = (i + 1) % n
        xi, yi = vertices[i].x, vertices[i].y
        xj, yj = vertices[j].x, vertices[j].y
        area += xi * yj - xj * yi
      end
      area = (area.abs / 2.0)

      area
    end

    def self.convert_to_square_meters(area)
      conversion_factor = 0.0254 ** 2
      area * conversion_factor
    end
  end
end

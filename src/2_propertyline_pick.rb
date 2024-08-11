
module Real_Estate_Optimizer
  module PropertylinePick
    def self.pick
      model = Sketchup.active_model
      selection = model.selection

      # Prompt user for keyword
      keyword = UI.inputbox(["请键入该用地边界线的名称 Enter a keyword for this property line:"], [""], "Property Line Keyword")[0]
      return if keyword.nil? || keyword.empty?

      if selection.empty?
        UI.messagebox("未选择任何图元。 No selection. Please select some edges or a component.")
        return
      end

      if selection.length == 1 && selection.first.is_a?(Sketchup::ComponentInstance)
        component = selection.first
        if component_contains_closed_loop?(component)
          area = calculate_component_area(component)
          handle_property_line_component(component, area, keyword)
          UI.messagebox("Area: #{convert_to_square_meters(area).round(2)} square meters")
        else
          UI.messagebox("The selected component does not contain a valid closed loop of edges.")
        end
      else
        edges = selection.grep(Sketchup::Edge)
        if edges_form_closed_loop?(edges)
          area = calculate_area(edges)
          define_property_line_component(edges, area, keyword)
          UI.messagebox("Area: #{convert_to_square_meters(area).round(2)} square meters")
        else
          UI.messagebox("请选择一个闭合曲线")
        end
      end
    end

    def self.component_contains_closed_loop?(component)
      edges = component.definition.entities.grep(Sketchup::Edge)
      edges_form_closed_loop?(edges)
    end

    def self.calculate_component_area(component)
      edges = component.definition.entities.grep(Sketchup::Edge)
      calculate_area(edges)
    end

    def self.handle_property_line_component(component, area, keyword)
      model = Sketchup.active_model
      definition_name = "property_line_#{keyword}"
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
        # Rename component definition
        component.definition.name = definition_name
      end

      # Set the dynamic attributes
      component.definition.set_attribute('dynamic_attributes', '_area_label', 'Property Area')
      component.definition.set_attribute('dynamic_attributes', '_area_units', 'square meters')
      component.definition.set_attribute('dynamic_attributes', 'property_area', convert_to_square_meters(area))
      component.definition.set_attribute('dynamic_attributes', 'keyword', keyword)
      # Force the dynamic attributes to refresh
      component.definition.set_attribute('dynamic_attributes', '_hasdc', 'true')
      $dc_observers.get_latest_class.redraw_with_undo(component)

      puts "Component '#{component.definition.name}' has been updated with area: #{convert_to_square_meters(area)} and keyword: #{keyword}"
    end

    def self.define_property_line_component(edges, area, keyword)
      model = Sketchup.active_model
      definition_name = "property_line_#{keyword}"
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

      # Set the dynamic attributes
      instance.definition.set_attribute('dynamic_attributes', '_area_label', 'Property Area')
      instance.definition.set_attribute('dynamic_attributes', '_area_units', 'square meters')
      instance.definition.set_attribute('dynamic_attributes', 'property_area', convert_to_square_meters(area))
      instance.definition.set_attribute('dynamic_attributes', 'keyword', keyword)
      # Force the dynamic attributes to refresh
      instance.definition.set_attribute('dynamic_attributes', '_hasdc', 'true')
      $dc_observers.get_latest_class.redraw_with_undo(instance)

      puts "Instance '#{instance.name}' has been created with area: #{convert_to_square_meters(area)} and keyword: #{keyword}"
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


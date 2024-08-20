module Real_Estate_Optimizer
  module PropertylinePick
    TOLERANCE = 1.0e-4

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
        puts "Number of edges selected: #{edges.size}"
        puts "Edges: #{edges.map { |e| [e.start.position.to_a, e.end.position.to_a] }}"
        is_closed = edges_form_closed_loop?(edges)
        puts "Is closed loop: #{is_closed}"
        if is_closed
          area = calculate_area(edges)
          define_property_line_component(edges, area, keyword)
          UI.messagebox("Area: #{convert_to_square_meters(area).round(2)} square meters")
        else
          UI.messagebox("请选择一个闭合曲线 Please select a closed loop")
        end
      end
    end

    def self.component_contains_closed_loop?(component)
      edges = component.definition.entities.grep(Sketchup::Edge)
      edges_form_closed_loop?(edges)
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
    
      # Define a precision for rounding the coordinates
      precision = 0.001
    
      # Create a hash to store connected edges for each vertex
      connections = Hash.new { |h, k| h[k] = [] }
    
      edges.each do |edge|
        start_point = [edge.start.position.x.round(precision), edge.start.position.y.round(precision), edge.start.position.z.round(precision)]
        end_point = [edge.end.position.x.round(precision), edge.end.position.y.round(precision), edge.end.position.z.round(precision)]
        connections[start_point] << edge
        connections[end_point] << edge
      end
    
      # Check if each vertex is connected to exactly two edges
      return false unless connections.all? { |_, connected_edges| connected_edges.size == 2 }
    
      # Start from any edge and try to make a full loop
      current_edge = edges.first
      visited_edges = Set.new
      start_point = [current_edge.start.position.x.round(precision), current_edge.start.position.y.round(precision), current_edge.start.position.z.round(precision)]
    
      edges.size.times do
        visited_edges.add(current_edge)
        current_position = [current_edge.end.position.x.round(precision), current_edge.end.position.y.round(precision), current_edge.end.position.z.round(precision)]
        next_edge = (connections[current_position] - [current_edge]).first
    
        return false if next_edge.nil?
    
        current_edge = next_edge
        start_point = current_position
      end
    
      # Check if we've visited all edges and returned to the starting point
      visited_edges.size == edges.size && start_point == [edges.first.start.position.x.round(precision), edges.first.start.position.y.round(precision), edges.first.start.position.z.round(precision)]
    end
    

    def self.point_to_key(point)
      [point.x.round(3), point.y.round(3), point.z.round(3)]
    end

    def self.sort_edges_into_loop(edges)
      return [] if edges.empty?
    
      sorted_edges = [edges.first]
      current_edge = edges.first
    
      while sorted_edges.size < edges.size
        next_edge = edges.find do |e|
          e != current_edge && (e.start.position == current_edge.end.position || e.end.position == current_edge.end.position)
        end
    
        break unless next_edge  # Exit if no next edge is found, which indicates a broken loop
    
        sorted_edges << next_edge
        current_edge = next_edge
      end
    
      sorted_edges
    end
    

    def self.calculate_area(edges)
      sorted_edges = sort_edges_into_loop(edges)
      return 0 if sorted_edges.empty?
    
      # Get the start position of each edge as a Point3d object
      vertices = sorted_edges.map { |e| e.start.position }
    
      area = 0.0
      vertices.each_with_index do |v, i|
        next_v = vertices[(i + 1) % vertices.size]
        area += v.x * next_v.y - next_v.x * v.y
      end
    
      area.abs / 2.0
    end
    

    def self.calculate_component_area(component)
      edges = component.definition.entities.grep(Sketchup::Edge)
      calculate_area(edges)
    end

    def self.convert_to_square_meters(area)
      conversion_factor = 0.0254 ** 2
      area * conversion_factor
    end
  end
end
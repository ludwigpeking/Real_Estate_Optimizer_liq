module Urban_Banal
    module Real_Estate_Optimizer
      module PropertylinePick
        def self.pick
          model = Sketchup.active_model
          selection = model.selection
          
          unless selection.empty?
            edges = selection.grep(Sketchup::Edge)
            # Check if all selected items are edges and form a closed loop
            if edges_form_closed_loop?(edges)
              area = calculate_area(edges)
              model.set_attribute('Dynamics', 'property_area', area)
              UI.messagebox("Area: #{area.round(2)} square meters")
            else
              UI.messagebox("请选择一个闭合曲线")
            end
          else
            UI.messagebox("No selection. Please select some edges.")
          end
        end
  
        def self.edges_form_closed_loop?(edges)
          return false if edges.empty?
          first_vertex = edges.first.start
          connected = edges.first
          loop_count = 1
  
          begin
            next_edge = edges.find { |e| e != connected && (e.start == connected.end || e.end == connected.end) }
            return false unless next_edge
            connected = next_edge
            loop_count += 1
          end until connected.end == first_vertex
  
          loop_count == edges.size
        end
  
        def self.calculate_area(edges)
            # Extract vertices from edges and ensure they are unique and in order
            vertices = edges.map { |e| [e.start.position, e.end.position] }.flatten.uniq
          
            # Calculate the area using the Shoelace formula
            n = vertices.length
            area = 0.0
            (0...n).each do |i|
              j = (i + 1) % n
              xi, yi = vertices[i].x, vertices[i].y
              xj, yj = vertices[j].x, vertices[j].y
              area += xi * yj - xj * yi
            end
            area = (area.abs / 2.0)
          
            area  # Return the computed area
          end
          
      end
    end
  end
  
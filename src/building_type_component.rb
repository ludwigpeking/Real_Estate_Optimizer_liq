# building_type_component.rb

module Real_Estate_Optimizer
    module BuildingTypeComponent
      def self.create_or_update_component(building_type)
        model = Sketchup.active_model
        definitions = model.definitions
        
        # Start the SketchUp operation
        model.start_operation('Create/Update Building Type Component', true)
  
        component_name = building_type['name']
        
        # Check if a component definition already exists
        building_def = definitions[component_name]
        if building_def
          # Clear existing geometry if component exists
          building_def.entities.clear!
        else
          # Create new component definition if it doesn't exist
          building_def = definitions.add(component_name)
        end
  
        # Create the geometry for the building type
        create_building_geometry(building_def, building_type)
  
        # Add dynamic component attributes
        add_dynamic_attributes(building_def, building_type)
  
        # Place the component in the model for inspection
        place_component_in_model(building_def)
  
        model.commit_operation
  
        building_def
      end
  
      def self.create_building_geometry(building_def, building_type)
        z_offset = 0
      
        building_type['floorTypes'].each do |floor_type|
          floor_height = floor_type['levelHeight'].to_f
          num_floors = floor_type['number'].to_i
      
          num_floors.times do
            floor_type['apartmentTypes'].each do |apartment|
              add_apartment(building_def, apartment['x'].to_f, apartment['y'].to_f, z_offset, apartment['name'], floor_height)
            end
            z_offset += floor_height
          end
        end
      end
      
      def self.add_apartment(building_def, x_offset, y_offset, z_offset, apartment_name, floor_height)
        model = Sketchup.active_model
        apartment_def = model.definitions[apartment_name]
        
        unless apartment_def
          UI.messagebox("Apartment type '#{apartment_name}' not found. Please create it first.")
          return
        end
      
        # Create a new instance of the apartment and add it to the building
        transform = Geom::Transformation.new([x_offset.m, y_offset.m, z_offset.m])
        building_def.entities.add_instance(apartment_def, transform)
      end
  
      def self.create_apartment_material(name, area)
        material = Sketchup.active_model.materials.add(name)
        hue = (area - 50) * 2 % 360
        material.color = Sketchup::Color.new(*hsl_to_rgb(hue, 100, 50))
        material
      end
  
      def self.add_dynamic_attributes(building_def, building_type)
        # Use the 'set_attribute' method instead of 'add_attribute'
        building_def.set_attribute('dynamic_attributes', 'x_coordinate', 0.0)
        building_def.set_attribute('dynamic_attributes', 'y_coordinate', 0.0)
        building_def.set_attribute('dynamic_attributes', 'z_coordinate', 0.0)
        building_def.set_attribute('dynamic_attributes', 'construction_init_time', 0)
        building_def.set_attribute('dynamic_attributes', 'sales_permit_time', building_type['standardConstructionTime']['monthsFromConstructionInitToSale'])
      end
  
      def self.place_component_in_model(building_def)
        model = Sketchup.active_model
        entities = model.active_entities
        
        # Find a clear space to place the component
        bbox = building_def.bounds
        max_dimension = [bbox.width, bbox.height, bbox.depth].max
        placement_point = Geom::Point3d.new(max_dimension, max_dimension, 0)
        
        # Add the component to the model
        instance = entities.add_instance(building_def, placement_point)
        
        # Zoom to the newly placed component
        model.active_view.zoom(instance)
      end
  
      def self.hsl_to_rgb(h, s, l)
        h /= 360.0
        s /= 100.0
        l /= 100.0
        
        c = (1 - (2 * l - 1).abs) * s
        x = c * (1 - ((h * 6) % 2 - 1).abs)
        m = l - c / 2
  
        r, g, b = case (h * 6).to_i
                  when 0 then [c, x, 0]
                  when 1 then [x, c, 0]
                  when 2 then [0, c, x]
                  when 3 then [0, x, c]
                  when 4 then [x, 0, c]
                  else [c, 0, x]
                  end
  
        [(r + m) * 255, (g + m) * 255, (b + m) * 255].map(&:round)
      end
    end
  end
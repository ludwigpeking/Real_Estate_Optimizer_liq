require 'sketchup.rb'
# building_type_component.rb

module Real_Estate_Optimizer
    module BuildingTypeComponent
      APARTMENT_TYPE_LIST_KEY = 'apartment_type_names'

      def self.print_all_apartment_types
        model = Sketchup.active_model
        apartment_type_names = model.get_attribute('aparment_type_data', APARTMENT_TYPE_LIST_KEY, [])
        
        puts "All Apartment Types in the Project:"
        if apartment_type_names.empty?
          puts "  No apartment types found."
        else
          apartment_type_names.each_with_index do |name, index|
            puts "  #{index + 1}. #{name}"
            
            # Retrieve and print detailed data for each apartment type
            apartment_data = JSON.parse(model.get_attribute('aparment_type_data', name, '{}'))
            puts "     Area: #{apartment_data['area']} sq.m"
            puts "     Category: #{apartment_data['apartment_category']}"
            puts "     Baseline Cost: #{apartment_data['product_baseline_unit_cost_before_allocation']} per sq.m"
            
            # Print sales scenes if available
            if apartment_data['sales_scenes'] && !apartment_data['sales_scenes'].empty?
              puts "     Sales Scenes:"
              apartment_data['sales_scenes'].each_with_index do |scene, scene_index|
                puts "       Scene #{scene_index + 1}: Price: #{scene['price']}, Volume: #{scene['volumn']}"
              end
            end
            
            puts "" # Empty line for readability
          end
        end
      end

      def self.create_or_update_component(building_type)
        model = Sketchup.active_model
        definitions = model.definitions
        
        model.start_operation('Create/Update Building Type Component', true)
      
        begin
          component_name = building_type['name']
          
          # Check if a component definition already exists
          building_def = definitions[component_name]
          if building_def
            # Clear existing geometry if the component exists
            building_def.entities.clear!
          else
            # Create a new component definition if it doesn't exist
            building_def = definitions.add(component_name)
          end
      
          # Ensure 'liq_0' layer exists and is visible
          liq_0_layer = model.layers['liq_0'] || model.layers.add('liq_0')
          liq_0_layer.visible = true
      
          # Store current active layer
          original_active_layer = model.active_layer
      
          # Set 'liq_0' as the active layer
          model.active_layer = liq_0_layer
      
          # Create the geometry for the building type
          create_building_geometry(building_def, building_type)
      
          # Pre-calculate apartment stocks, total cost, total area, and footprint area
          apartment_stocks = {}
          total_cost = 0
          total_area = 0
          footprint_area = 0
      
          building_type['floorTypes'].each_with_index do |floor_type, floor_index|
            num_floors = floor_type['number'].to_i
            
            floor_type['apartmentTypes'].each do |apartment|
              apt_name = apartment['name']
              
              # Fetch apartment type data
              apt_data = get_apartment_type_data(model, apt_name)
              
              apartment_stocks[apt_name] ||= 0
              apartment_stocks[apt_name] += num_floors  # Each apartment type appears once per floor
              
              apt_area = apt_data['area'].to_f
              apt_cost = apt_data['product_baseline_unit_cost_before_allocation'].to_f
              
              # Calculate cost and area for this apartment type
              apt_total_cost = num_floors * apt_area * apt_cost
              apt_total_area = num_floors * apt_area
              
              total_cost += apt_total_cost
              total_area += apt_total_area
      
              # Calculate footprint area (only for the first floor type)
              footprint_area += apt_area if floor_index == 0
            end
          end
      
          # Save data to the component definition
          apartment_stocks_json = apartment_stocks.to_json
          building_def.set_attribute('building_data', 'apartment_stocks', apartment_stocks_json)
          building_def.set_attribute('building_data', 'total_cost', total_cost)
          building_def.set_attribute('building_data', 'total_area', total_area)
          building_def.set_attribute('building_data', 'footprint_area', footprint_area)
          building_def.set_attribute('building_data', 'supervisionFundPercentage', building_type['standardConstructionTime']['supervisionFundPercentage'].to_f)
          building_def.set_attribute('building_data', 'supervisionFundReleaseSchedule', building_type['supervisionFundReleaseSchedule'])
      
          # Log the calculated values for inspection
          puts "Building Type: #{component_name}"
          puts "Apartment Stocks: #{apartment_stocks}"
          puts "Total Cost: #{total_cost}"
          puts "Total Area: #{total_area}"
          puts "Footprint Area: #{footprint_area}"
      
          # Place the component in the model for inspection
          instance = place_component_in_model(building_def)
      
          # Add dynamic component attributes
          add_dynamic_attributes(instance, building_type)
      
          # Restore original active layer
          model.active_layer = original_active_layer
      
          model.commit_operation
        rescue => e
          model.abort_operation
          puts "Error in create_or_update_component: #{e.message}"
          puts e.backtrace.join("\n")
        end
      
        building_def
      end
  
      def self.create_building_geometry(building_def, building_type)
        model = Sketchup.active_model
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
        instance = building_def.entities.add_instance(apartment_def, transform)
    
        # Ensure the instance is on the 'liq_0' layer
        instance.layer = model.layers['liq_0']
      end

      def self.get_apartment_type_data(model, apt_name)
        apartment_data = JSON.parse(model.get_attribute('aparment_type_data', apt_name) || '{}')
        
        if apartment_data.empty?
          puts "Warning: No data found for apartment type '#{apt_name}'"
          return {}
        end
      
        {
          'area' => apartment_data['area'],
          'category' => apartment_data['apartment_category'],
          'product_baseline_unit_cost_before_allocation' => apartment_data['product_baseline_unit_cost_before_allocation']
        }
      end
  
      def self.create_apartment_material(name, area)
        material = Sketchup.active_model.materials.add(name)
        hue = (area - 50) * 2 % 360
        material.color = Sketchup::Color.new(*hsl_to_rgb(hue, 100, 50))
        material
      end
  
      def self.add_dynamic_attributes(instance, building_type)
        # Set dynamic attributes on the component instance
        instance.set_attribute('dynamic_attributes', 'construction_init_time', 0)
        sales_permit_time = building_type['standardConstructionTime']['monthsFromConstructionInitToSale'].to_i
        instance.set_attribute('dynamic_attributes', 'sales_permit_time', sales_permit_time)
        
        # Add these lines
        instance.set_attribute('dynamic_attributes', 'supervisionFundPercentage', building_type['standardConstructionTime']['supervisionFundPercentage'].to_f)
        instance.set_attribute('dynamic_attributes', 'supervisionFundReleaseSchedule', building_type['supervisionFundReleaseSchedule'])
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
        instance # Return the instance for further manipulation
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
module Real_Estate_Optimizer
  module PhasingColorUpdater
    def self.update_phasing_colors
      model = Sketchup.active_model
      model.start_operation('Update Phasing Colors', true)

      # Find all building instances and get the max init time
      building_instances = find_building_instances(model)
      max_time = find_max_init_time(building_instances)

      building_instances.each do |instance|
        init_time = instance.get_attribute('dynamic_attributes', 'construction_init_time', 0).to_i
        color = calculate_color(init_time, max_time)
        apply_phasing_color(instance, color)
      end

      model.commit_operation
    end

    def self.find_building_instances(model)
      model.active_entities.grep(Sketchup::ComponentInstance).select do |instance|
        instance.definition.attribute_dictionaries && 
        instance.definition.attribute_dictionaries['building_data']
      end
    end

    def self.find_max_init_time(instances)
      max_time = instances.map { |instance| 
        instance.get_attribute('dynamic_attributes', 'construction_init_time', 0).to_i 
      }.max
      max_time.zero? ? 72 : max_time  # Default to 72 if no init times set
    end


    def self.apply_phasing_color(instance, color)
      # Create or update the material in the model
      model = Sketchup.active_model
      material_name = "phasing_color_#{instance.entityID}"
      material = model.materials[material_name] || model.materials.add(material_name)
      material.color = color

      # Apply the material to the instance
      instance.material = material
    end

    def self.update_single_building(instance)
      return unless instance.is_a?(Sketchup::ComponentInstance)
      
      model = Sketchup.active_model
      model.start_operation('Update Single Building Phasing', true)

      begin
        # Get construction init time
        init_time = instance.get_attribute('dynamic_attributes', 'construction_init_time', 0).to_i
        puts "PhasingColorUpdater: Updating building with init_time: #{init_time}" # Debug log

        # Calculate color (using fixed max_time of 72 for consistency)
        color = calculate_color(init_time, 72)  # Use fixed max time
        puts "PhasingColorUpdater: Calculated color: #{color.inspect}" # Debug log

        # Create or update material
        material_name = "phasing_#{instance.entityID}"
        material = model.materials[material_name] || model.materials.add(material_name)
        material.color = color
        puts "PhasingColorUpdater: Created/updated material: #{material_name}" # Debug log

        # Apply material to instance
        instance.material = material
        puts "PhasingColorUpdater: Applied material to instance" # Debug log

        model.commit_operation
      rescue => e
        puts "PhasingColorUpdater Error: #{e.message}"
        puts e.backtrace
        model.abort_operation
      end
    end

    def self.calculate_color(init_time, max_time)
      ratio = 1.0 - (init_time.to_f / max_time)
      blue = (255 * ratio).to_i
      Sketchup::Color.new(255, 255-blue, 255-blue)
    end
  end
end
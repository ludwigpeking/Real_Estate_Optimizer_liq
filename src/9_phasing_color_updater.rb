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

    def self.calculate_color(init_time, max_time)
      ratio = 1 - (init_time.to_f / max_time)
      blue = (255 * ratio).to_i
      Sketchup::Color.new(0, 0, blue)
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

      # Find max init time considering all buildings
      all_instances = find_building_instances(model)
      max_time = find_max_init_time(all_instances)

      # Calculate and apply color for this instance
      init_time = instance.get_attribute('dynamic_attributes', 'construction_init_time', 0).to_i
      color = calculate_color(init_time, max_time)
      apply_phasing_color(instance, color)

      model.commit_operation
    end
  end
end
module Real_Estate_Optimizer
  module PhasingColorUpdater
    def self.calculate_color(init_time, max_time = 72)
      ratio = 1 - (init_time.to_f / max_time)
      blue = (255 * ratio).to_i
      [0, 0, blue]
    end

    def self.create_phasing_geometry(apartment, color)
      # Create a new group for the phasing geometry
      phasing_group = apartment.definition.entities.add_group
      phasing_group.layer = apartment.model.layers["liq_phasing"]

      # Get the bounding box of the apartment
      bounds = apartment.definition.bounds
      
      # Create a simple box representing the apartment
      points = [
        bounds.corner(0), bounds.corner(1), bounds.corner(3), bounds.corner(2),
        bounds.corner(4), bounds.corner(5), bounds.corner(7), bounds.corner(6)
      ]
      
      face = phasing_group.entities.add_face(points[0], points[1], points[2], points[3])
      face.pushpull(bounds.depth)
      
      # Apply the color to all faces of the new geometry
      phasing_group.entities.grep(Sketchup::Face).each do |face|
        face.material = color
        face.back_material = color
      end

      # Add an attribute to identify this as a phasing geometry
      phasing_group.set_attribute('PhasingColorUpdater', 'is_phasing_geometry', true)
    end

    def self.update_phasing_colors
      model = Sketchup.active_model
      
      model.start_operation('Update Phasing Colors', true)

      # Clear existing phasing geometry
      clear_phasing_geometry(model)

      building_instances = model.active_entities.grep(Sketchup::ComponentInstance).select do |instance|
        instance.definition.attribute_dictionaries && instance.definition.attribute_dictionaries['building_data']
      end

      building_instances.each do |building|
        construction_init_time = building.get_attribute('dynamic_attributes', 'construction_init_time', 0)
        color = Sketchup::Color.new(*calculate_color(construction_init_time))

        building.definition.entities.grep(Sketchup::ComponentInstance).each do |apartment|
          create_phasing_geometry(apartment, color)
        end
      end

      model.commit_operation
    end

    def self.clear_phasing_geometry(model)
      phasing_layer = model.layers["liq_phasing"]
      return unless phasing_layer

      model.active_entities.grep(Sketchup::Group).each do |group|
        if group.layer == phasing_layer && group.get_attribute('PhasingColorUpdater', 'is_phasing_geometry')
          group.erase!
        end
      end

      model.definitions.each do |definition|
        definition.entities.grep(Sketchup::Group).each do |group|
          if group.layer == phasing_layer && group.get_attribute('PhasingColorUpdater', 'is_phasing_geometry')
            group.erase!
          end
        end
      end
    end
  end
end
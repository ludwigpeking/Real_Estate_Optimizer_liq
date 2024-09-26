# phasing_color_updater.rb
module Real_Estate_Optimizer
  module PhasingColorUpdater
    def self.update_phasing_colors
      model = Sketchup.active_model
      
      model.start_operation('Update Phasing Colors', true)

      clear_existing_phasing(model)

      building_instances = find_building_instances(model)

      building_instances.each do |instance|
        construction_init_time = instance.get_attribute('dynamic_attributes', 'construction_init_time', 0)
        color = calculate_color(construction_init_time)
        create_phasing_geometry(instance, color)
      end

      model.commit_operation
    end

    def self.clear_existing_phasing(model)
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

    def self.find_building_instances(model)
      model.active_entities.grep(Sketchup::ComponentInstance).select do |instance|
        instance.definition.attribute_dictionaries && instance.definition.attribute_dictionaries['building_data']
      end
    end

    def self.calculate_color(init_time, max_time = 72)
      ratio = 1 - (init_time.to_f / max_time)
      blue = (255 * ratio).to_i
      Sketchup::Color.new(0, 0, blue)
    end

    def self.create_phasing_geometry(instance, color)
      definition = instance.definition
      phasing_group = definition.entities.add_group
      phasing_group.layer = instance.model.layers["liq_phasing"]

      bounds = definition.bounds
      
      points = [
        bounds.corner(0), bounds.corner(1), bounds.corner(3), bounds.corner(2),
        bounds.corner(4), bounds.corner(5), bounds.corner(7), bounds.corner(6)
      ]
      
      face = phasing_group.entities.add_face(points[0], points[1], points[2], points[3])
      face.pushpull(bounds.depth)
      
      phasing_group.entities.grep(Sketchup::Face).each do |face|
        face.material = color
        face.back_material = color
      end

      phasing_group.set_attribute('PhasingColorUpdater', 'is_phasing_geometry', true)
    end

    def self.setup_observer
      model = Sketchup.active_model
      observer = PhasingObserver.new
      model.add_observer(observer)
    end

    class PhasingObserver < Sketchup::ModelObserver
      def onTransactionCommit(model)
        PhasingColorUpdater.update_phasing_colors
      end
    end
  end
end

# Call this method to set up the observer when the plugin is loaded

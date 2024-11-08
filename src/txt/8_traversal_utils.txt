# traversal_utils.rb
module Real_Estate_Optimizer
  module TraversalUtils
    def self.traverse_building_instances(model, max_depth = 3)
      building_instances = []
      
      def self.recursive_search(entities, transformation, current_depth, max_depth, building_instances)
        return if current_depth > max_depth
        
        entities.each do |entity|
          if entity.is_a?(Sketchup::ComponentInstance)
            if entity.definition.attribute_dictionary('building_data')
              world_transformation = transformation * entity.transformation
              building_instances << [entity, world_transformation]
            end
            
            recursive_search(entity.definition.entities, transformation * entity.transformation, current_depth + 1, max_depth, building_instances)
          elsif entity.is_a?(Sketchup::Group)
            recursive_search(entity.entities, transformation * entity.transformation, current_depth + 1, max_depth, building_instances)
          end
        end
      end

      recursive_search(model.active_entities, Geom::Transformation.new, 1, max_depth, building_instances)
      
      building_instances
    end
  end
end
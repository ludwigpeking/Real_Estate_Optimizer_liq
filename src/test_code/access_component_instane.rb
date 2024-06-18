require 'sketchup.rb'

module UrbanBanal
  module InitialTimeSum
    def self.calculate_sum
      model = Sketchup.active_model
      entities = model.active_entities

      # Initialize the sum
      total_initial_time = 0

      # Iterate through all entities in the model
      entities.each do |entity|
        # Check if the entity is a component instance
        if entity.is_a?(Sketchup::ComponentInstance)
          # Check if the component name starts with "urban_banal"
          if entity.definition.name.start_with?("urban_banal")
            # Get the initial_time attribute value
            initial_time = entity.get_attribute('dynamic_attributes', 'initial_time')
            # If the initial_time attribute is present, add its value to the sum
            if initial_time
              total_initial_time += initial_time.to_f
            end
          end
        end
      end

      # Prompt the total sum in SketchUp
      UI.messagebox("Total Initial Time: #{total_initial_time}")
    end
  end
end

# To run the calculation, call:
UrbanBanal::InitialTimeSum.calculate_sum

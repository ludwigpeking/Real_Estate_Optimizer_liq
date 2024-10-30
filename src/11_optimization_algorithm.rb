# optimization_algorithm.rb

require_relative '8_cashflow'
require_relative '8_output'
require_relative  '8_traversal_utils'
require_relative '8_financial_calculations'


module Real_Estate_Optimizer
  module OptimizationAlgorithm
    def self.optimize(buildings, settings)
      puts "Optimizing #{buildings.length} buildings"
      puts "First building type: #{buildings.first.class}"
      population_size = 100
      generations = 100
      mutation_rate = 0.1

      population = initialize_population(buildings, population_size)

      best_solution = nil
      best_fitness = -Float::INFINITY

      generations.times do |gen|
        fitness_scores = evaluate_population(population, buildings, settings)
        current_best = population[fitness_scores.index(fitness_scores.max)]
        current_best_fitness = fitness_scores.max

        if current_best_fitness > best_fitness
          best_solution = current_best
          best_fitness = current_best_fitness
          update_model_with_solution(buildings, best_solution)
          Output.update_output_data(Sketchup.active_model)
        end

        new_population = []
        while new_population.size < population_size
          parent1 = tournament_select(population, fitness_scores)
          parent2 = tournament_select(population, fitness_scores)
          child = crossover(parent1, parent2)
          mutate(child, mutation_rate)
          new_population << child
        end

        population = new_population
      end

      best_solution
    end

    def self.initialize_population(buildings, size)
      population = []
      size.times do
        schedule = buildings.map { rand(0..47) }  # Random init time between 0 and 72 months
        population << schedule
      end
      population
    end

    def self.evaluate_population(population, buildings, settings)
      population.map { |schedule| objective_function(schedule, buildings, settings) }
    end

    def self.tournament_select(population, fitness_scores)
      tournament_size = 5
      tournament = population.sample(tournament_size)
      tournament_fitness = fitness_scores.values_at(*population.each_index.select { |i| tournament.include?(population[i]) })
      tournament[tournament_fitness.index(tournament_fitness.max)]
    end

    def self.crossover(parent1, parent2)
      crossover_point = rand(parent1.length)
      parent1[0...crossover_point] + parent2[crossover_point..-1]
    end

    def self.mutate(child, rate)
      child.map! { |gene| rand < rate ? rand(0..47) : gene }
    end

    def self.objective_function(schedule, buildings, settings)
      update_model_with_solution(buildings, schedule)
      cashflow_data = CashFlowCalculator.calculate_and_print_full_cashflow_table
      monthly_cashflow = CashFlowCalculator.calculate_monthly_cashflow(cashflow_data)
      key_indicators = CashFlowCalculator.calculate_key_indicators(monthly_cashflow)

      irr = key_indicators[:yearly_irr] || 0
      moic = key_indicators[:moic] || 0
      direction_priority = calculate_direction_priority(schedule, buildings, settings)
      property_line_priority = calculate_property_line_priority(schedule, buildings, settings)

      (settings['irr_weight'] * irr + settings['moic_weight'] * moic) * direction_priority * property_line_priority
    end

    def self.update_model_with_solution(buildings, schedule)
      Sketchup.active_model.start_operation('Update Building Init Times', true)
      schedule.each_with_index do |init_time, index|
        if index < buildings.length
          building, _ = buildings[index]  # Unpack the array, ignoring the transformation
          if building.is_a?(Sketchup::ComponentInstance)
            init_time = [init_time, 47].min
            building.set_attribute('dynamic_attributes', 'construction_init_time', init_time)
          else
            puts "Warning: Building at index #{index} is not a ComponentInstance"
          end
        else
          puts "Warning: Schedule has more elements than buildings"
        end
      end
      Sketchup.active_model.commit_operation
    end

    def self.calculate_direction_priority(schedule, buildings, settings)
      priority_sum = 0
      buildings.each_with_index do |building_data, index|
        building, transformation = building_data  # Unpack the array
        x_coord = transformation.origin.x.to_m
        y_coord = transformation.origin.y.to_m
        init_time = schedule[index]
        priority_value = settings['north_south_weight'] * y_coord + settings['east_west_weight'] * x_coord
        priority_sum += priority_value * (72 - init_time) / 72.0  # Earlier init times have higher priority
      end
      Math.exp(priority_sum / schedule.size)  # Normalize and ensure positive value
    end

  

    def self.calculate_property_line_priority(schedule, buildings, settings)
      property_line_order = settings['property_line_order']
      return 1.0 if property_line_order.empty?
    
      priority_sum = 0
      total_buildings = schedule.size
    
      buildings.each_with_index do |building_data, index|
        building, _ = building_data  # Unpack the array, ignoring the transformation
        property_line_keyword = building.get_attribute('dynamic_attributes', 'property_line_keyword')
        init_time = schedule[index]
        if property_line_keyword
          priority_index = property_line_order.index(property_line_keyword)
          if priority_index
            priority_value = (property_line_order.size - priority_index).to_f / property_line_order.size
            priority_sum += priority_value * (72 - init_time) / 72.0  # Earlier init times have higher priority
          end
        end
      end
    
      average_priority = priority_sum / total_buildings
      Math.exp(average_priority - 0.5)
    end

    def self.find_building_instances(model)
      TraversalUtils.traverse_building_instances(model, max_depth)

    end
  end
end
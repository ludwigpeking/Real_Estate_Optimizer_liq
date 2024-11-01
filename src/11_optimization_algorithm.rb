require_relative '8_cashflow'
require_relative '8_output'
require_relative '8_traversal_utils'
require_relative '8_financial_calculations'

module Real_Estate_Optimizer
  module OptimizationAlgorithm
    def self.optimize(buildings, settings, dialog = nil)
      return nil if buildings.empty?
      return nil unless validate_settings(settings)
      
      puts "\n=== Starting Optimization ==="
      puts "Number of buildings: #{buildings.length}"

      # Phase 1: Group identical buildings
      building_groups = group_identical_buildings(buildings)
      puts "Building groups:"
      building_groups.each do |type, instances|
        puts "Type #{type}: #{instances.length} instances"
      end

      # Phase 2: Optimize timing for each building type
      best_type_schedule = optimize_building_types(building_groups, settings)
      puts "\nBest type schedule found:"
      best_type_schedule.each do |type, time_slots|
        puts "Type #{type}: #{time_slots.inspect}"
      end

      # Phase 3: Assign specific instances based on priorities
      final_assignments = assign_instances_to_slots(best_type_schedule, building_groups, settings)
      
      # Phase 4: Apply final solution
      if final_assignments
        update_model_with_solution(final_assignments)
        puts "=== Optimization Complete ==="
      else
        puts "=== Optimization Failed ==="
      end
      
      final_assignments
    end

    class Solution
      attr_reader :genes, :fitness
      
      def initialize(building_groups, randomize = true)
        @genes = {}
        if randomize
          building_groups.each do |type, instances|
            count = instances.length
            @genes[type] = generate_initial_intervals(count)
          end
        end
        @fitness = nil
        @improvement_history = {}  # Track successful mutations
      end

      def generate_initial_intervals(count)
        case rand(3)
        when 0  # All start together
          [rand(0..24)] + Array.new(count - 1, 0)
        when 1  # Sequential with small intervals
          first = rand(0..12)  # Leave room for sequence
          intervals = Array.new(count - 1) { rand(1..3) }
          [first] + intervals
        when 2  # Random intervals
          first = rand(0..24)
          intervals = Array.new(count - 1) { rand(0..6) }
          [first] + intervals
        end
      end

      def get_absolute_times
        schedule = {}
        @genes.each do |type, intervals|
          times = []
          current_time = intervals[0]  # First time is absolute
          times << current_time
          
          intervals[1..-1].each do |interval|
            current_time = [current_time + interval, 24].min
            times << current_time
          end
          schedule[type] = times
        end
        schedule
      end

      def mutate!(rate)
        @genes.each do |type, intervals|
          intervals.each_with_index do |value, i|
            if rand < rate
              # Use improvement history to guide mutation
              history_key = "#{type}_#{i}"
              last_success = @improvement_history[history_key]
              
              if last_success && last_success.abs > 0.01  # Only use history if significant improvement
                step = rand(1..3) * last_success.positive? ? 1 : -1
              else
                step = rand(-3..3)
              end

              # Apply mutation
              if i == 0  # First value is absolute start time
                new_value = [[value + step, 0].max, 24].min
                intervals[i] = new_value
              else  # Subsequent values are intervals
                new_value = [[value + step, 0].max, 6].min  # Max interval of 6 months
                intervals[i] = new_value
              end
            end
          end
        end
      end

      def crossover(other)
        child = Solution.new({}, false)  # Create empty solution
        
        @genes.each do |type, intervals|
          child.genes[type] = intervals.map.with_index do |value, i|
            if rand < 0.5
              value
            else
              other.genes[type][i]
            end
          end
        end
        
        child
      end

      def record_improvement(type, index, success)
        history_key = "#{type}_#{index}"
        @improvement_history[history_key] = success
      end
    end

    def self.optimize_building_types(building_groups, settings)
      population_size = 200  # Larger initial population
      elite_size = 20      # Keep top 100 solutions
      generations = 30
      mutation_rate = 0.2

      # Initialize population
      population = Array.new(population_size) { Solution.new(building_groups) }
      best_solution = nil
      best_fitness = -Float::INFINITY
      generations_without_improvement = 0

      generations.times do |gen|
        puts "\nGeneration #{gen + 1}"

        # Evaluate population
        population.each do |solution|
          schedule = solution.get_absolute_times
          fitness = evaluate_type_schedule(schedule, building_groups, settings)
          solution.instance_variable_set(:@fitness, fitness)
        end

        # Sort by fitness
        population.sort_by! { |solution| -solution.fitness }

        # Update best solution
        if population.first.fitness > best_fitness
          best_solution = population.first
          best_fitness = population.first.fitness
          generations_without_improvement = 0
          puts "Generation #{gen + 1}: New best fitness = #{best_fitness}"
        else
          generations_without_improvement += 1
        end

        # Early stopping if no improvement for many generations
        break if generations_without_improvement > 10

        # Create new population
        new_population = population[0...elite_size]  # Keep elite solutions

        # Fill rest with tournament selection and crossover
        while new_population.size < population_size
          parent1 = tournament_select(population, 5)
          parent2 = tournament_select(population, 5)
          
          child = parent1.crossover(parent2)
          child.mutate!(mutation_rate)
          
          new_population << child
        end

        population = new_population
      end

      best_solution.get_absolute_times
    end

    def self.tournament_select(population, tournament_size)
      tournament = population.sample(tournament_size)
      tournament.max_by { |solution| solution.fitness }
    end

    def self.evaluate_type_schedule(schedule, building_groups, settings)
      return -Float::INFINITY unless verify_schedule(schedule, building_groups)
      
      original_states = store_building_states(building_groups)
      
      begin
        # Apply schedule
        schedule.each do |type, times|
          instances = building_groups[type]
          times.each_with_index do |time, i|
            instances[i][0].set_attribute('dynamic_attributes', 
              'construction_init_time', time)
          end
        end

        # Calculate financial metrics
        cashflow_data = CashFlowCalculator.calculate_and_print_full_cashflow_table
        return -Float::INFINITY unless cashflow_data

        monthly_cashflow = CashFlowCalculator.calculate_monthly_cashflow(cashflow_data)
        key_indicators = CashFlowCalculator.calculate_key_indicators(monthly_cashflow)

        irr = key_indicators[:yearly_irr] || -100
        moic = key_indicators[:moic] || 0

        # Scale metrics
        scaled_irr = irr/100
        scaled_moic = moic 

        # Combined fitness
        fitness = (settings['irr_weight'] * scaled_irr + 
                  settings['moic_weight'] * scaled_moic)

        puts "IRR: #{irr}%, MOIC: #{moic}x"
        fitness
      ensure
        restore_building_states(original_states)
      end
    end

    def self.group_identical_buildings(buildings)
      groups = {}
      buildings.each do |building, transformation|
        type = building.definition.name
        groups[type] ||= []
        groups[type] << [building, transformation]
      end
      groups
    end

    def self.verify_schedule(schedule, building_groups)
      schedule.each do |type, slots|
        expected_count = building_groups[type].length
        actual_count = slots.length
        
        if expected_count != actual_count
          puts "Warning: Invalid schedule for type #{type}"
          puts "Expected #{expected_count} slots, got #{actual_count}"
          return false
        end

        # Verify all times are within bounds
        if slots.any? { |time| time < 0 || time > 24 }
          puts "Warning: Invalid time found in schedule"
          return false
        end
      end
      true
    end

    def self.store_building_states(building_groups)
      states = {}
      building_groups.each do |_, instances|
        instances.each do |building, _|
          states[building] = building.get_attribute('dynamic_attributes', 'construction_init_time')
        end
      end
      states
    end

    def self.restore_building_states(states)
      states.each do |building, time|
        building.set_attribute('dynamic_attributes', 'construction_init_time', time)
      end
    end

    def self.validate_settings(settings)
      required_keys = ['irr_weight', 'moic_weight', 'property_line_order']
      missing_keys = required_keys - settings.keys
      
      if missing_keys.any?
        puts "Missing required settings: #{missing_keys.join(', ')}"
        return false
      end
      true
    end

    def self.assign_instances_to_slots(type_schedule, building_groups, settings)
      final_assignments = {}
      available_slots_by_type = type_schedule.dup
    
      begin
        # Process each property line according to priority
        settings['property_line_order'].each do |property_line|
          type_schedule.each do |type, _|
            next unless available_slots_by_type[type]&.any?
    
            # Get instances for this type in this property line
            instances = building_groups[type].select do |building, _|
              building.get_attribute('dynamic_attributes', 'property_line_keyword') == property_line
            end
            
            # Skip if no instances found
            next if instances.empty?
    
            # Sort instances by direction priority
            sorted_instances = sort_by_direction_priority(instances, settings)
            
            # Get available times for this type
            available_times = available_slots_by_type[type]
    
            # Assign times to instances in priority order
            sorted_instances.each do |building, _|
              next if final_assignments.key?(building)
              time = available_times.shift
              final_assignments[building] = time if time
            end
          end
        end
    
        # Handle any remaining unassigned instances
        type_schedule.each do |type, _|
          remaining_instances = building_groups[type].reject { |building, _| final_assignments.key?(building) }
          next if remaining_instances.empty?
    
          # Sort remaining instances by direction priority
          sorted_remaining = sort_by_direction_priority(remaining_instances, settings)
          
          # Assign any remaining times
          sorted_remaining.each do |building, _|
            time = available_slots_by_type[type]&.shift
            final_assignments[building] = time if time
          end
        end
    
        final_assignments
      rescue => e
        puts "Error in instance assignment: #{e.message}"
        puts e.backtrace
        nil
      end
    end
    
    def self.sort_by_direction_priority(instances, settings)
      ns_weight = settings['north_south_weight'].to_f
      ew_weight = settings['east_west_weight'].to_f
      
      instances.sort_by do |_, transformation|
        x_coord = transformation.origin.x.to_m
        y_coord = transformation.origin.y.to_m
        
        # Combine weighted coordinates
        # Negative y_coord means south, positive x_coord means east
        priority_score = (ns_weight * -y_coord) + (ew_weight * - x_coord)
        
        # Return priority score (higher score = higher priority)
        -priority_score  # Negative because sort_by is ascending
      end
    end

    def self.update_model_with_solution(assignments)
      model = Sketchup.active_model
      model.start_operation('Update Building Init Times', true)
      
      begin
        assignments.each do |building, init_time|
          building.set_attribute('dynamic_attributes', 'construction_init_time', init_time)
        end
        
        # Update phasing colors
        if defined?(PhasingColorUpdater)
          PhasingColorUpdater.update_phasing_colors
        end
        
        model.commit_operation
      rescue => e
        puts "Error updating model: #{e.message}"
        puts e.backtrace
        model.abort_operation
      end
    end
  end
end
require_relative '8_cashflow'
require_relative '8_output'
require_relative '8_traversal_utils'
require_relative '8_financial_calculations'

module Real_Estate_Optimizer
  module OptimizationAlgorithm
    REQUIRED_SETTINGS = [
      'irr_weight', 
      'moic_weight', 
      'property_line_order',
      'max_timeline'
    ]

    def self.optimize(buildings, settings, dialog = nil)
      return nil if buildings.empty? || !validate_settings(settings)
      
      puts "\n=== Starting Optimization ==="
      puts "Number of buildings: #{buildings.length}"

      # Phase 1: Group buildings and cache evaluations
      building_groups = group_identical_buildings(buildings)
      @evaluation_cache = {}  # Cache for fitness evaluations
      
      # Phase 2: Optimize with improved genetic algorithm
      best_type_schedule = optimize_building_types(building_groups, settings)
      
      # Phase 3: Assign instances based on priorities
      final_assignments = assign_instances_to_slots(best_type_schedule, building_groups, settings)
      
      if final_assignments
        update_model_with_solution(final_assignments)
        puts "=== Optimization Complete ==="
      end
      
      final_assignments
    end
      
    def self.validate_settings(settings)
      missing_keys = REQUIRED_SETTINGS - settings.keys
      
      if missing_keys.any?
        puts "Missing required settings: #{missing_keys.join(', ')}"
        return false
      end

      # Validate timeline range
      max_timeline = settings['max_timeline'].to_i
      if max_timeline < 12 || max_timeline > 72
        puts "Invalid max_timeline: must be between 12 and 72 months"
        return false
      end

      true
    end
    class Solution
      attr_reader :genes, :fitness
      
      def initialize(building_groups, settings, randomize = true)
        @genes = {}
        @settings = settings
        if randomize
          building_groups.each do |type, instances|
            @genes[type] = generate_initial_intervals(instances.length)
          end
        end
        @fitness = nil
      end
    
      def generate_initial_intervals(count)
        max_time = @settings['max_timeline']
        # Generate initial start time in first 70% of timeline
        first = rand(0..(max_time * 0.7).to_i)
        
        # Generate reasonable intervals (2-8 months)
        intervals = Array.new(count - 1) { rand(2..8) }
        
        # Scale if needed to fit timeline
        total_time = first + intervals.sum
        if total_time > max_time
          scale_factor = max_time.to_f / total_time
          intervals = intervals.map { |i| (i * scale_factor).round }
        end
        
        [first] + intervals
      end
    
      def mutate!(rate)
        max_time = @settings['max_timeline']
        
        @genes.each do |type, intervals|
          intervals.each_with_index do |value, i|
            if rand < rate
              if i == 0  # Start time
                # Smaller changes to start time
                delta = rand(-4..4)
                intervals[i] = [[value + delta, 0].max, max_time].min
              else  # Intervals
                # Favor small adjustments (80% chance)
                if rand < 0.8
                  delta = rand(-2..2)
                  intervals[i] = [[value + delta, 1].max, 8].min
                else
                  # Occasionally allow larger changes
                  intervals[i] = rand(1..8)
                end
              end
            end
          end
          
          # Ensure we don't exceed timeline
          total_time = intervals.sum
          if total_time > max_time
            scale_factor = max_time.to_f / total_time
            intervals.map! { |i| (i * scale_factor).round }
          end
        end
      end
    
      def crossover(other)
        child = Solution.new({}, @settings, false)
        child.genes = {}
        
        @genes.each do |type, intervals|
          # Single-point crossover
          point = rand(intervals.length)
          child.genes[type] = intervals[0...point] + other.genes[type][point..]
          
          # Ensure timeline constraint
          total_time = child.genes[type].sum
          if total_time > @settings['max_timeline']
            scale_factor = @settings['max_timeline'].to_f / total_time
            child.genes[type] = child.genes[type].map { |v| (v * scale_factor).round }
          end
        end
        
        child
      end
    end
    def self.optimize_building_types(building_groups, settings)
      population_size = 200  # Larger population
      elite_size = 20       # Keep more elites
      generations = 30
      mutation_rate = 0.2   # Fixed, moderate mutation rate
      
      # Initialize population
      population = Array.new(population_size) { Solution.new(building_groups, settings) }
      
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
          
          # Print progress
          puts "Generation #{gen + 1}: New best fitness = #{best_fitness}"
        else
          generations_without_improvement += 1
        end
        
        # Early stopping if stuck
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

    def self.tournament_select_with_diversity(population, tournament_size, population_avg)
      tournament = population.sample(tournament_size)
      
      # 20% chance to prefer diverse solutions
      if rand < 0.2
        # Select solution that's most different from population average
        tournament.max_by { |solution| (solution.fitness - population_avg).abs }
      else
        # Normal selection by fitness
        tournament.max_by { |solution| solution.fitness }
      end
    end

    def self.tournament_select(population, tournament_size)
      tournament = population.sample(tournament_size)
      tournament.max_by { |solution| solution.fitness }
    end

    def self.evaluate_type_schedule(schedule, building_groups, settings)
      return -Float::INFINITY unless verify_schedule(schedule, building_groups, settings)
      
      cache_key = schedule_hash(schedule, settings)
      return @evaluation_cache[cache_key] if @evaluation_cache.key?(cache_key)
      
      original_states = store_building_states(building_groups)
      
      begin
        schedule.each do |type, times|
          instances = building_groups[type]
          times.each_with_index do |time, i|
            instances[i][0].set_attribute('dynamic_attributes', 
              'construction_init_time', time)
          end
        end

        cashflow_data = CashFlowCalculator.calculate_and_print_full_cashflow_table
        return -Float::INFINITY unless cashflow_data

        monthly_cashflow = CashFlowCalculator.calculate_monthly_cashflow(cashflow_data)
        key_indicators = CashFlowCalculator.calculate_key_indicators(monthly_cashflow)

        irr = key_indicators[:yearly_irr] || -100
        moic = key_indicators[:moic] || 0

        scaled_irr = irr/100
        scaled_moic = moic 

        fitness = (settings['irr_weight'] * scaled_irr + 
                  settings['moic_weight'] * scaled_moic)

        @evaluation_cache[cache_key] = fitness
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

    def self.verify_schedule(schedule, building_groups, settings)
      max_timeline = settings['max_timeline']
      
      schedule.each do |type, slots|
        expected_count = building_groups[type].length
        actual_count = slots.length
        
        if expected_count != actual_count
          puts "Warning: Invalid schedule for type #{type}"
          puts "Expected #{expected_count} slots, got #{actual_count}"
          return false
        end

        if slots.any? { |time| time < 0 || time > max_timeline }
          puts "Warning: Invalid time found in schedule (exceeds max_timeline)"
          return false
        end
      end
      true
    end

    def self.schedule_hash(schedule, settings)
      "#{schedule.to_s}-#{settings['max_timeline']}".hash
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

    def self.assign_instances_to_slots(type_schedule, building_groups, settings)
      final_assignments = {}
      available_slots_by_type = type_schedule.dup
    
      begin
        settings['property_line_order'].each do |property_line|
          type_schedule.each do |type, _|
            next unless available_slots_by_type[type]&.any?
    
            instances = building_groups[type].select do |building, _|
              building.get_attribute('dynamic_attributes', 'property_line_keyword') == property_line
            end
            
            next if instances.empty?
    
            sorted_instances = sort_by_direction_priority(instances, settings)
            available_times = available_slots_by_type[type]
    
            sorted_instances.each do |building, _|
              next if final_assignments.key?(building)
              time = available_times.shift
              final_assignments[building] = time if time
            end
          end
        end
    
        type_schedule.each do |type, _|
          remaining_instances = building_groups[type].reject { |building, _| final_assignments.key?(building) }
          next if remaining_instances.empty?
    
          sorted_remaining = sort_by_direction_priority(remaining_instances, settings)
          
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
        
        priority_score = (ns_weight * -y_coord) + (ew_weight * -x_coord)
        -priority_score
      end
    end

    def self.update_model_with_solution(assignments)
      model = Sketchup.active_model
      model.start_operation('Update Building Init Times', true)
      
      begin
        assignments.each do |building, init_time|
          building.set_attribute('dynamic_attributes', 'construction_init_time', init_time)
        end
        
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
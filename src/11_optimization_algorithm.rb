require_relative '8_cashflow'
require_relative '8_output'
require_relative '8_traversal_utils'
require_relative '8_financial_calculations'

module Real_Estate_Optimizer
  module OptimizationAlgorithm
    REQUIRED_SETTINGS = [
      'optimization_method',
      'max_timeline',
      'property_line_order'
    ]

    def self.optimize(buildings, settings, dialog = nil)
      return nil if buildings.empty? || !validate_settings(settings)
      
      puts "\n=== Starting Optimization ==="
      puts "Number of buildings: #{buildings.length}"

      # Phase 1: Group buildings and cache evaluations
      building_groups = group_identical_buildings(buildings)
      @evaluation_cache = {}  # Cache for fitness evaluations
      
      # Phase 2: Optimize with improved genetic algorithm
      best_solution = optimize_building_types(building_groups, settings)
      
      # Phase 3: Assign instances based on priorities
      final_assignments = assign_instances_to_slots(best_solution.get_absolute_times, building_groups, settings)
      
      if final_assignments
        update_model_with_solution(final_assignments)
        
        # Calculate final NPV with proper monthly rate
        final_cashflow = CashFlowCalculator.calculate_and_print_full_cashflow_table
        annual_discount_rate = settings['discount_rate']
        monthly_discount_rate = (1 + annual_discount_rate)**(1.0/12) - 1
        final_npv = CashFlowCalculator.npv(final_cashflow[:monthly_cashflow], monthly_discount_rate)
        
        puts "\nFinal Results:"
        puts "Optimization Fitness Score (scaled): #{best_solution.fitness.round(4)}"
        puts "Raw NPV: #{(best_solution.fitness * 1_000_000).round(2)} yuan"
        puts "Final NPV after applying solution: #{final_npv.round(2)} yuan"
        puts "=== Optimization Complete ==="
      end
      
      final_assignments
    end

    
    class Solution
      attr_reader :fitness, :genes, :scene_switches  # Made scene_switches readable
      attr_writer :genes, :scene_switches  # Made both writable
      
      def initialize(building_groups, settings, randomize = true)
        @genes = {}
        @scene_switches = {}
        @settings = settings
        
        if randomize
          # Collect all unique apartment types across all building types
          apartment_types = Set.new
          building_groups.each do |building_type, instances|
            instances.each do |instance, _|
              # Get apartment stocks from building definition
              stocks = JSON.parse(instance.definition.get_attribute('building_data', 'apartment_stocks') || '{}')
              apartment_types.merge(stocks.keys)
            end
            @genes[building_type] = generate_initial_intervals(instances.length)
          end
          
          # Generate scene switch times for each apartment type
          apartment_types.each do |apt_type|
            @scene_switches[apt_type] = rand(0..@settings['max_timeline'])
          end
        end
        @fitness = nil
      end

      def fitness
        @fitness || -Float::INFINITY
      end
    
      # Made this method public by moving it out of private section
      def get_absolute_times
        schedule = {}
        @genes.each do |building_type, intervals|
          times = []
          current_time = intervals[0]  # First time is absolute
          times << current_time
          
          # Convert intervals to absolute times
          intervals[1..-1].each do |interval|
            current_time += interval
            current_time = [@settings['max_timeline'], current_time].min
            times << current_time
          end
          schedule[building_type] = times
        end
        schedule
      end

      def mutate!(rate)
        max_time = @settings['max_timeline']
        
        # Mutate building construction timings
        @genes.each do |building_type, intervals|
          intervals.each_with_index do |value, i|
            if rand < rate
              if i == 0  # Start time
                delta = rand(-4..4)
                intervals[i] = [[value + delta, 0].max, max_time].min
              else  # Intervals
                if rand < 0.8
                  delta = rand(-2..2)
                  intervals[i] = [[value + delta, 1].max, 8].min
                else
                  intervals[i] = rand(1..8)
                end
              end
            end
          end
          
          # Ensure timeline constraints
          total_time = intervals.sum
          if total_time > max_time
            scale_factor = max_time.to_f / total_time
            intervals.map! { |i| (i * scale_factor).round }
          end
        end
    
        # Mutate scene switch times for each apartment type
        @scene_switches.each do |apt_type, switch_time|
          if rand < rate
            delta = rand(-6..6)
            @scene_switches[apt_type] = [[switch_time + delta, 0].max, max_time].min
          end
        end
      end
    
      def crossover(other)
        child = Solution.new({}, @settings, false)
        child_genes = {}
        child_scene_switches = {}
        
        # Crossover building construction timings
        @genes.each do |building_type, intervals|
          point = rand(intervals.length)
          child_genes[building_type] = intervals[0...point] + other.genes[building_type][point..]
          
          # Ensure timeline constraint
          total_time = child_genes[building_type].sum
          if total_time > @settings['max_timeline']
            scale_factor = @settings['max_timeline'].to_f / total_time
            child_genes[building_type] = child_genes[building_type].map { |v| (v * scale_factor).round }
          end
        end
        
        # Crossover scene switch times
        @scene_switches.each_key do |apt_type|
          # Randomly select scene switch time from either parent
          child_scene_switches[apt_type] = rand < 0.5 ? @scene_switches[apt_type] : other.scene_switches[apt_type]
        end
        
        child.genes = child_genes
        child.scene_switches = child_scene_switches
        child
      end
    
      private
    
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
    end
      
    def self.validate_settings(settings)
      # Check base required settings
      missing_keys = REQUIRED_SETTINGS - settings.keys
      
      # Check method-specific required settings
      if settings['optimization_method'] == 'irr_moic'
        method_keys = ['irr_weight', 'moic_weight']
        missing_keys += method_keys - settings.keys
      elsif settings['optimization_method'] == 'npv'
        method_keys = ['discount_rate']
        missing_keys += method_keys - settings.keys
      end
    
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
    
      # Validate discount rate if using NPV
      if settings['optimization_method'] == 'npv'
        discount_rate = settings['discount_rate'].to_f
        if discount_rate <= 0 || discount_rate >= 1
          puts "Invalid discount rate: must be between 0 and 1"
          return false
        end
      end
    
      true
    end
 
    def self.optimize_building_types(building_groups, settings)
      # Configuration parameters
      population_size = 100   # Larger population for better diversity
      elite_size = 10        # Keep top 10% as elites
      generations = 50       # Maximum generations
      mutation_rate = 0.2    # Moderate mutation rate
      tournament_size = 5    # Tournament selection size
      max_stagnant_gens = 10 # Early stopping threshold
      
      puts "\n=== Starting Genetic Algorithm Optimization ==="
      puts "Population: #{population_size}, Generations: #{generations}, Mutation Rate: #{mutation_rate}"
      
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
          fitness = evaluate_type_schedule(schedule, solution.scene_switches, building_groups, settings)
          solution.instance_variable_set(:@fitness, fitness)
        end
        
        # Sort by fitness
        population.sort_by! { |solution| -(solution.fitness || -Float::INFINITY) }    

        # Update best solution
        if population.first.fitness > best_fitness
          best_solution = population.first
          best_fitness = population.first.fitness
          generations_without_improvement = 0
          
          # Print progress
          puts "Generation #{gen + 1}: New best fitness = #{best_fitness.round(4)}"
          
          # Print brief genotype summary for best solution
          best_schedule = best_solution.get_absolute_times
          puts "Best solution schedule summary:"
          best_schedule.each do |building_type, times|
            puts "  #{building_type}: #{times.length} buildings, " \
                 "start: #{times.first}, end: #{times.last}"
          end

          # Print scene switches
          puts "\nScene switch times:"
          best_solution.scene_switches.sort.each do |apt_type, switch_time|
            puts "  #{apt_type} => Month #{switch_time}"
          end
        else
          generations_without_improvement += 1
          puts "Generation #{gen + 1}: No improvement (#{generations_without_improvement})"
        end
        
        # Early stopping if stuck
        if generations_without_improvement > max_stagnant_gens
          puts "\nStopping early: No improvement for #{max_stagnant_gens} generations"
          break
        end
        
        # Create new population
        new_population = population[0...elite_size]  # Keep elite solutions
        
        # Fill rest with tournament selection and crossover
        while new_population.size < population_size
          parent1 = tournament_select(population, tournament_size)
          parent2 = tournament_select(population, tournament_size)
          
          child = parent1.crossover(parent2)
          child.mutate!(mutation_rate)
          
          new_population << child
        end
        
        population = new_population
      end
      
      puts "\n=== Optimization Complete ==="
      puts "Final best fitness: #{best_fitness.round(4)}"
      
      best_solution  # Return the complete solution object instead of just the schedule
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
    
      if settings['use_property_line_priority']
        # Existing property line priority logic
        settings['property_line_order'].each do |property_line|
          type_schedule.each do |type, _|
            next unless available_slots_by_type[type]&.any?
    
            instances = building_groups[type].select do |building, transformation|
              position = building.definition.bounds.center.transform(transformation)
              detected_line = CashFlowCalculator.find_containing_property_line(
                position, 
                CashFlowCalculator.find_property_line_components(Sketchup.active_model)
              )
              property_line_keyword = detected_line&.definition&.get_attribute('dynamic_attributes', 'keyword')
              property_line_keyword == property_line
            end
    
            next if instances.empty?
    
            sorted_instances = sort_by_direction_priority(
              instances,
              settings['north_south_weight'].to_f,
              settings['east_west_weight'].to_f
            )
    
            sorted_instances.each do |building, _|
              next if final_assignments.key?(building)
              time = available_slots_by_type[type].shift
              final_assignments[building] = time if time
            end
          end
        end
      else
        # Direction-only priority logic
        type_schedule.each do |type, _|
          next unless available_slots_by_type[type]&.any?
    
          instances = building_groups[type]
          sorted_instances = sort_by_direction_priority(
            instances,
            settings['north_south_weight'].to_f,
            settings['east_west_weight'].to_f
          )
    
          sorted_instances.each do |building, _|
            next if final_assignments.key?(building)
            time = available_slots_by_type[type].shift
            final_assignments[building] = time if time
          end
        end
      end
    
      final_assignments
    end
      
    def self.sort_remaining_instances(instances, property_line_order, ns_weight, ew_weight)
      # Group instances by property line
      instances_by_line = instances.group_by do |building, _|
        position = building[0].definition.bounds.center.transform(building[1])
        detected_line = CashFlowCalculator.find_containing_property_line(
          position, 
          CashFlowCalculator.find_property_line_components(Sketchup.active_model)
        )
        detected_line&.definition&.get_attribute('dynamic_attributes', 'keyword')
      end

      sorted_instances = []
      
      # First add instances from property lines in the priority order
      property_line_order.each do |line|
        if instances_by_line[line]
          sorted_line_instances = sort_by_direction_priority(
            instances_by_line[line],
            ns_weight,
            ew_weight
          )
          sorted_instances.concat(sorted_line_instances)
        end
      end

      # Then add any remaining instances from property lines not in the priority list
      remaining_lines = instances_by_line.keys - property_line_order
      remaining_lines.each do |line|
        sorted_line_instances = sort_by_direction_priority(
          instances_by_line[line],
          ns_weight,
          ew_weight
        )
        sorted_instances.concat(sorted_line_instances)
      end

      sorted_instances
    end

    def self.sort_by_direction_priority(instances, ns_weight, ew_weight)
      puts "  Sorting by direction (NS weight: #{ns_weight}, EW weight: #{ew_weight})"
      
      instances.sort_by do |building, transformation|
        bounds = building.definition.bounds
        center = bounds.center.transform(transformation)
        
        ns_score = center.y * ns_weight
        ew_score = center.x * ew_weight
        total_score = ns_score - ew_score
        
        puts "    Building #{building.definition.name} at (#{center.x.round(2)}, #{center.y.round(2)}) score: #{total_score.round(4)}"
        
        total_score
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

    def self.evaluate_type_schedule(schedule, scene_switches, building_groups, settings)
      return -Float::INFINITY unless verify_schedule(schedule, building_groups, settings)
      
      cache_key = schedule_hash(schedule, settings)
      return @evaluation_cache[cache_key] if @evaluation_cache.key?(cache_key)
      
      original_states = store_building_states(building_groups)
      
      begin
        # Apply construction times
        schedule.each do |type, times|
          instances = building_groups[type]
          times.each_with_index do |time, i|
            instances[i][0].set_attribute('dynamic_attributes', 'construction_init_time', time)
          end
        end

        # Calculate fitness
        cashflow_data = CashFlowCalculator.calculate_and_print_full_cashflow_table
        return -Float::INFINITY unless cashflow_data
        
        fitness = if settings['optimization_method'] == 'npv'
          monthly_cashflow = cashflow_data[:monthly_cashflow]
          annual_discount_rate = settings['discount_rate']
          monthly_discount_rate = (1 + annual_discount_rate)**(1.0/12) - 1
          CashFlowCalculator.npv(monthly_cashflow, monthly_discount_rate)
        else
          monthly_cashflow = CashFlowCalculator.calculate_monthly_cashflow(cashflow_data)
          key_indicators = CashFlowCalculator.calculate_key_indicators(monthly_cashflow)
          irr = key_indicators[:yearly_irr] || -100
          moic = key_indicators[:moic] || 0
          scaled_irr = irr/100
          scaled_moic = moic
          (settings['irr_weight'] * scaled_irr + settings['moic_weight'] * scaled_moic)
        end

        @evaluation_cache[cache_key] = fitness || -Float::INFINITY
        fitness || -Float::INFINITY
      ensure
        restore_building_states(original_states)
      end
end
  end
end
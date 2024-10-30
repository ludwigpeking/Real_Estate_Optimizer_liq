module Real_Estate_Optimizer
  module FinancialCalculations
    def self.calculate_irr(cashflows, max_iterations = 1000, precision = 1e-6)
      # puts "Starting IRR calculation with #{cashflows.length} cashflows"
      # puts "First few cashflows: #{cashflows.take(5)}"
      # puts "Last few cashflows: #{cashflows.last(5)}"

      return nil if cashflows.empty?
      unless irr_calculable?(cashflows)
        # puts "IRR is not calculable for these cashflows"
        return nil
      end

      # Use Newton-Raphson method with a good initial guess
      rate = initial_guess(cashflows)
      # puts "Initial guess: #{rate}"

      iteration = 0
      while iteration < max_iterations
        npv = npv(cashflows, rate)
        derivative = npv_derivative(cashflows, rate)

        break if derivative.abs < precision

        new_rate = rate - npv / derivative

        if (new_rate - rate).abs < precision
          # puts "IRR found: #{new_rate}"
          return new_rate
        end

        rate = new_rate
        iteration += 1

        # puts "Iteration #{iteration}: rate = #{rate}" if iteration % 100 == 0
      end

      # puts "IRR calculation did not converge after #{max_iterations} iterations"
      nil
    end

    def self.npv(cashflows, rate)
      cashflows.each_with_index.sum { |cf, t| cf / ((1 + rate) ** t) }
    end

    def self.npv_derivative(cashflows, rate)
      cashflows.each_with_index.sum { |cf, t| -t * cf / ((1 + rate) ** (t + 1)) }
    end

    def self.irr_calculable?(cashflows)
      pos = neg = false
      sum = 0
      cashflows.each do |cf|
        pos = true if cf > 0
        neg = true if cf < 0
        sum += cf
      end
      result = pos && neg && sum.abs > 1e-10
      # puts "IRR calculable: #{result} (pos: #{pos}, neg: #{neg}, sum: #{sum})"
      result
    end

    def self.initial_guess(cashflows)
      n = cashflows.length
      total_positive = cashflows.select { |cf| cf > 0 }.sum
      total_negative = cashflows.select { |cf| cf < 0 }.sum.abs
      (total_positive / total_negative) ** (1.0 / n) - 1
    end
  end
end
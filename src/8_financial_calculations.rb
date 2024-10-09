module Real_Estate_Optimizer
  module FinancialCalculations
    def self.calculate_irr(cashflows, max_iterations = 1000, precision = 1e-6)
      return nil if cashflows.empty?
      return nil unless irr_calculable?(cashflows)

      # Use bisection method to find a good initial bracket
      low_rate = -0.99999999
      high_rate = 1.0
      while npv(cashflows, low_rate) * npv(cashflows, high_rate) > 0
        high_rate *= 2
        break if high_rate > 1e6  # Avoid infinite loop
      end

      # Use a combination of bisection and secant methods
      rate = (low_rate + high_rate) / 2
      prev_rate = low_rate
      iteration = 0

      while iteration < max_iterations
        npv_rate = npv(cashflows, rate)
        
        if npv_rate.abs < precision
          return rate
        end

        if npv_rate * npv(cashflows, low_rate) < 0
          high_rate = rate
        else
          low_rate = rate
        end

        # Secant method
        npv_prev = npv(cashflows, prev_rate)
        if (npv_rate - npv_prev).abs > 1e-10
          new_rate = rate - npv_rate * (rate - prev_rate) / (npv_rate - npv_prev)
          if new_rate > low_rate && new_rate < high_rate
            prev_rate = rate
            rate = new_rate
            next
          end
        end

        # Bisection method
        prev_rate = rate
        rate = (low_rate + high_rate) / 2
        iteration += 1
      end

      nil  # Return nil if IRR did not converge
    end

    def self.npv(cashflows, rate)
      cashflows.each_with_index.sum do |cf, t|
        cf / ((1 + rate) ** t)
      end
    end

    def self.irr_calculable?(cashflows)
      pos = neg = false
      sum = 0
      cashflows.each do |cf|
        pos = true if cf > 0
        neg = true if cf < 0
        sum += cf
      end
      pos && neg && sum.abs > 1e-10
    end
  end
end
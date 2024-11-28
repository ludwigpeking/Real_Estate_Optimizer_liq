module Real_Estate_Optimizer
  module FinancialCalculations
    @last_successful_irr = nil
    @last_cashflow_pattern = nil

    def self.calculate_irr(cashflows, max_iterations = 1000, precision = 1e-6)
      return nil if cashflows.empty?

      # Clean up cashflows - remove trailing zeros
      while cashflows.last == 0 && cashflows.length > 1
        cashflows.pop
      end

      # Check if calculation is possible
      return nil unless irr_calculable?(cashflows)

      # Check if current cashflow pattern is similar to last one
      current_pattern = cashflows[0..5]  # Use first 6 months as pattern
      if @last_successful_irr && similar_cashflow_pattern?(current_pattern, @last_cashflow_pattern)
        rate1 = @last_successful_irr
        rate2 = @last_successful_irr * 1.1  # Slightly higher for second guess
      else
        rate1 = 0.0
        rate2 = initial_guess(cashflows)
      end
      
      max_iterations.times do
        npv1 = npv(cashflows, rate1)
        npv2 = npv(cashflows, rate2)
        
        # Break if we've found a close enough answer
        if (rate2 - rate1).abs < precision
          # Cache successful result
          @last_successful_irr = rate2
          @last_cashflow_pattern = current_pattern
          return rate2
        end
        
        # Calculate new rate using modified secant method
        rate_new = rate2 - npv2 * (rate2 - rate1) / (npv2 - npv1)
        
        # Guard against invalid rates
        if rate_new.nan? || rate_new.infinite? || rate_new < -1.0
          # Try binary search between current points
          rate_new = (rate1 + rate2) / 2.0
        end
        
        # Update for next iteration
        rate1 = rate2
        rate2 = rate_new
        
        # Add bounds checking
        if rate2 > 1000.0  # More than 100,000% return
          return 10.0  # Cap at 1000% return
        elsif rate2 < -0.99  # Preventing division by zero issues
          rate2 = -0.99
        end
      end
      
      # If we didn't converge, but have a reasonable rate, return it
      if rate2.between?(-0.99, 10.0)
        @last_successful_irr = rate2
        @last_cashflow_pattern = current_pattern
        return rate2
      end
      nil
    end

    def self.similar_cashflow_pattern?(pattern1, pattern2)
      return false if pattern1.nil? || pattern2.nil?
      return false if pattern1.length != pattern2.length

      # Check if the signs and rough magnitudes are similar
      pattern1.zip(pattern2).all? do |cf1, cf2|
        next true if cf1.zero? && cf2.zero?
        next false if cf1.zero? || cf2.zero?
        
        # Same sign and within 20% of each other
        cf1 * cf2 > 0 && (cf1 - cf2).abs / [cf1.abs, cf2.abs].max < 0.2
      end
    end

    def self.npv(cashflows, rate)
      # More numerically stable NPV calculation
      cashflows.each_with_index.sum do |cf, t|
        if rate == -1 && t > 0
          0.0  # Avoid division by zero
        else
          cf / ((1 + rate) ** t)
        end
      end
    end

    def self.irr_calculable?(cashflows)
      # Must have both positive and negative cash flows
      has_positive = false
      has_negative = false
      sum = 0.0
      
      cashflows.each do |cf|
        next if cf.zero?  # Skip zero cash flows
        has_positive = true if cf > 0
        has_negative = true if cf < 0
        sum += cf
      end
      
      # Must have meaningful cash flows and not all in same direction
      return false if sum.abs < 1e-6 || !has_positive || !has_negative
      
      # Check timing pattern
      # Usually investments (negative) come before returns (positive)
      first_nonzero = cashflows.find { |cf| cf != 0 }
      return false if first_nonzero.nil? || first_nonzero > 0  # Should start with investment
      
      true
    end

    def self.initial_guess(cashflows)
      # Smarter initial guess based on cash flow patterns
      positive_sum = cashflows.select { |cf| cf > 0 }.sum
      negative_sum = cashflows.select { |cf| cf < 0 }.sum.abs
      
      # Calculate rough payback period
      investment_period = cashflows.index { |cf| cf > 0 } || 1
      
      if positive_sum > 0 && negative_sum > 0
        # Basic return ratio adjusted by time
        return_ratio = (positive_sum / negative_sum) ** (1.0 / investment_period) - 1
        [[return_ratio, -0.9].max, 9.0].min  # Keep initial guess reasonable
      else
        0.1  # Default conservative guess
      end
    end

    def self.monthly_to_annual_rate(monthly_rate)
      return nil if monthly_rate.nil?
      return nil if monthly_rate < -1.0 || monthly_rate.infinite? || monthly_rate.nan?
      
      begin
        annual_rate = ((1 + monthly_rate) ** 12) - 1
        annual_rate * 100  # Convert to percentage
      rescue
        nil
      end
    end
  end
end
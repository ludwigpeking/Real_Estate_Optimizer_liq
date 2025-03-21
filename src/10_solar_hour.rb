require 'date'

module Real_Estate_Optimizer
  module SolarAnalyzer
    # Default settings
    @latitude = 40.0  # Default latitude (40° North)
    @calculation_date = Date.new(Time.now.year, 1, 20)  # January 20th
    @start_hour = 8.0  # 8:00 AM
    @end_hour = 16.0   # 4:00 PM
    @step_minutes = 5  # Check every 5 minutes
    def self.calculate_sun_vector(hour)
      lat_rad = @latitude * Math::PI / 180
      day_of_year = @calculation_date.yday
      
      # Calculate declination angle
      declination = 23.45 * Math.sin(Math::PI / 180 * 360 * (284 + day_of_year) / 365.0)
      declination_rad = declination * Math::PI / 180
      
      # Calculate hour angle
      hour_angle = (hour - 12) * 15
      hour_angle_rad = hour_angle * Math::PI / 180
      
      # Calculate solar altitude
      sin_altitude = Math.sin(lat_rad) * Math.sin(declination_rad) + 
                      Math.cos(lat_rad) * Math.cos(declination_rad) * Math.cos(hour_angle_rad)
      altitude = Math.asin(sin_altitude)
      
      # Calculate solar azimuth
      cos_azimuth = (Math.sin(declination_rad) - Math.sin(altitude) * Math.sin(lat_rad)) / 
                    (Math.cos(altitude) * Math.cos(lat_rad))
      azimuth = Math.acos([[-1, cos_azimuth].max, 1].min)
      azimuth = 2 * Math::PI - azimuth if hour > 12
      
      # Convert to Cartesian coordinates (SketchUp: Y is north, X is east, Z is up)
      # Fix: Removed negative sign for y component
      x = Math.cos(altitude) * Math.sin(azimuth)
      y = Math.cos(altitude) * Math.cos(azimuth)  # Removed the negative for Y axis
      z = Math.sin(altitude)
      
      # Create vector
      Geom::Vector3d.new(x, y, z)
    end

    def self.show_settings_dialog
      puts "SolarAnalyzer.show_settings_dialog called"
      
      prompts = ["Latitude (degrees North):", "Date (MM/DD):", "Start Time (hour):", "End Time (hour):"]
      defaults = [
        @latitude.to_s, 
        "#{@calculation_date.month}/#{@calculation_date.day}", 
        @start_hour.to_s, 
        @end_hour.to_s
      ]
      
      results = UI.inputbox(prompts, defaults, "Solar Analysis Settings")
      return unless results
      
      @latitude = results[0].to_f
      date_parts = results[1].split('/')
      begin
        @calculation_date = Date.new(Time.now.year, date_parts[0].to_i, date_parts[1].to_i)
      rescue => e
        UI.messagebox("Invalid date format. Using default date.")
        @calculation_date = Date.new(Time.now.year, 1, 20)
      end
      
      @start_hour = results[2].to_f
      @end_hour = results[3].to_f
      
      UI.messagebox("Solar analysis settings updated!")
    end
    
    def self.activate_tool
      puts "SolarAnalyzer.activate_tool called"
      Sketchup.active_model.select_tool(TestSolarTool.new)
    end
    
    class TestSolarTool
      def initialize
        @ip = Sketchup::InputPoint.new
      end
      
      def activate
        puts "TestSolarTool activated"
        Sketchup.status_text = "Click on a point to test solar analysis"
      end
      
      def deactivate(view)
        puts "TestSolarTool deactivated"
      end
      
      def onMouseMove(flags, x, y, view)
        @ip.pick(view, x, y)
        view.invalidate
      end
      
      def draw(view)
        @ip.draw(view)
      end
      
      def onLButtonDown(flags, x, y, view)
        if @ip.valid?
          point = @ip.position
          calculate_solar_hours(point)
        end
      end
      
      def calculate_solar_hours(point)
        model = Sketchup.active_model
        total_minutes = 0
        step = SolarAnalyzer.instance_variable_get(:@step_minutes) / 60.0
        start_hour = SolarAnalyzer.instance_variable_get(:@start_hour)
        end_hour = SolarAnalyzer.instance_variable_get(:@end_hour)
        
        # Create group for visualization
        group = model.active_entities.add_group
        
        (start_hour..end_hour).step(step) do |hour|
          sun_vector = SolarAnalyzer.calculate_sun_vector(hour)
          
          # Skip if sun is below horizon
          next if sun_vector.z <= 0
          
          # Set up ray test
          ray = [point, sun_vector]
          hit_item = model.raytest(ray)
          
          if hit_item.nil?
            # Sun is visible
            total_minutes += SolarAnalyzer.instance_variable_get(:@step_minutes)
            
            # Draw visible ray (green)
            end_point = point.offset(sun_vector, 10.m)
            group.entities.add_line(point, end_point).material = "green"
          else
            # Check if the hit is too close (less than 1 meter)
            hit_point = hit_item[0]
            distance = point.distance(hit_point)
            
            if distance < 1.m
              # Still count as visible if the object is too close
              total_minutes += SolarAnalyzer.instance_variable_get(:@step_minutes)
              # Draw as green (visible)
              end_point = point.offset(sun_vector, 10.m)
              group.entities.add_line(point, end_point).material = "green"
            else
              # Draw blocked ray (red)
              group.entities.add_line(point, hit_point).material = "red"
            end
          end
        end
        
        # Calculate hours and minutes
        hours = (total_minutes / 60).to_i
        minutes = (total_minutes % 60).to_i
        
        # Display result
        result = "Solar exposure: #{hours}h #{minutes}min"
        UI.messagebox(result)
        
        # Add text label
        text = group.entities.add_text(result, point)
        text.text_color = "black"
      end
    end
  end
end
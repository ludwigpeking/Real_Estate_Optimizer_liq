module SolarHourCalculator
# Global variables
@latitude = 38.0  # Default latitude (degrees)
@calculation_date = Date.new(Time.now.year, 1, 20)  # January 20th of the current year

def self.calculate_solar_hours
  model = Sketchup.active_model
  entities = model.active_entities
  puts "Total entities: #{entities.length}"

  # Create a new group and layer for subdivided faces
  faces_group = model.active_entities.add_group
  faces_layer = model.layers.add "Subdivided Faces"
  faces_group.layer = faces_layer

  # Create a new group and layer for debug lines
  debug_group = model.active_entities.add_group
  debug_layer = model.layers.add "Debug Lines"
  debug_group.layer = debug_layer

  south_facing_faces = find_south_facing_faces(entities)
  puts "South facing faces found: #{south_facing_faces.length}"

  south_facing_faces.each do |face|
    subdivided_faces = subdivide_face(face, 3.m, 3.m)  # Subdivide by 3 meters
    
    subdivided_faces.each do |sub_face|
      center = sub_face.bounds.center
      solar_hours = calculate_point_solar_hours(center, sub_face, entities, debug_group.entities)
      color = map_solar_hours_to_color(solar_hours)
      # puts "Solar hours: #{solar_hours.round(2)}, Color: R#{color.red}, G#{color.green}, B#{color.blue}"
      
      # Create the subdivided face in the faces group
      new_face = faces_group.entities.add_face(sub_face.vertices)
      new_face.material = color
    end
  end

  # Zoom to show both groups
  model.active_view.zoom(faces_group)
  model.active_view.zoom(debug_group)
end

  def self.find_south_facing_faces(entities)
    entities.grep(Sketchup::Face).select do |face|
      face.normal.y < 0
    end
  end

  def self.subdivide_face(face, u_size, v_size)
    subdivided_faces = []
    
    # Get two edges to use as our UV axes
    edge1 = face.edges[0]
    edge2 = face.edges.find { |e| e.common_face(edge1) && e != edge1 }
    
    # Create UV axes using the edge's start and end points
    u_vector = edge1.end.position - edge1.start.position
    v_vector = edge2.end.position - edge2.start.position
    
    # Normalize the vectors to avoid scaling issues
    u_vector.normalize!
    v_vector.normalize!
    
    # Calculate the length of the edges
    u_length = edge1.length
    v_length = edge2.length
    
    # Calculate the number of subdivisions based on the desired grid size (3m x 3m)
    u_subdivisions = (u_length / u_size).floor
    v_subdivisions = (v_length / v_size).floor
    
    # Get the origin point
    origin = face.bounds.corner(0)
    
    # Create subdivided faces
    (0...v_subdivisions).each do |row|
      (0...u_subdivisions).each do |col|
        # Calculate corner points of the subdivided face using the offset method
        p1 = origin.offset(u_vector, col * u_size).offset(v_vector, row * v_size)
        p2 = p1.offset(u_vector, u_size)
        p3 = p2.offset(v_vector, v_size)
        p4 = p1.offset(v_vector, v_size)
        
        points = [p1, p2, p3, p4]
        

        begin
          # Create the new face
          new_face = face.parent.entities.add_face(points)
          subdivided_faces << new_face
        rescue ArgumentError => e
          puts "  Failed to create face: #{e.message}"
        end
      end
    end
    
    subdivided_faces
  end
  
  def self.calculate_point_solar_hours(point, face, original_entities, debug_entities)
    total_hours = 0
    debug_info = []
    model = Sketchup.active_model
  
    # Start from 08:02:30 and end at 15:57:30 to center the 5-minute intervals
    (8.0416666..15.9583333).step(1.0/12) do |hour|
      sun_vector = calculate_sun_vector(hour)
  
      # Create the correct ray array
      ray = [point, sun_vector]
  
      # Perform the raytest
      hit_item = model.raytest(ray)
  
      if hit_item
        hit_point, hit_face_path = hit_item
        hit_face = hit_face_path.last
  
        # Check if the hit face is in the original entities and not the face we're checking
        if original_entities.include?(hit_face) && hit_face != face && (hit_point - point).dot(sun_vector) > 0
          # The ray hit something other than the original face and in front of the point
          debug_info << "Hour #{hour.round(2)}: Blocked by #{hit_face}"
  
          # Draw a red line to show the blocked direction
          # debug_entities.add_line(point, hit_point).material = "red"
        else
          # The ray didn't hit anything or hit the original face or a face behind
          total_hours += 1.0/12
          debug_info << "Hour #{hour.round(2)}: Clear"
  
          # Draw a green line to show the clear direction
          end_point = point.offset(sun_vector, 10.m)  # Extend the line for 10 meters
          # debug_entities.add_line(point, end_point).material = "green"
        end
      else
        # If hit_item is nil, it means the ray didn't hit anything
        total_hours += 1.0/12
        debug_info << "Hour #{hour.round(2)}: Clear (no hit)"
  
        # Draw a blue line to show the clear direction with no hit
        end_point = point.offset(sun_vector, 10.m)  # Extend the line for 10 meters
        # debug_entities.add_line(point, end_point).material = "blue"
      end
    end
  
    # puts "Total solar hours: #{total_hours.round(2)}"
    
    total_hours
  end
  

  def self.calculate_sun_vector(hour)
    # Convert latitude to radians
    lat_rad = @latitude * Math::PI / 180
  
    # Calculate day of year
    day_of_year = @calculation_date.yday
  
    # Calculate declination angle
    declination = 23.45 * Math::sin(Math::PI / 180 * 360 * (284 + day_of_year) / 365.0)
    declination_rad = declination * Math::PI / 180
  
    # Calculate hour angle
    hour_angle = (hour - 12) * 15
    hour_angle_rad = hour_angle * Math::PI / 180
  
    # Calculate solar altitude
    sin_altitude = Math::sin(lat_rad) * Math::sin(declination_rad) + 
                    Math::cos(lat_rad) * Math::cos(declination_rad) * Math::cos(hour_angle_rad)
    altitude = Math::asin(sin_altitude)
  
    # Calculate solar azimuth
    cos_azimuth = (Math::sin(declination_rad) - Math::sin(altitude) * Math::sin(lat_rad)) / 
                  (Math::cos(altitude) * Math::cos(lat_rad))
    azimuth = Math::acos(cos_azimuth)
    azimuth = 2 * Math::PI - azimuth if hour > 12
  
    # Convert to Cartesian coordinates
    # Note: In SketchUp, Y is north, X is east, and Z is up
    x = Math::cos(altitude) * Math::sin(azimuth)
    y = Math::cos(altitude) * Math::cos(azimuth)  # Negative because south is negative Y in SketchUp
    z = Math::sin(altitude)
  
    # Create and normalize the vector
    vector = Geom::Vector3d.new(x, y, z)
    vector.normalize!
    vector
  end

  def self.map_solar_hours_to_color(hours)
    case hours
    when 0...1
      Sketchup::Color.new(165, 0, 0)  # Black
    when 1...2
      Sketchup::Color.new(255, 0, 0)  # Red
    when 2...3
      Sketchup::Color.new(255, 165, 0)  # Orange
    when 3...4
      Sketchup::Color.new(255, 255, 0)  # Yellow
    when 4...5
      Sketchup::Color.new(165, 255, 0)  # Green
    when 5...6
      Sketchup::Color.new(0, 255, 0)  # Cyan
    when 6...7
      Sketchup::Color.new(0, 255, 165)  # Blue
    else
      Sketchup::Color.new(0, 0, 255)  # purple (7 and above)
    end
  end

  def self.set_latitude(lat)
    @latitude = lat
  end

  def self.set_calculation_date(date)
    @calculation_date = date
  end

  # Separate method for creating menus
  def self.create_menus
    menu = UI.menu('Plugins')
    menu.add_item('Calculate Solar Hours') {
      self.calculate_solar_hours
    }
    menu.add_item('Set Latitude') {
      prompts = ["Latitude (degrees):"]
      defaults = [@latitude.to_s]
      input = UI.inputbox(prompts, defaults, "Set Latitude")
      self.set_latitude(input[0].to_f) if input
    }
    menu.add_item('Set Calculation Date') {
      prompts = ["Date (YYYY-MM-DD):"]
      defaults = [@calculation_date.strftime("%Y-%m-%d")]
      input = UI.inputbox(prompts, defaults, "Set Calculation Date")
      self.set_calculation_date(Date.parse(input[0])) if input
    }
  end
end

# Load the plugin
SolarHourCalculator.calculate_solar_hours
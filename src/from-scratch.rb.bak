module ExampleBuildingCreator
  # Define the ApartmentType class
  class ApartmentType
    attr_accessor :type, :area, :comment_tag, :unit_cost_no_overhead, :net_area_ratio, :width, :depth, :level_height, :scenarios, :name_tag, :color

    def initialize(type, area, comment_tag, unit_cost_no_overhead, net_area_ratio, width, depth, level_height, scenarios)
      @type = type
      @area = area
      @comment_tag = comment_tag
      @unit_cost_no_overhead = unit_cost_no_overhead
      @net_area_ratio = net_area_ratio
      @width = width
      @depth = depth
      @level_height = level_height
      @scenarios = scenarios
      @name_tag = "#{type}#{area}#{comment_tag}"
      @color = "hsl(#{(area - 50) * 2}, 100%, 50%)" # Note: SketchUp does not use HSL directly, needs conversion
    end
  end

  # Define the BuildingType class
  class BuildingType
    attr_accessor :levels, :construction_schedule, :days_from_commence_to_sales_permit, :fund_supervision_percentage, :fund_supervision_schedule, :construction_payment_schedule

    def initialize(levels, construction_schedule, days_from_commence_to_sales_permit, fund_supervision_percentage, fund_supervision_schedule, construction_payment_schedule)
      @levels = levels
      @construction_schedule = construction_schedule
      @days_from_commence_to_sales_permit = days_from_commence_to_sales_permit
      @fund_supervision_percentage = fund_supervision_percentage
      @fund_supervision_schedule = fund_supervision_schedule
      @construction_payment_schedule = construction_payment_schedule
      
    end
  end

  # Create instances of apartment types
  def self.setup_types
    type_select = ["大高层", "小高层", "准洋房", "洋房", "叠拼", "别墅", "商业", "办公", "酒店", "公寓", "其他"]

    apartment_type1 = ApartmentType.new(
      type_select[1], 110, "三室两卫", 4700, 0.765, 10.2.m, 10.8.m, 3.m,
      [{ unit_price: 11300, monthly_sales: 15 }, { unit_price: 11900, monthly_sales: 10 }, { unit_price: 12500, monthly_sales: 7 }]
    )
 apartment_type2 = ApartmentType.new(
      type_select[1], 130, "三室两卫", 4700, 0.765, 11.2.m, 10.8.m, 3.m,
      [{ unit_price: 11300, monthly_sales: 12 }, { unit_price: 11900, monthly_sales: 9 }, { unit_price: 12500, monthly_sales: 6 }]
    )

    apartment_type3 = ApartmentType.new(
      type_select[1], 90, "首层变异二室二卫", 4700, 0.765, 10.2.m, 10.8.m, 3.m,
      [{ unit_price: 10500, monthly_sales: 2 }, { unit_price: 11000, monthly_sales: 0.8 }, { unit_price: 11500, monthly_sales: 0.2 }]
    )

    levels = [
      { level: [1], apartments: [{ type: apartment_type3, offset_x: 0, offset_y: 0 }, { type: apartment_type3, offset_x: 10.2.m, offset_y: 0 }], level_height: apartment_type2.level_height },
      { level: [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18], apartments: [{ type: apartment_type1, offset_x: 0, offset_y: 0 }, { type: apartment_type2, offset_x: 10.2.m, offset_y: 0 }], level_height: apartment_type1.level_height }
    ]

    building_type = BuildingType.new(levels, "Standard", 30, 20.0, "Monthly", "Quarterly")

    # Pass to building creation method
    create_building(building_type)
  end

   def self.create_building(building_type)
    model = Sketchup.active_model
    definitions = model.definitions
    entities = model.active_entities

    # Start the SketchUp operation
    model.start_operation('Create Building', true)

    # Calculate the total number of levels
    total_levels = building_type.levels.inject(0) { |sum, level| sum + level[:level].length }

    # Identify the most prevalent level type
    prevalent_level = building_type.levels.max_by { |level| level[:level].length }
    prevalent_apartment_areas = prevalent_level[:apartments].map { |apt| apt[:type].area }.sort
    prevalent_areas_string = prevalent_apartment_areas.join('+')

    building_name = "#{total_levels}层#{prevalent_areas_string}"

    # Check if a component definition already exists
    building_def = definitions[building_name] || definitions.add(building_name)

    # Iterate over each level defined in the building type
    z_offset = 0.0
    building_type.levels.each do |level_info|
      level_info[:level].each do |level_number|
        level_info[:apartments].each do |apartment_info|
          apartment_type = apartment_info[:type]
          x_offset = apartment_info[:offset_x]
          y_offset = apartment_info[:offset_y]

          add_apartment(building_def, x_offset, y_offset, z_offset, apartment_type)
        end
        z_offset += level_info[:level_height]
      end
    end

    # Add the building instance to the model
    building_instance = entities.add_instance(building_def, ORIGIN)

    model.commit_operation
  end

def self.add_apartment(parent_definition, x_offset, y_offset, z_offset, apartment_type)
    # Check if material already exists; if not, create it
    material = Sketchup.active_model.materials[apartment_type.name_tag]
    unless material
      material = Sketchup.active_model.materials.add(apartment_type.name_tag)
      h, s, l = (apartment_type.area - 50) * 2, 100, 50
      r, g, b = hsl_to_rgb(h, s, l)
      material.color = Sketchup::Color.new(r.round, g.round, b.round)
    end

    # Check if a component definition already exists
    apartment_def = Sketchup.active_model.definitions[apartment_type.name_tag]
    unless apartment_def
      apartment_def = Sketchup.active_model.definitions.add(apartment_type.name_tag)
      pts = [
        [0, 0, 0],
        [apartment_type.width, 0, 0],
        [apartment_type.width, apartment_type.depth, 0],
        [0, apartment_type.depth, 0]
      ]
      face = apartment_def.entities.add_face(pts)
      face.reverse! if face.normal.z < 0
      face.pushpull(apartment_type.level_height)
      apartment_def.entities.each { |entity| entity.material = material if entity.is_a?(Sketchup::Face) }
    end

    # Add the apartment instance to the parent definition at the specified offsets
    transform = Geom::Transformation.new([x_offset, y_offset, z_offset])
    parent_definition.entities.add_instance(apartment_def, transform)
  end

  def self.hsl_to_rgb(h, s, l)
    h /= 360.0
    s /= 100.0
    l /= 100.0
    r, g, b = l, l, l
    v = (l <= 0.5) ? (l * (1.0 + s)) : (l + s - l * s)
    if v > 0
      m = l + l - v
      sv = (v - m) / v
      h *= 6.0
      sextant = h.floor
      fract = h - sextant
      vsf = v * sv * fract
      mid1 = m + vsf
      mid2 = v - vsf
      r, g, b = v, mid1, m if sextant == 0
      r, g, b = mid2, v, m if sextant == 1
      r, g, b = m, v, mid1 if sextant == 2
      r, g, b = m, mid2, v if sextant == 3
      r, g, b = mid1, m, v if sextant == 4
      r, g, b = v, m, mid2 if sextant == 5
    end
    [(r * 255).round, (g * 255).round, (b * 255).round]
  end

  # To run the function from the Ruby Console
  if defined?(Sketchup)
    setup_types
  end
end

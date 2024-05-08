# File: apartment_type.rb

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
      @color = "hsl(#{(area - 50) * 2}, 100%, 50%)"  # Note: SketchUp does not use HSL directly, needs conversion
    end
  
    def to_hash
      {
        "type" => @type,
        "area" => @area,
        "comment_tag" => @comment_tag,
        "unit_cost_no_overhead" => @unit_cost_no_overhead,
        "net_area_ratio" => @net_area_ratio,
        "width" => @width,
        "depth" => @depth,
        "level_height" => @level_height,
        "scenarios" => @scenarios.map(&:to_hash),
        "name_tag" => @name_tag,
        "color" => @color
      }
    end
  
    def self.from_hash(hash)
      new(hash["type"], hash["area"], hash["comment_tag"], hash["unit_cost_no_overhead"], hash["net_area_ratio"], hash["width"], hash["depth"], hash["level_height"], hash["scenarios"].map { |s| OpenStruct.new(s) })
    end
  end
  
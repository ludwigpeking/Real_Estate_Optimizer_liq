require 'sketchup.rb'
require 'extensions.rb'

module Urban_Banal
  module Real_Estate_Optimizer
    unless file_loaded?(__FILE__)
      ex = SketchupExtension.new("Real Estate Optimizer by liq", "RealEstateOptimizer/src/main.rb")
      ex.description = "This is a detailed description of the Plugin."
      ex.version = "1.0.0"
      ex.creator = "Richard Qian Li"
      Sketchup.register_extension(ex, true)
      file_loaded(__FILE__)
    end
  end
end

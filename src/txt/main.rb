# main.rb

require_relative '0_toolbar'
require_relative '4_apartment_manager'
require_relative '11_optimization_algorithm'

module Real_Estate_Optimizer
  module_function

  def activate
    puts "Activating Real Estate Optimizer plugin..."
    # Remove existing toolbar if it exists
    toolbar = UI::Toolbar.new "Real_Estate_Optimizer"
    toolbar.remove if toolbar.respond_to?(:remove)

    ApartmentManager.ensure_layers_exist
    Toolbar.create_toolbar
    puts "Activation complete."
  end

  unless file_loaded?(__FILE__)
    activate
    file_loaded(__FILE__)
  end
end
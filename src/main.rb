require_relative '0_toolbar'


module Real_Estate_Optimizer
  def self.activate
    # UI.messagebox("Activating Real_Estate_Optimizer Plugin")
    Toolbar.create_toolbar
  end

  # Run the activation method to initialize everything
  unless file_loaded?(__FILE__)
    activate
    file_loaded(__FILE__)
  end
end


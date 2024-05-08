require_relative 'toolbar'

module Urban_Banal
  module Real_Estate_Optimizer
    def self.activate
      Toolbar.create_toolbar
    end

    # Run the activation method to initialize everything
    activate unless file_loaded?(__FILE__)
    file_loaded(__FILE__)
  end
end


module Real_Estate_Optimizer
  module OptimizationPanel
    def self.show_dialog
      dialog = UI::HtmlDialog.new(
        {
          :dialog_title => "Optimization Settings",
          :preferences_key => "com.example.optimization_settings",
          :scrollable => true,
          :resizable => true,
          :width => 400,
          :height => 600
        }
      )

      html_content = <<-HTML
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="UTF-8">
          <title>Optimization Settings</title>
          <style>
            body {
              font-family: Arial, sans-serif;
              padding: 20px;
            }
            .property-line-item {
              display: flex;
              align-items: center;
              margin: 5px 0;
              padding: 5px;
              background-color: #f5f5f5;
              border: 1px solid #ddd;
            }
            .property-line-name {
              flex-grow: 1;
              margin: 0 10px;
            }
            .move-button {
              padding: 2px 8px;
              margin: 0 2px;
              cursor: pointer;
              background: #fff;
              border: 1px solid #ccc;
              border-radius: 3px;
            }
            .move-button:disabled {
              opacity: 0.5;
              cursor: not-allowed;
            }
            #property_line_list {
              list-style: none;
              padding: 0;
              margin: 0;
            }
            .main-button {
              padding: 8px 16px;
              margin: 10px 5px;
              background: #4CAF50;
              color: white;
              border: none;
              border-radius: 4px;
              cursor: pointer;
            }
            .main-button:hover {
              background: #45a049;
            }
          </style>
        </head>
        <link rel="stylesheet" type="text/css" href="file:///#{File.join(__dir__, 'style.css')}">
        <body>

    
          <div>
            <label for="max_timeline">最晚开工月份 Max Timeline (months):</label>
            <input type="number" id="max_timeline" min="12" max="72" value="24">
          </div>
          <div>
            <h3>优化方式 Optimization Method</h3>
            <div class="radio-group">
              <label>
                <input type="radio" name="optimization_method" value="npv" checked>
                净现值法 Net Present Value (NPV)
              </label>
              <label>
                <input type="radio" name="optimization_method" value="irr_moic">
                内部收益率与总投资汇报率组合 IRR + MOIC
              </label>
            </div>
            <div id="discount_rate_section">
              <label for="discount_rate">贴现率 Discount Rate (%):</label>
              <input type="number" id="discount_rate" min="0" max="100" step="0.01" value="9">
            </div>
            <div id="irr_moic_weights" style="display: none;">
              <h3>优化权重 Optimization Weights</h3>
              <div>
                <label for="irr_weight">内部收益率权重 IRR Weight:</label>
                <input type="range" id="irr_weight" min="0" max="100" value="50" oninput="updateWeightValue('irr_weight')">
                <span id="irr_weight_value">50</span>
              </div>
              <div>
                <label for="moic_weight">总投资汇报率权重 MOIC Weight:</label>
                <input type="range" id="moic_weight" min="0" max="100" value="50" oninput="updateWeightValue('moic_weight')">
                <span id="moic_weight_value">50</span>
              </div>
            </div>
          </div>
         
          <div class="construction-priority">
            <h3>开工优先方向</h3>
            
            <!-- North-South slider group -->
            <div class="slider-group">
              <div class="slider-labels">
                <span>北侧</span>
                <span id="north_south_weight_value">0</span>
                <span>南侧</span>
              </div>
              <div class="slider-container">
                <input type="range" 
                      id="north_south_weight" 
                      min="-100" 
                      max="100" 
                      value="0" 
                      oninput="updateWeightValue('north_south_weight')">
              </div>
            </div>

            <!-- East-West slider group -->
            <div class="slider-group">
              <div class="slider-labels">
                <span>西侧</span>
                <span id="east_west_weight_value">0</span>
                <span>东侧</span>
              </div>
              <div class="slider-container">
                <input type="range" 
                      id="east_west_weight" 
                      min="-100" 
                      max="100" 
                      value="0" 
                      oninput="updateWeightValue('east_west_weight')">
              </div>
            </div>
          </div>
          <div>
          <label for="use_property_line_priority">
            <input type="checkbox" id="use_property_line_priority" checked>
            启用地块优先级 Enable Property Line Priority
          </label>
        </div>
          <h3>地块开工顺序 Property Line Priority</h3>
          <ul id="property_line_list">
            <!-- Property lines will be populated here -->
          </ul>
          <button onclick="saveSettings()" class="main-button">Save Settings</button>
          <button onclick="launchOptimization()" class="main-button">Launch Optimization</button>
          <script>
            let propertyLines = [];
            

            function moveItem(index, direction) {
              if ((direction === -1 && index === 0) || 
                  (direction === 1 && index === propertyLines.length - 1)) {
                return;
              }

              const newIndex = index + direction;
              const temp = propertyLines[index];
              propertyLines[index] = propertyLines[newIndex];
              propertyLines[newIndex] = temp;

              populatePropertyLines();
            }
            function toggleOptimizationMethod() {
              const method = document.querySelector('input[name="optimization_method"]:checked').value;
              const irrMoicWeights = document.getElementById('irr_moic_weights');
              irrMoicWeights.style.display = method === 'irr_moic' ? 'block' : 'none';
            }

            function loadSavedSettings(settings) {
              if (!settings) return;
              
              // Define default values in decimal form
              const defaultValues = {
                'irr_weight': 0.5,
                'moic_weight': 0.5,
                'north_south_weight': 0,
                'east_west_weight': 0,
                'max_timeline': 24
              };
              
              // Update input values with saved settings or defaults
              Object.entries(defaultValues).forEach(([id, defaultValue]) => {
                const element = document.getElementById(id);
                if (element) {
                  if (id === 'max_timeline') {
                    // Handle max_timeline normally
                    element.value = settings[id] !== undefined ? Math.round(settings[id]) : defaultValue;
                  } else {
                    // Convert decimal weights to percentages for display and round to nearest integer
                    const value = settings[id] !== undefined ? Math.round(settings[id] * 100) : Math.round(defaultValue * 100);
                    element.value = value;
                    const valueDisplay = document.getElementById(id + '_value');
                    if (valueDisplay) {
                      valueDisplay.textContent = value + '%';
                    }
                  }
                }
              });
            
              // Update property line order if available
              if (settings.property_line_order && settings.property_line_order.length > 0) {
                const orderedLines = [];
                settings.property_line_order.forEach(name => {
                  const line = propertyLines.find(pl => pl.name === name);
                  if (line) orderedLines.push(line);
                });
                
                propertyLines.forEach(line => {
                  if (!orderedLines.find(ol => ol.name === line.name)) {
                    orderedLines.push(line);
                  }
                });
                
                propertyLines = orderedLines;
                populatePropertyLines();
              }
            }

            function populatePropertyLines() {
              const list = document.getElementById('property_line_list');
              list.innerHTML = '';
              propertyLines.forEach((line, index) => {
                const li = document.createElement('li');
                li.className = 'property-line-item';
                li.setAttribute('data-id', line.name);
                
                // Create up button
                const upButton = document.createElement('button');
                upButton.textContent = '↑';
                upButton.className = 'move-button';
                upButton.disabled = index === 0;
                upButton.onclick = () => moveItem(index, -1);
                
                // Create down button
                const downButton = document.createElement('button');
                downButton.textContent = '↓';
                downButton.className = 'move-button';
                downButton.disabled = index === propertyLines.length - 1;
                downButton.onclick = () => moveItem(index, 1);
                
                // Create name span
                const nameSpan = document.createElement('span');
                nameSpan.className = 'property-line-name';
                nameSpan.textContent = line.name;
                
                // Add elements to li
                li.appendChild(upButton);
                li.appendChild(downButton);
                li.appendChild(nameSpan);
                
                list.appendChild(li);
              });
            }

            function updateWeightValue(sliderId) {
              const slider = document.getElementById(sliderId);
              const valueDisplay = document.getElementById(sliderId + '_value');
              valueDisplay.textContent = slider.value;
            }
            function getPropertyLineOrder() {
              return propertyLines.map(line => line.name);
            }

            function launchOptimization() {
              const settings = getOptimizationSettings();
              sketchup.launch_optimization(JSON.stringify(settings));
            }

            function saveSettings() {
              const settings = getOptimizationSettings();
              window.location = 'skp:save_optimization_settings@' + JSON.stringify(settings);
            }

            // Call this function when the page loads to populate property lines
            function loadPropertyLines() {
              sketchup.get_property_lines();
            }
            function applyDefaultValues() {
              const defaultValues = {
                'irr_weight': 50,
                'moic_weight': 50,
                'north_south_weight': 0,
                'east_west_weight': 0,
                'max_timeline': 24
              };

              Object.entries(defaultValues).forEach(([id, value]) => {
                const element = document.getElementById(id);
                if (element) {
                  element.value = value;
                  const valueDisplay = document.getElementById(id + '_value');
                  if (valueDisplay) {
                    valueDisplay.textContent = value;
                  }
                }
              });
            }

            function updateDiscountRate(value) {
              window.location = 'skp:update_discount_rate@' + value;
            }            

            window.onload = function() {
              applyDefaultValues();  // Apply defaults first
              loadPropertyLines();   // Then load any saved settings
            };

            document.querySelectorAll('input[name="optimization_method"]').forEach(radio => {
              radio.addEventListener('change', toggleOptimizationMethod);
            });

            function getOptimizationSettings() {
              const method = document.querySelector('input[name="optimization_method"]:checked').value;
              const settings = {
                optimization_method: method,
                discount_rate: parseFloat(document.getElementById('discount_rate').value) / 100,
                max_timeline: parseInt(document.getElementById('max_timeline').value),
                property_line_order: getPropertyLineOrder(),
                use_property_line_priority: document.getElementById('use_property_line_priority').checked,
                north_south_weight: parseFloat(document.getElementById('north_south_weight').value) / 100,
                east_west_weight: parseFloat(document.getElementById('east_west_weight').value) / 100
              };
            
              if (method === 'irr_moic') {
                settings.irr_weight = parseFloat(document.getElementById('irr_weight').value) / 100;
                settings.moic_weight = parseFloat(document.getElementById('moic_weight').value) / 100;
              }
            
              return settings;
            }

          </script>
        </body>
        </html>
      HTML

      dialog.set_html(html_content)

      dialog.add_action_callback("get_property_lines") do |action_context|
        model = Sketchup.active_model
        property_lines = CashFlowCalculator.get_property_line_data(model)
        saved_settings = load_settings
      
        # First set the property lines
        dialog.execute_script("propertyLines = #{property_lines.to_json}; populatePropertyLines();")
        
        # Then load the saved settings with a slight delay to ensure DOM is ready
        dialog.execute_script(<<-JS
          setTimeout(() => {
            const settings = #{saved_settings.to_json};
            console.log('Loading saved settings:', settings);
            loadSavedSettings(settings);
          }, 100);
        JS
        )
      end
      dialog.add_action_callback("save_optimization_settings") do |action_context, settings_json|
        begin
          settings = JSON.parse(settings_json)
          save_settings(settings)
          UI.messagebox("Settings saved successfully!")
        rescue => e
          puts "Error saving settings: #{e.message}"
          puts e.backtrace
          UI.messagebox("Error saving settings. Check Ruby Console for details.")
        end
      end

      dialog.add_action_callback("launch_optimization") do |action_context, settings_json|
        begin
          settings = JSON.parse(settings_json)
          buildings = find_building_instances(Sketchup.active_model)
          
          # Save settings before optimization
          save_settings(settings)
          
          # Run optimization
          OptimizationAlgorithm.optimize(buildings, settings, dialog)
          
          dialog.execute_script("isOptimizing = false;")
          UI.messagebox("Optimization completed. Check the Output panel for results.")
        rescue => e
          puts "Error during optimization: #{e.message}"
          puts e.backtrace
          dialog.execute_script("isOptimizing = false;")
          UI.messagebox("Error during optimization. Check Ruby Console for details.")
        end
      end

      dialog.show
    end

    def self.save_settings(settings)
      model = Sketchup.active_model
      model.start_operation('Save Optimization Settings', true)
      begin
        model.set_attribute('optimization_settings', 'data', settings.to_json)
        model.commit_operation
      rescue => e
        model.abort_operation
        raise e
      end
    end

    def self.find_building_instances(model, max_depth = 3)
      building_instances = []
      
      def self.recursive_search(entities, transformation, current_depth, max_depth, building_instances)
        return if current_depth > max_depth

        entities.each do |entity|
          if entity.is_a?(Sketchup::ComponentInstance)
            if entity.definition.attribute_dictionary('building_data')
              world_transformation = transformation * entity.transformation
              building_instances << [entity, world_transformation]
            end
            
            recursive_search(entity.definition.entities, transformation * entity.transformation, current_depth + 1, max_depth, building_instances)
          elsif entity.is_a?(Sketchup::Group)
            recursive_search(entity.entities, transformation * entity.transformation, current_depth + 1, max_depth, building_instances)
          end
        end
      end

      recursive_search(model.active_entities, Geom::Transformation.new, 1, max_depth, building_instances)
      
      building_instances
    end

    def self.load_settings
      model = Sketchup.active_model
      saved_json = model.get_attribute('optimization_settings', 'data')
      if saved_json
        begin
          JSON.parse(saved_json)
        rescue => e
          puts "Error parsing saved settings: #{e.message}"
          default_settings
        end
      else
        default_settings
      end
    end

    def self.default_settings
      {
        'optimization_method' => 'npv',
        'discount_rate' => 0.09,
        'north_south_weight' => 0.0,
        'east_west_weight' => 0.0,
        'property_line_order' => [],
        'max_timeline' => 24,
        'use_property_line_priority' => true,
        'irr_weight' => 0.5,  # Keep these for backward compatibility
        'moic_weight' => 0.5  # and when switching methods
      }
    end

    def self.apply_schedule(schedule)
      model = Sketchup.active_model
      model.start_operation('Apply Optimization Schedule', true)
      
      schedule.each do |instance, init_time|
        instance.set_attribute('dynamic_attributes', 'construction_init_time', init_time)
      end
      
      model.commit_operation
      
      # Update phasing colors
      PhasingColorUpdater.update_phasing_colors
    end

  end
end
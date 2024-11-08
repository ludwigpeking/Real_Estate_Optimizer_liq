
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
          <div>
            <label for="north_south_weight">北侧先开工</label>
            <input type="range" id="north_south_weight" min="-100" max="100" value="0" oninput="updateWeightValue('north_south_weight')">
           
            <span id="north_south_weight_value">0</span> <p>南侧先开工</p>
          </div>
          <div>
            <label for="east_west_weight">东侧先开工</label>
            <input type="range" id="east_west_weight" min="-100" max="100" value="0" oninput="updateWeightValue('east_west_weight')">
           
            <span id="east_west_weight_value">0</span> <p>西侧先开工</p>
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

            function updateWeightValue(id) {
              const slider = document.getElementById(id);
              const valueSpan = document.getElementById(id + '_value');
              // Round to nearest integer and append %
              valueSpan.textContent = Math.round(parseFloat(slider.value)) + '%';
            }
            function getPropertyLineOrder() {
              return propertyLines.map(line => line.name);
            }

            function launchOptimization() {
              const settings = {
                irr_weight: parseFloat(document.getElementById('irr_weight').value) / 100,
                moic_weight: parseFloat(document.getElementById('moic_weight').value) / 100,
                north_south_weight: parseFloat(document.getElementById('north_south_weight').value) / 100,
                east_west_weight: parseFloat(document.getElementById('east_west_weight').value) / 100,
                property_line_order: getPropertyLineOrder(),
                max_timeline: parseInt(document.getElementById('max_timeline').value)
              };
              sketchup.launch_optimization(JSON.stringify(settings));
            }

            function saveSettings() {
              const settings = {
                irr_weight: parseFloat(document.getElementById('irr_weight').value) / 100,
                moic_weight: parseFloat(document.getElementById('moic_weight').value) / 100,
                north_south_weight: parseFloat(document.getElementById('north_south_weight').value) / 100,
                east_west_weight: parseFloat(document.getElementById('east_west_weight').value) / 100,
                property_line_order: getPropertyLineOrder(),
                max_timeline: parseInt(document.getElementById('max_timeline').value)
              };
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

            window.onload = function() {
              applyDefaultValues();  // Apply defaults first
              loadPropertyLines();   // Then load any saved settings
            };

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
        'irr_weight' => 0.5,           # Changed from 50 to 0.5
        'moic_weight' => 0.5,          # Changed from 50 to 0.5
        'north_south_weight' => 0.0,   # Changed from 0 to 0.0
        'east_west_weight' => 0.0,     # Changed from 0 to 0.0
        'property_line_order' => [],
        'max_timeline' => 24  
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
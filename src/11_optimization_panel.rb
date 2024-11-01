# optimization_panel.rb
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
            /* Add your CSS styles here */
          </style>
        </head>
        <body>
          <h2>优化权重 Optimization Weights</h2>
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
          <h2>Direction Priority</h2>
          <div>
            <label for="north_south_weight">North-South Priority:</label>
            <input type="range" id="north_south_weight" min="-100" max="100" value="0" oninput="updateWeightValue('north_south_weight')">
            <span id="north_south_weight_value">0</span>
          </div>
          <div>
            <label for="east_west_weight">East-West Priority:</label>
            <input type="range" id="east_west_weight" min="-100" max="100" value="0" oninput="updateWeightValue('east_west_weight')">
            <span id="east_west_weight_value">0</span>
          </div>
          <h2>Property Line Priority</h2>
          <ul id="property_line_list">
            <!-- Property lines will be populated here -->
          </ul>
          <button onclick="saveSettings()">Save Settings</button>
          <button onclick="launchOptimization()">Launch Optimization</button>
          <script>
           
          let propertyLines = [];

          function launchOptimization() {
            const settings = {
              irr_weight: parseFloat(document.getElementById('irr_weight').value) / 100,
              moic_weight: parseFloat(document.getElementById('moic_weight').value) / 100,
              north_south_weight: parseFloat(document.getElementById('north_south_weight').value) / 100,
              east_west_weight: parseFloat(document.getElementById('east_west_weight').value) / 100,
              property_line_order: getPropertyLineOrder()
            };
            sketchup.launch_optimization(JSON.stringify(settings));
          }

          function populatePropertyLines() {
            const list = document.getElementById('property_line_list');
            list.innerHTML = '';
            propertyLines.forEach((line, index) => {
              const li = document.createElement('li');
              li.draggable = true;
              li.setAttribute('data-id', line.id);
              li.textContent = line.name;
              li.addEventListener('dragstart', dragStart);
              li.addEventListener('dragover', dragOver);
              li.addEventListener('drop', drop);
              list.appendChild(li);
            });
          }

          function updateWeightValue(id) {
            const slider = document.getElementById(id);
            const valueSpan = document.getElementById(id + '_value');
            valueSpan.textContent = slider.value;
          }
          
          function dragStart(e) {
            e.dataTransfer.setData('text/plain', e.target.getAttribute('data-id'));
          }
          
          function dragOver(e) {
            e.preventDefault();
          }
          
          function drop(e) {
            e.preventDefault();
            const id = e.dataTransfer.getData('text');
            const draggedElement = document.querySelector(`[data-id="${id}"]`);
            const dropZone = e.target.closest('li');
            if (dropZone && draggedElement !== dropZone) {
              const list = document.getElementById('property_line_list');
              const fromIndex = Array.from(list.children).indexOf(draggedElement);
              const toIndex = Array.from(list.children).indexOf(dropZone);
              if (fromIndex < toIndex) {
                dropZone.parentNode.insertBefore(draggedElement, dropZone.nextSibling);
              } else {
                dropZone.parentNode.insertBefore(draggedElement, dropZone);
              }
              updatePropertyLineOrder();
            }
          }
          
          function updatePropertyLineOrder() {
            const list = document.getElementById('property_line_list');
            propertyLines = Array.from(list.children).map(li => ({
              id: li.getAttribute('data-id'),
              name: li.textContent
            }));
          }
          
          function getPropertyLineOrder() {
            return propertyLines.map(line => line.id);
          }
          
          // Call this function when the page loads to populate property lines
          function loadPropertyLines() {
            sketchup.get_property_lines();
          }
          
          window.onload = function() {
            loadPropertyLines();
          };

            function saveSettings() {
              const settings = {
                irr_weight: document.getElementById('irr_weight').value,
                moic_weight: document.getElementById('moic_weight').value,
                north_weight: document.getElementById('north_weight').value,
                east_weight: document.getElementById('east_weight').value,
                property_line_order: getPropertyLineOrder()
              };
              window.location = 'skp:save_optimization_settings@' + JSON.stringify(settings);
            }

          </script>
        </body>
        </html>
      HTML

      dialog.set_html(html_content)

      dialog.add_action_callback("get_property_lines") do |action_context|
        property_lines = CashFlowCalculator.get_property_line_data(Sketchup.active_model)
        dialog.execute_script("propertyLines = #{property_lines.to_json}; populatePropertyLines();")
      end

      dialog.add_action_callback("launch_optimization") do |action_context, settings_json|
        begin
          settings = JSON.parse(settings_json)
          buildings = find_building_instances(Sketchup.active_model)
          
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
      model.set_attribute('optimization_settings', 'data', settings.to_json)
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
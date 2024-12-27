require 'sketchup.rb'
require 'json'

module Real_Estate_Optimizer
  module ApartmentManager
    APARTMENT_TYPE_LIST_KEY = 'apartment_type_names'

    def self.ensure_layers_exist
      model = Sketchup.active_model
      layers = ['liq_color_mass', 'liq_architecture', 'liq_sunlight', 'liq_phasing', 'liq_price']
      layers.each do |layer_name|
        model.layers.add(layer_name) unless model.layers[layer_name]
      end
    end
    
    def self.show_dialog
      dialog = UI::HtmlDialog.new(
        {
          :dialog_title => "户型维护 Apartment Maintenance",
          :preferences_key => "com.example.apartment_maintenance",
          :scrollable => true,
          :resizable => true,
          :width => 600,
          :height => 600,
          :left => 100,
          :top => 100,
          :min_width => 300,
          :min_height => 200,
          :max_width => 1000,
          :max_height => 1000,
          :style => UI::HtmlDialog::STYLE_DIALOG
        }
      )

      html_content = <<-HTML
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="UTF-8">
          <link rel="stylesheet" type="text/css" href="file:///#{File.join(__dir__, 'style.css')}">
          <script src="file:///#{File.join(__dir__, 'chart.js')}"></script>
        </head>
        <body>
          <div class="form-section">
            <label for="apartment_category">户型属于类型 Apartment in building type of: </label>
            <select id="apartment_category">
              <option value="联排">联排</option>
              <option value="叠拼">叠拼</option>
              <option value="洋房">洋房</option>
              <option value="小高层" selected>小高层</option>
              <option value="大高">大高</option>
              <option value="超高">超高</option>
              <option value="商铺">商铺</option>
              <option value="办公">办公</option>
              <option value="公寓">公寓</option>
            </select><br>

            <label for="apartment_type_area">户型建筑面积 (平米)</label>
            <input type="number" id="apartment_type_area" value="110"><br>


            <label for="tag">备注</label>
            <input type="text" id="tag" value=""><br>


            <label for="apartment_type_name">户型名</label><br>
            <div id="apartment_type_name">110小高层</div>
          </div>

          <div class="form-section">
            <label for="product_baseline_unit_cost_before_allocation">产品基准单位成本 (元/平米)</label>
            <input type="number" id="product_baseline_unit_cost_before_allocation" value="5500"><br>


            <label for="width">面宽 (m)</label>
            <input type="number" id="width" value="10.5">

            <label for="depth">进深 (m)</label>
            <input type="number" id="depth" value="11.0">

              <label for="height">层高 (m)</label>
              <input type="number" id="height" value="3.0" step="0.1">
          </div>

          <div class="form-section">
            <h3>销售场景 Sales Scenes</h3>
            <div id="pricingScenesContainer"></div>
            <button onclick="addPricingScene()">+ Add Pricing Scene</button>
            <div class="scene-switch">
              <label for="scene_change_month">场景切换月份 Scene Switch Month:</label>
              <input type="number" id="scene_change_month" min="0" max="72" value="72" placeholder="Enter month (0-72)">
              <small class="input-hint">(从优化结果加载 Loaded from optimization results)</small>
            </div>
            <button onclick="saveAttributes()">保存属性 Save Attributes</button>
            <button onclick="deleteApartmentType()">删除户型 Delete Apartment Type</button>
          </div>

          <div class="form-section">
            <h3>加载户型 Load Apartment Type</h3>
            <select id="savedApartmentTypes" onchange="loadApartmentType(this.value)">
              <option value="">选择户型...</option>
            </select>
          </div>
          <script>

          function saveOverlapMatrix() {
            const matrix = {};
            const types = Array.from(document.querySelectorAll('#overlapMatrix th'))
              .slice(1)
              .map(th => th.textContent);
              
            types.forEach(type1 => {
              matrix[type1] = {};
              types.forEach(type2 => {
                if (type1 !== type2) {
                  const input = document.getElementById(`overlap_${type1}_${type2}`);
                  if (input && !input.readOnly) {
                    matrix[type1][type2] = parseFloat(input.value) || 0;
                  }
                }
              });
            });
            
            window.location = 'skp:save_overlap_matrix@' + encodeURIComponent(JSON.stringify(matrix));
          }
          
          function enforceOverlapConstraints(input, vol1, vol2, type1, type2) {
            console.log("Enforcing constraints:", type1, type2, vol1, vol2);
            if (!vol1 || !vol2) {
                console.log("Volumes not valid for reverse calculation:", {vol1, vol2});
                return;
            }
            
            // Get the actual input element instead of using activeElement
            const sourceInput = document.getElementById(`overlap_${type1}_${type2}`);
            let value = parseFloat(sourceInput.value) || 0;
            const symmetricInput = document.getElementById(`overlap_${type2}_${type1}`);
            
            if (symmetricInput) {
                const symmetric_value = (value * vol1) / vol2;
                console.log("Calculating reverse overlap:", {value, vol1, vol2, symmetric_value});
                symmetricInput.value = Math.min(1, symmetric_value).toFixed(2);
            }
        }
        



            function updateApartmentTypeName() {
              var area = document.getElementById('apartment_type_area').value;
              var type = document.getElementById('apartment_category').value;
              var tag = document.getElementById('tag').value;
              document.getElementById('apartment_type_name').innerText = area + type + tag;
            }

            function validateInputs() {
              var area = document.getElementById('apartment_type_area').value;
              if (!area || isNaN(area) || area <= 0) {
                alert("请填写有效的户型建筑面积 Please enter a valid apartment type area.");
                return false;
              }
              return true;
            }

            function saveAttributes() {
              if (!validateInputs()) return;
            
              var apartmentData = {
                apartment_category: document.getElementById('apartment_category').value,
                area: parseFloat(document.getElementById('apartment_type_area').value),
                tag: document.getElementById('tag').value,
                apartment_type_name: document.getElementById('apartment_type_name').innerText,
                product_baseline_unit_cost_before_allocation: parseFloat(document.getElementById('product_baseline_unit_cost_before_allocation').value),
                width: parseFloat(document.getElementById('width').value),
                depth: parseFloat(document.getElementById('depth').value),
                height: parseFloat(document.getElementById('height').value) || 3.0,
                scene_change_month: parseInt(document.getElementById('scene_change_month').value),
                sales_scenes: []
              };
            
              // Ensure scene_change_month is a valid number, default to 72 if invalid
              if (isNaN(apartmentData.scene_change_month) || 
                  apartmentData.scene_change_month < 0 || 
                  apartmentData.scene_change_month > 72) {
                apartmentData.scene_change_month = 72;
              }
            
              document.querySelectorAll('.pricing-scene').forEach(function(scene) {
                var price = parseFloat(scene.querySelector('.price').value);
                var volumn = parseInt(scene.querySelector('.volumn').value);
                apartmentData.sales_scenes.push({ price: price, volumn: volumn });
              });
            
              var apartmentTypeName = apartmentData.apartment_type_name;
              window.location = 'skp:save_attributes@' + apartmentTypeName + '@' + JSON.stringify(apartmentData);
            }

            function deleteApartmentType() {
              var select = document.getElementById('savedApartmentTypes');
              var apartmentTypeName = select.value;
              if (!apartmentTypeName) {
                alert("请选择一个户型 Select an apartment type to delete.");
                return;
              }
              var confirmation = confirm("确定删除这个户型吗？ Are you sure you want to delete this apartment type?");
              if (confirmation) {
                window.location = 'skp:delete_apartment_type@' + apartmentTypeName;
              }
            }

            function addPricingScene(price = '', volumn = '') {
              var container = document.getElementById('pricingScenesContainer');
              var index = container.children.length;
              var div = document.createElement('div');
              div.className = 'pricing-scene';
              div.innerHTML = `
                <label>场景 ${index + 1} Scene ${index + 1}</label>
                <input class="price" type="number" value="${price}" placeholder="单价 Price (元/平米)"> <p>元/平米</p>
                <input class="volumn" type="number" value="${volumn}" placeholder="月销量 Monthly Sales"> <p>套/月</p>
              `;
              
              if (index > 0) {
                var removeButton = document.createElement('button');
                removeButton.className = 'remove';
                removeButton.innerText = '-';
                removeButton.onclick = function() {
                  container.removeChild(div);
                };
                div.appendChild(removeButton);
              }
              container.appendChild(div);
            }
            

            function loadApartmentType(apartmentTypeName) {
              window.location = 'skp:load_apartment_type@' + apartmentTypeName;
            }

            function populateApartmentType(apartmentData) {
              var data = JSON.parse(apartmentData);
              document.getElementById('apartment_category').value = data.apartment_category;
              document.getElementById('apartment_type_area').value = data.area;
              document.getElementById('tag').value = data.tag;
              document.getElementById('apartment_type_name').innerText = data.apartment_type_name;
              document.getElementById('product_baseline_unit_cost_before_allocation').value = data.product_baseline_unit_cost_before_allocation;
              document.getElementById('width').value = data.width;
              document.getElementById('depth').value = data.depth;
              document.getElementById('height').value = data.height || 3.0;
              
              // Load scene change month - if it's not set, use 72 as default
              var sceneChangeMonth = data.scene_change_month;
              document.getElementById('scene_change_month').value = (sceneChangeMonth !== undefined && sceneChangeMonth !== null) ? sceneChangeMonth : 72;
            
              var container = document.getElementById('pricingScenesContainer');
              container.innerHTML = '';
              data.sales_scenes.forEach(function(scene) {
                addPricingScene(scene.price, scene.volumn);
              });
            }
            
            function updateSavedApartmentTypes(apartmentTypes) {
              var select = document.getElementById('savedApartmentTypes');
              select.innerHTML = '<option value="">选择户型...</option>';
              apartmentTypes.forEach(function(name) {
                var option = document.createElement('option');
                option.value = name;
                option.text = name;
                select.appendChild(option);
              });
            }

            window.onload = function() {
              // Keep all existing functionality
              document.getElementById('apartment_type_area').oninput = updateApartmentTypeName;
              document.getElementById('apartment_category').onchange = updateApartmentTypeName;
              document.getElementById('tag').oninput = updateApartmentTypeName;
              addPricingScene();
              window.location = 'skp:get_saved_apartment_types';
              
              // Initialize overlap matrix after a slight delay to ensure apartment types are loaded
              setTimeout(() => {
                updateOverlapMatrix();
              }, 1000);  // 1 second delay
              
              // Add observer for future changes to apartment types
              const typesSelect = document.getElementById('savedApartmentTypes');
              const observer = new MutationObserver(function(mutations) {
                mutations.forEach(function(mutation) {
                  if (mutation.type === 'childList') {
                    updateOverlapMatrix();
                  }
                });
              });
              
              observer.observe(typesSelect, {
                childList: true,
                subtree: true
              });
            }

        
          </script>
        </body>
        </html>
      HTML

      dialog.set_html(html_content)

      dialog.add_action_callback("save_attributes") do |action_context, params|
        apartment_type_name, apartment_data_json = params.split('@', 2)
        apartment_data = JSON.parse(apartment_data_json)
        model = Sketchup.active_model

        # Retrieve the current list of apartment type names
        apartment_type_names = model.get_attribute('apartment_type_data', APARTMENT_TYPE_LIST_KEY, [])
        
        if apartment_type_names.include?(apartment_type_name)
          result = UI.messagebox("户型名已存在。是否覆盖？ Apartment type name already exists. Overwrite?", MB_YESNO)
          return if result == IDNO
        else
          apartment_type_names << apartment_type_name
          model.set_attribute('apartment_type_data', APARTMENT_TYPE_LIST_KEY, apartment_type_names)
        end

        model.set_attribute('apartment_type_data', apartment_type_name, apartment_data.to_json)
        puts "Stored data for #{apartment_type_name}: #{apartment_data.inspect}"  # Debugging line

        # Create or update the apartment component
        create_apartment_component(apartment_data)

        UI.messagebox("属性已保存 Attributes saved: " + apartment_data['apartment_type_name'])
        update_saved_apartment_types(dialog)
        dialog.execute_script(<<-JS
          setTimeout(() => {
            const matrix = document.getElementById('overlapMatrix');
            if (matrix) {
              // Recalculate all overlap values since sales velocities might have changed
              const inputs = matrix.querySelectorAll('input:not([readonly])');
              inputs.forEach(input => validateOverlap(input));
            }
          }, 500);
        JS
        )
      end

      dialog.add_action_callback("delete_apartment_type") do |action_context, apartment_type_name|
        model = Sketchup.active_model
        model.delete_attribute('apartment_type_data', apartment_type_name)
        
        apartment_type_names = model.get_attribute('apartment_type_data', APARTMENT_TYPE_LIST_KEY, [])
        apartment_type_names.delete(apartment_type_name)
        model.set_attribute('apartment_type_data', APARTMENT_TYPE_LIST_KEY, apartment_type_names)

        puts "Deleted data for #{apartment_type_name}"  # Debugging line
        UI.messagebox("户型已删除 Apartment type deleted: " + apartment_type_name)
        update_saved_apartment_types(dialog)
      end

      dialog.add_action_callback("load_apartment_type") do |action_context, apartment_type_name|
        model = Sketchup.active_model
        apartment_data_json = model.get_attribute('apartment_type_data', apartment_type_name)
        if apartment_data_json
          dialog.execute_script("populateApartmentType('#{apartment_data_json}')")
        else
          UI.messagebox("未找到该户型数据 Apartment type data not found.")
        end
      end

      def self.initialize_overlap_matrix(types)
        matrix = {}
        types.each do |type1|
          matrix[type1] = {}
          types.each do |type2|
            next if type1 == type2
            matrix[type1][type2] = 0.0
          end
        end
        matrix
      end

      dialog.add_action_callback("get_saved_apartment_types") do |action_context|
        model = Sketchup.active_model
        puts "\n=== Loading Apartment Types and Overlaps ==="
        
        # Load apartment types
        apartment_type_names = model.get_attribute('apartment_type_data', APARTMENT_TYPE_LIST_KEY, [])
        sorted_types = sort_apartment_types(apartment_type_names)
        puts "Found apartment types: #{sorted_types.inspect}"
        
        # Load overlap matrix
        overlap_matrix = model.get_attribute('apartment_type_data', 'overlap_matrix', '{}')
        overlap_matrix = JSON.parse(overlap_matrix)
        puts "Retrieved overlap matrix: #{overlap_matrix.inspect}"
        
        # Update apartment types in dialog
        dialog.execute_script("updateSavedApartmentTypes(#{sorted_types.to_json})")
        
        # Prepare JavaScript command
        js_command = <<-JS
          window.savedOverlapMatrix = #{overlap_matrix.to_json};
          console.log("Setting savedOverlapMatrix:", window.savedOverlapMatrix);
          
          setTimeout(() => {
            console.log("Starting matrix update...");
            updateOverlapMatrix();
            
            // First set all saved values
            Object.keys(window.savedOverlapMatrix).forEach(type1 => {
              Object.keys(window.savedOverlapMatrix[type1]).forEach(type2 => {
                const input = document.getElementById(`overlap_${type1}_${type2}`);
                if (input && !input.readOnly) {
                  input.value = window.savedOverlapMatrix[type1][type2].toFixed(2);
                  console.log(`Set value for ${type1}-${type2}: ${input.value}`);
                }
              });
            });
            
            // Then update all reversal values at once
            const editableInputs = document.querySelectorAll('#overlapMatrix input:not([readonly])');
            console.log("Found editable inputs:", editableInputs.length);
            
            editableInputs.forEach(input => {
              const parts = input.id.split('_');
              if (parts.length === 3) {
                const type1 = parts[1];
                const type2 = parts[2];
                console.log(`Requesting volumes for ${type1}-${type2}`);
                const params = JSON.stringify({type1: type1, type2: type2});
                window.location = 'skp:get_apartment_volumes@' + encodeURIComponent(params);
              }
            });
          }, 1000);
        JS
        
        # Execute JavaScript with debug output
        puts "Executing JavaScript command..."
        dialog.execute_script(js_command)
        puts "JavaScript command executed"
      end
      
      dialog.add_action_callback("get_apartment_volumes") do |action_context, params_json|
        begin
          model = Sketchup.active_model
          params = JSON.parse(URI.decode_www_form_component(params_json))
          type1 = params['type1']
          type2 = params['type2']
          
          # Get all apartment types and their volumes at once
          apartment_type_names = model.get_attribute('apartment_type_data', APARTMENT_TYPE_LIST_KEY, [])
          volumes = {}
          
          apartment_type_names.each do |apt_type|
            data = JSON.parse(model.get_attribute('apartment_type_data', apt_type) || '{}')
            volumes[apt_type] = data.dig('sales_scenes', 0, 'volumn') || 0
          end
          
          puts "All volumes: #{volumes.inspect}"
          
          # Send all volumes to JavaScript
          js_command = <<-JS
            if (!window.apartmentVolumes) window.apartmentVolumes = {};
            const volumes = #{volumes.to_json};
            Object.keys(volumes).forEach(type => {
              window.apartmentVolumes[type] = volumes[type];
              console.log('Updated volume for ' + type + ': ' + volumes[type]);
            });
            enforceOverlapConstraints(null, volumes['#{type1}'], volumes['#{type2}'], '#{type1}', '#{type2}');
          JS
          
          dialog.execute_script(js_command)
        rescue => e
          puts "Error in get_apartment_volumes: #{e.message}"
          puts e.backtrace
        end
      end
      
      
      dialog.add_action_callback("save_overlap_matrix") do |action_context, matrix_json|
        save_overlap_matrix(matrix_json)
      end

      dialog.show
    end
    def self.create_apartment_component(apartment_data)
      model = Sketchup.active_model
      definitions = model.definitions
      
      component_name = apartment_data['apartment_type_name']
      
      model.start_operation('Create/Update Apartment Component', true)
    
      # Create layers if they don't exist
      layers = ['liq_color_mass', 'liq_architecture', 'liq_sunlight', 'liq_phasing', 'liq_price']
      layers.each do |layer_name|
        model.layers.add(layer_name) unless model.layers[layer_name]
      end
    
      # Create or update component definition
      apartment_def = definitions[component_name] || definitions.add(component_name)
      apartment_def.entities.clear!
    
      # Store current active layer
      original_layer = model.active_layer
    
      # Create geometry for each layer
      layers.each do |layer_name|
        # Set the layer as active before creating the group
        model.active_layer = model.layers[layer_name]
        
        group = apartment_def.entities.add_group
        group.layer = layer_name
    
        # Create the geometry for the apartment within the group
        width = apartment_data['width'].to_f.m
        depth = apartment_data['depth'].to_f.m
        height = (apartment_data['height'] || 3.0).to_f.m
    
        # All entities created will automatically be on the current active layer
        face = group.entities.add_face([0, 0, 0], [0, depth, 0], [width, depth, 0], [width, 0, 0])
        face.pushpull(-height)
    
        # Only create and apply material for liq_color_mass layer
        if layer_name == 'liq_color_mass'
          material_name = "#{component_name}_color_mass"
          material = model.materials[material_name] || model.materials.add(material_name)
          
          category = apartment_data['apartment_category']
          if ['商铺', '办公', '公寓'].include?(category)
            material.color = Sketchup::Color.new(255, 0, 0)  # Red for commercial, office, and apartment
          else
            hue = (apartment_data['area'].to_f - 50) * 2 % 360
            rgb = hsl_to_rgb(hue, 100, 50)
            material.color = Sketchup::Color.new(*rgb)
          end
          
          # Apply material to faces in liq_color_mass layer
          group.entities.grep(Sketchup::Face).each { |entity| 
            entity.material = material
            entity.layer = layer_name
          }
        else
          # For all other layers, use default material
          group.entities.grep(Sketchup::Face).each { |entity| 
            entity.material = nil
            entity.layer = layer_name
          }
        end
        
        # Set layer for all edges (no material needed)
        group.entities.grep(Sketchup::Edge).each { |edge| 
          edge.layer = layer_name
        }
      end
    
      # Restore original active layer
      model.active_layer = original_layer
    
      # Add attributes to the component
      apartment_def.set_attribute('apartment_data', 'area', apartment_data['area'])
      apartment_def.set_attribute('apartment_data', 'category', apartment_data['apartment_category'])
      apartment_def.set_attribute('apartment_data', 'product_baseline_unit_cost', apartment_data['product_baseline_unit_cost_before_allocation'])
      apartment_def.set_attribute('apartment_data', 'height', apartment_data['height'] || 3.0)
    
      model.commit_operation
    
      apartment_def
    end

    def self.sort_apartment_types(apartment_types)
      apartment_types.sort_by do |type|
        match = type.match(/(\d+)([A-Za-z]*)/)
        if match
          [match[1].to_i, match[2]]  # Sort by number first, then by letter
        else
          [Float::INFINITY, type]  # Put non-matching names at the end
        end
      end
    end
    
    def self.hsl_to_rgb(h, s, l)
      h /= 360.0
      s /= 100.0
      l /= 100.0
      
      c = (1 - (2 * l - 1).abs) * s
      x = c * (1 - ((h * 6) % 2 - 1).abs)
      m = l - c / 2
    
      r, g, b = case (h * 6).to_i
                when 0 then [c, x, 0]
                when 1 then [x, c, 0]
                when 2 then [0, c, x]
                when 3 then [0, x, c]
                when 4 then [x, 0, c]
                else [c, 0, x]
                end
    
      [(r + m) * 255, (g + m) * 255, (b + m) * 255].map(&:round)
    end

    def self.switch_layer(layer_name)
      model = Sketchup.active_model
      layers = ['liq_color_mass', 'liq_architecture', 'liq_sunlight', 'liq_phasing', 'liq_price']
      
      layers.each do |name|
        layer = model.layers[name]
        layer.visible = (name == layer_name)
      end
      model.active_layer = model.layers[layer_name]
    end

    def self.place_component_in_model(component_def)
      model = Sketchup.active_model
      entities = model.active_entities
      
      # Find a clear space to place the component
      bbox = component_def.bounds
      max_dimension = [bbox.width, bbox.height, bbox.depth].max
      placement_point = Geom::Point3d.new(max_dimension, max_dimension, 0)
      
      # Add the component to the model
      instance = entities.add_instance(component_def, placement_point)
      
      # Zoom to the newly placed component
      model.active_view.zoom(instance)
    end
    

    def self.update_saved_apartment_types(dialog)
      model = Sketchup.active_model
      apartment_type_names = model.get_attribute('apartment_type_data', APARTMENT_TYPE_LIST_KEY, [])
      
      # Sort the apartment types
      sorted_apartment_types = sort_apartment_types(apartment_type_names)
      
      # Pass the sorted array to the JavaScript function
      dialog.execute_script("updateSavedApartmentTypes(#{sorted_apartment_types.to_json})")
    end



    def self.parse_apartment_type(raw_type)
      return nil if raw_type.nil? || raw_type.empty?
      
      # Remove any whitespace and split by @ if present
      types = raw_type.strip.split('@')
      types.first.strip
    end

  end
end

# Real_Estate_Optimizer::ApartmentManager.show_dialog

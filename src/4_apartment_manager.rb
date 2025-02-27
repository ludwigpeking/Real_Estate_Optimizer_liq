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
            <div style="margin-top: 12px; margin-bottom: 12px;">
              <label style="display: block; margin-bottom: 6px;">户型颜色 Apartment Color:</label>
              <div class="custom-color-picker">
                <div style="display: flex; align-items: center; margin-bottom: 8px;">
                  <div class="color-preview" id="color-preview" style="width: 32px; height: 32px; border: 1px solid #ccc; cursor: pointer;"></div>
                  <div style="margin-left: 8px; font-size: 12px; color: #666;">
                    (Click color box to show/hide options)
                  </div>
                </div>

                <div class="color-options" id="color-options" style="display:none; margin-top: 8px; border: 1px solid #ddd; padding: 12px; background: #f9f9f9; border-radius: 4px;">
                  <div class="color-input-container" style="margin-bottom: 10px;">
                    <div style="display: flex; align-items: center; margin-bottom: 8px;">
                      <label for="color-r-input" style="width: 20px; margin-right: 8px;">R:</label>
                      <input type="number" id="color-r-input" min="0" max="255" value="0" style="width: 60px;">
                      <div id="live-color-preview" style="width: 32px; height: 32px; border: 1px solid #ccc; margin-left: 15px;"></div>
                    </div>
                    <div style="display: flex; align-items: center; margin-bottom: 8px;">
                      <label for="color-g-input" style="width: 20px; margin-right: 8px;">G:</label>
                      <input type="number" id="color-g-input" min="0" max="255" value="0" style="width: 60px;">
                    </div>
                    <div style="display: flex; align-items: center; margin-bottom: 8px;">
                      <label for="color-b-input" style="width: 20px; margin-right: 8px;">B:</label>
                      <input type="number" id="color-b-input" min="0" max="255" value="0" style="width: 60px;">
                    </div>
                  </div>
                  
                  <div style="display: flex; gap: 8px;">
                    <button id="apply-color" style="padding: 4px 12px;">Apply</button>
                    <button id="reset-color" style="padding: 4px 12px;">Reset to Auto</button>
                  </div>
                </div>
              </div>
              <div style="font-size: 12px; color: #666; margin-top: 4px;">
                (Auto-generated from area unless custom color selected)
              </div>
            </div>
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

          function calculateAutoColor(area) {
              if (!area) return '#CCCCCC';
              const hue = (area - 50) * 2.5 % 360;
              return `hsl(${hue}, 100%, 85%)`;
          }
          // Convert RGB to hex
          function rgbToHex(r, g, b) {
            return '#' + [r, g, b].map(x => {
                const hex = parseInt(x).toString(16);
                return hex.length === 1 ? '0' + hex : hex;
            }).join('');
          }

          // Convert hex to RGB
          function hexToRgb(hex) {
            const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
            return result ? {
                r: parseInt(result[1], 16),
                g: parseInt(result[2], 16),
                b: parseInt(result[3], 16)
            } : null;
          }

          function clampRgb(value) {
              const num = parseInt(value);
              return isNaN(num) ? 0 : Math.max(0, Math.min(255, num));
          }

          // Update RGB inputs from hex color
          function updateRgbInputs(hexColor) {
              const rgb = hexToRgb(hexColor);
              if (rgb) {
                  document.getElementById('color-r-input').value = rgb.r;
                  document.getElementById('color-g-input').value = rgb.g;
                  document.getElementById('color-b-input').value = rgb.b;
              }
          }
          function initializeColorPicker() {
            const colorPreview = document.getElementById('color-preview');
            const colorOptions = document.getElementById('color-options');
            const rInput = document.getElementById('color-r-input');
            const gInput = document.getElementById('color-g-input');
            const bInput = document.getElementById('color-b-input');
            const applyButton = document.getElementById('apply-color');
            const resetButton = document.getElementById('reset-color');
            const areaInput = document.getElementById('apartment_type_area');
            const livePreview = document.getElementById('live-color-preview');
            
            // Initialize with auto color
            let currentColor = calculateAutoColor(areaInput.value);
            colorPreview.style.backgroundColor = currentColor;
            livePreview.style.backgroundColor = currentColor;
            
            // Set initial RGB values from auto color
            updateRgbInputs(currentColor);
            
            // Show/hide color options when clicking preview
            colorPreview.addEventListener('click', () => {
              colorOptions.style.display = colorOptions.style.display === 'none' ? 'block' : 'none';
            });
          
            // Function to update the live preview
            function updateLivePreview() {
              const r = clampRgb(rInput.value);
              const g = clampRgb(gInput.value);
              const b = clampRgb(bInput.value);
              
              const hexColor = rgbToHex(r, g, b);
              livePreview.style.backgroundColor = hexColor;
            }
            
            // Update live preview when RGB values change
            rInput.addEventListener('input', updateLivePreview);
            gInput.addEventListener('input', updateLivePreview);
            bInput.addEventListener('input', updateLivePreview);
          
            // Apply RGB color when button is clicked
            applyButton.addEventListener('click', () => {
              const r = clampRgb(rInput.value);
              const g = clampRgb(gInput.value);
              const b = clampRgb(bInput.value);
              
              // Update RGB inputs with valid values
              rInput.value = r;
              gInput.value = g;
              bInput.value = b;
              
              // Convert to hex for storage
              const hexColor = rgbToHex(r, g, b);
              currentColor = hexColor;
              
              // Update both previews
              colorPreview.style.backgroundColor = currentColor;
              livePreview.style.backgroundColor = currentColor;
              colorPreview.setAttribute('data-custom-color', 'true');
            });
          
            // Reset to auto color
            resetButton.addEventListener('click', () => {
              currentColor = calculateAutoColor(areaInput.value);
              colorPreview.style.backgroundColor = currentColor;
              livePreview.style.backgroundColor = currentColor;
              updateRgbInputs(currentColor);
              colorPreview.removeAttribute('data-custom-color');
            });
          
            // Update on area change if not using custom color
            areaInput.addEventListener('input', (e) => {
              if (!colorPreview.hasAttribute('data-custom-color')) {
                currentColor = calculateAutoColor(e.target.value);
                colorPreview.style.backgroundColor = currentColor;
                livePreview.style.backgroundColor = currentColor;
                updateRgbInputs(currentColor);
              }
            });
          }
    
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
              if (!area || isNaN(area) || area < 0) {
                alert("请填写有效的户型建筑面积 Please enter a valid apartment type area.");
                return false;
              }
              return true;
            }
            function saveAttributes() {
              if (!validateInputs()) return;
            
              var colorPreview = document.getElementById('color-preview');
              var rInput = document.getElementById('color-r-input');
              var gInput = document.getElementById('color-g-input');
              var bInput = document.getElementById('color-b-input');
              
              // Get color in hex format
              var colorHex = colorPreview.hasAttribute('data-custom-color') ? 
                rgbToHex(rInput.value, gInput.value, bInput.value) : null;
            
              var apartmentData = {
                color: colorHex,
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
            
            const colorPreview = document.getElementById('color-preview');
            
            if (data.color) {
              colorPreview.style.backgroundColor = data.color;
              updateRgbInputs(data.color);
              colorPreview.setAttribute('data-custom-color', 'true');
            } else {
              const autoColor = calculateAutoColor(data.area);
              colorPreview.style.backgroundColor = autoColor;
              updateRgbInputs(autoColor);
              colorPreview.removeAttribute('data-custom-color');
            }
            
            var container = document.getElementById('pricingScenesContainer');
            container.innerHTML = '';
            data.sales_scenes.forEach(function(scene) {
              addPricingScene(scene.price, scene.volumn);
            });
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
              div.className = 'pricing-scene single-line';
              div.innerHTML = `
                <label>场景 ${index + 1} Scene ${index + 1}</label>
                <input class="price" type="number" value="${price}" placeholder="单价 Price (元/平米)">
                <span>元/平米</span>
                <input class="volumn" type="number" value="${volumn}" placeholder="月销量 Monthly Sales">
                <span>套/月</span>
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
              // Existing code...
              document.getElementById('apartment_type_area').oninput = updateApartmentTypeName;
              document.getElementById('apartment_category').onchange = updateApartmentTypeName;
              document.getElementById('tag').oninput = updateApartmentTypeName;
              initializeColorPicker();
              addPricingScene();
              window.location = 'skp:get_saved_apartment_types';
          }
          </script>
        </body>
        </html>
      HTML

      def self.update_building_types_with_apartment(model, apartment_type_name, apartment_data)
        puts "\n=== Updating Building Types for Apartment: #{apartment_type_name} ==="
        
        # Get building type names and project data
        building_type_names = model.get_attribute('project_data', BuildingGenerator::BUILDING_TYPE_LIST_KEY, [])
        project_data = JSON.parse(model.get_attribute('project_data', 'data', '{}'))
        project_data['building_types'] ||= []
        
        puts "Found #{building_type_names.length} building types in type list"
        puts "Found #{project_data['building_types'].length} building types in project data"
      
        # Get building types from either source
        building_types = if !project_data['building_types'].empty?
          project_data['building_types']
        else
          building_type_names.map do |name| 
            definition = model.definitions[name]
            if definition && definition.attribute_dictionaries && definition.attribute_dictionaries['building_data']
              JSON.parse(definition.get_attribute('building_data', 'details'))
            end
          end.compact
        end
      
        building_types.each do |building_type|
          modified = false
          total_cost = 0
          total_area = 0
          
          building_type['floorTypes'].each do |floor_type|
            num_floors = floor_type['number'].to_i
            
            floor_type['apartmentTypes'].each do |apartment|
              apt_name = apartment['name']
              
              # Get the current data for this apartment type
              apt_data = if apt_name == apartment_type_name
                modified = true
                apartment_data
              else
                JSON.parse(model.get_attribute('apartment_type_data', apt_name) || '{}')
              end
              
              next if apt_data.empty?
              
              # Calculate cost for this apartment occurrence
              apt_area = apt_data['area'].to_f
              apt_unit_cost = apt_data['product_baseline_unit_cost_before_allocation'].to_f
              apt_cost_per_unit = apt_area * apt_unit_cost
              apt_total_cost = apt_cost_per_unit * num_floors
              
              total_cost += apt_total_cost
              total_area += apt_area * num_floors
            end
          end
          
          if modified

            
            # Update component definition
            building_def = model.definitions[building_type['name']]
            if building_def
              building_def.set_attribute('building_data', 'total_cost', total_cost)
              building_def.set_attribute('building_data', 'total_area', total_area)
              building_def.set_attribute('building_data', 'details', building_type.to_json)
              
              # Verify the update
              actual_cost = building_def.get_attribute('building_data', 'total_cost')
            end
            
            # Update project data
            building_type['total_cost'] = total_cost
            building_type['total_area'] = total_area
          end
        end
        
        # Save everything back
        project_data['building_types'] = building_types
        model.set_attribute('project_data', 'data', project_data.to_json)
        puts "=== Building Type Update Complete ===\n"
      end

      dialog.set_html(html_content)

      dialog.add_action_callback("save_attributes") do |action_context, params|
        apartment_type_name, apartment_data_json = params.split('@', 2)
        apartment_data = JSON.parse(apartment_data_json)
        model = Sketchup.active_model
      
        begin
          model.start_operation('Save Apartment Type', true)
          
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
          puts "Stored data for #{apartment_type_name}: #{apartment_data.inspect}"
      
          # Create or update the apartment component
          create_apartment_component(apartment_data)
      
          # Update building types that contain this apartment type
          update_building_types_with_apartment(model, apartment_type_name, apartment_data)
      
          model.commit_operation
          
          UI.messagebox("属性已保存 Attributes saved: " + apartment_data['apartment_type_name'])
          update_saved_apartment_types(dialog)
        rescue => e
          model.abort_operation
          puts "Error saving apartment type: #{e.message}"
          puts e.backtrace
          UI.messagebox("Error saving apartment type: #{e.message}")
        end
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
          if apartment_data['color']
            # Parse the custom color to RGB
            color_str = apartment_data['color'].gsub('#', '')
            r = color_str[0..1].to_i(16)
            g = color_str[2..3].to_i(16)
            b = color_str[4..5].to_i(16)
            material.color = Sketchup::Color.new(r, g, b)
        elsif ['商铺', '办公', '公寓'].include?(category)
            material.color = Sketchup::Color.new(255, 0, 0)  # Red for commercial
        else
            hue = (apartment_data['area'].to_f - 50) * 2.5 % 360
            rgb = hsl_to_rgb(hue, 100, 85)
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

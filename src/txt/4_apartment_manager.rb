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
            <h3>销售场景</h3>
            <div id="pricingScenesContainer"></div>
            <button onclick="saveAttributes()">保存属性 Save Attributes</button>
            <button onclick="deleteApartmentType()">删除户型 Delete Apartment Type</button>
          </div>

          <div class="form-section">
            <h3>加载户型 Load Apartment Type</h3>
            <select id="savedApartmentTypes" onchange="loadApartmentType(this.value)">
              <option value="">选择户型...</option>
            </select>
          </div>

          <div class="form-section">
            <h3>客户重叠矩阵 Customer Overlap Matrix</h3>
            <p class="note">Enter overlap rates between apartment types. Values between 0 and 1.</p>
            <div id="overlapMatrixContainer">
              <table id="overlapMatrix" class="overlap-table">
              </table>
            </div>
            <button onclick="saveOverlapMatrix()">保存重叠矩阵 Save Overlap Matrix</button>
          </div>

          <div class="calculation-results" style="margin-top: 20px; display: none;">
            <h3>销售调整结果 Sales Adjustment Results</h3>
            <div id="salesResults"></div>
            <canvas id="salesChart" width="600" height="300"></canvas>
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
        

          function storeOverlapValues() {
            const matrix = {};
            const types = Array.from(document.querySelectorAll('#overlapMatrix th'))
                .slice(1)
                .map(th => th.textContent);
            
            // Only store editable (upper triangle) values
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
              if (!validateInputs()) {
                return;
              }

              var apartmentData = {
                apartment_category: document.getElementById('apartment_category').value,
                area: parseFloat(document.getElementById('apartment_type_area').value),
                tag: document.getElementById('tag').value,
                apartment_type_name: document.getElementById('apartment_type_name').innerText,
                product_baseline_unit_cost_before_allocation: parseFloat(document.getElementById('product_baseline_unit_cost_before_allocation').value),
                width: parseFloat(document.getElementById('width').value),
                depth: parseFloat(document.getElementById('depth').value),
                height: parseFloat(document.getElementById('height').value) || 3.0,  // Default to 3.0 if not specified
                sales_scenes: []
              };

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
              div.innerHTML = '<input class="price" type="number" value="' + price + '" placeholder="销售场景' + (index + 1) + ' (元/平米)">' +
                '<input class="volumn" type="number" value="' + volumn + '" placeholder="15套/月" >' +
                '<button class="add" onclick="addPricingScene()">+</button>';
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
            function calculateAdjustedSales() {
              const types = Array.from(document.querySelectorAll('#overlapMatrix th'))
                  .slice(1)
                  .map(th => th.textContent);
              
              if (types.length === 0) return;
              
              const demands = {};
              const overlaps = {};
              let hasValidData = true;
              
              // Collect demands (volumes) and overlap rates
              types.forEach(type1 => {
                  demands[type1] = 0;
                  overlaps[type1] = {};
                  types.forEach(type2 => {
                      if (type1 !== type2) {
                          const input = document.getElementById(`overlap_${type1}_${type2}`);
                          if (input) {
                              overlaps[type1][type2] = parseFloat(input.value) || 0;
                          }
                      }
                  });
              });
              
              // Get volumes from sales scenes
              for (const type of types) {
                  const volInput = document.querySelector(`#overlap_${type}_${types[0]}`);
                  if (volInput && volInput.dataset.volume) {
                      demands[type] = parseFloat(volInput.dataset.volume);
                  } else {
                      hasValidData = false;
                      break;
                  }
              }
              
              if (!hasValidData) return;
              
              // Calculate adjusted sales
              const adjustedSales = {};
              let totalSales = 0;
              
              types.forEach(type => {
                  let adjustment = 0;
                  types.forEach(otherType => {
                      if (type !== otherType) {
                          const overlap = overlaps[type][otherType] || 0;
                          if (demands[type] + demands[otherType] > 0) {
                              adjustment += (overlap * (demands[otherType] * demands[type])) / 
                                          (demands[type] + demands[otherType]);
                          }
                      }
                  });
                  adjustedSales[type] = Math.max(0, demands[type] - adjustment);
                  totalSales += adjustedSales[type];
              });
              
              updateResults(totalSales, adjustedSales);
          }
          
          function updateResults(totalSales, adjustedSales) {
            const resultsDiv = document.getElementById('salesResults');
            const container = document.querySelector('.calculation-results');
            
            // Ensure container is visible
            container.style.removeProperty('display');
            
            let html = `<strong>总调整销量 Total Adjusted Sales:</strong> ${totalSales.toFixed(2)} 套/月<br>`;
            html += '<strong>销售分布 Sales Distribution:</strong><br>';
            
            const labels = [];
            const data = [];
            const backgroundColors = [];
            
            Object.entries(adjustedSales).forEach(([type, sales], index) => {
                html += `- ${type}: ${sales.toFixed(2)} 套/月<br>`;
                labels.push(type);
                data.push(sales.toFixed(2));
                const hue = ((index * 360) / Object.keys(adjustedSales).length) % 360;
                backgroundColors.push(`hsl(${hue}, 70%, 50%)`);
            });
            
            resultsDiv.innerHTML = html;
            
            // Ensure chart container is visible before creating chart
            const chartCanvas = document.getElementById('salesChart');
            chartCanvas.style.display = 'block';
            updateChart(labels, data, backgroundColors);
        }
          
          function updateChart(labels, data, backgroundColors) {
              const ctx = document.getElementById('salesChart').getContext('2d');
              
              if (window.salesChartInstance) {
                  window.salesChartInstance.destroy();
              }
              
              window.salesChartInstance = new Chart(ctx, {
                  type: 'bar',
                  data: {
                      labels: labels,
                      datasets: [{
                          label: '销售量 (套/月)',
                          data: data,
                          backgroundColor: backgroundColors,
                          barPercentage: 0.3,
                          categoryPercentage: 0.7
                      }]
                  },
                  options: {
                      responsive: true,
                      maintainAspectRatio: false,
                      scales: {
                          y: {
                              beginAtZero: true
                          }
                      },
                      plugins: {
                          legend: {
                              display: false
                          },
                          title: {
                              display: true,
                              text: '户型销售分布',
                              font: { size: 16 }
                          }
                      }
                  }
              });
          }
                    
          function updateOverlapMatrix() {
            const container = document.getElementById('overlapMatrix');
            const select = document.getElementById('savedApartmentTypes');
            const apartmentTypes = Array.from(select.options)
              .filter(opt => opt.value)
              .map(opt => opt.value);
            
            // Initialize volumes storage
            window.apartmentVolumes = {};
            
            // Clear existing content
            container.innerHTML = '';
            
            // Create header row
            const headerRow = document.createElement('tr');
            headerRow.appendChild(document.createElement('th')); // Empty corner cell
            apartmentTypes.forEach(type => {
              const th = document.createElement('th');
              th.textContent = type;
              headerRow.appendChild(th);
            });
            container.appendChild(headerRow);
            
            // Create matrix rows
            apartmentTypes.forEach((rowType, i) => {
              const row = document.createElement('tr');
              const header = document.createElement('th');
              header.textContent = rowType;
              row.appendChild(header);
              
              apartmentTypes.forEach((colType, j) => {
                const cell = document.createElement('td');
                if (i === j) {
                  cell.textContent = '—';
                } else if (j > i) {
                  const input = document.createElement('input');
                  input.type = 'number';
                  input.min = '0';
                  input.max = '1';
                  input.step = '0.1';
                  input.id = `overlap_${rowType}_${colType}`;
                  input.className = 'overlap-input';
                  input.value = '0.0';
                  input.onchange = () => validateOverlap(input);
                  cell.appendChild(input);
                } else {
                  // Lower triangle (read-only)
                  const input = document.createElement('input');
                  input.type = 'number';
                  input.id = `overlap_${rowType}_${colType}`;
                  input.className = 'overlap-input read-only';
                  input.value = '0.0';
                  input.readOnly = true;
                  cell.appendChild(input);
                }
                row.appendChild(cell);
              });
              container.appendChild(row);
            });
            
            // After matrix structure is created, load saved values
            if (window.savedOverlapMatrix) {
              console.log("Loading saved overlap matrix:", window.savedOverlapMatrix);
              
              // First set all saved values
              Object.entries(window.savedOverlapMatrix).forEach(([type1, vals]) => {
                Object.entries(vals).forEach(([type2, value]) => {
                  const input = document.getElementById(`overlap_${type1}_${type2}`);
                  if (input && !input.readOnly) {
                    input.value = value.toFixed(2);
                    console.log(`Set initial value for ${type1}-${type2}: ${value}`);
                  }
                });
              });
              
              // Then validate all inputs to update reversal values
              const editableInputs = document.querySelectorAll('#overlapMatrix input:not([readonly])');
              editableInputs.forEach(input => validateOverlap(input));
            }
          
            // Request initial volumes for all pairs
            apartmentTypes.forEach(type1 => {
              apartmentTypes.forEach(type2 => {
                if (type1 !== type2) {
                  const params = JSON.stringify({type1: type1, type2: type2});
                  window.location = 'skp:get_apartment_volumes@' + encodeURIComponent(params);
                }
              });
            });
          }
          
          function validateOverlap(input) {
            console.log("Validating overlap for", input.id);
            let value = parseFloat(input.value) || 0;
            value = Math.min(1, Math.max(0, value));
            input.value = value.toFixed(2);
            
            const parts = input.id.split('_');
            if (parts.length === 3) {
              const type1 = parts[1];
              const type2 = parts[2];
              
              // If we have volumes for both types, calculate reverse overlap
              const vol1 = window.apartmentVolumes && window.apartmentVolumes[type1];
              const vol2 = window.apartmentVolumes && window.apartmentVolumes[type2];
              
              console.log(`Volumes for ${type1}-${type2}:`, vol1, vol2);
              
              if (vol1 !== undefined && vol2 !== undefined && vol2 > 0) {
                const reverse_overlap = (value * vol1) / vol2;
                const reverseInput = document.getElementById(`overlap_${type2}_${type1}`);
                if (reverseInput) {
                  const capped_value = Math.min(1, reverse_overlap);
                  reverseInput.value = capped_value.toFixed(2);
                  console.log(`Set reverse overlap ${type2}-${type1} to ${capped_value.toFixed(2)}`);
                }
              } else {
                // Request volumes if we don't have them
                const params = JSON.stringify({type1: type1, type2: type2});
                console.log("Requesting volumes for", type1, type2);
                window.location = 'skp:get_apartment_volumes@' + encodeURIComponent(params);
              }
            }
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

    def self.save_overlap_matrix(matrix_json)
      model = Sketchup.active_model
      begin
        overlap_matrix = JSON.parse(matrix_json) # This is a Hash
        # Convert the hash to a JSON string before saving
        model.set_attribute('apartment_type_data', 'overlap_matrix', JSON.dump(overlap_matrix))
    
        # Verify by retrieving and parsing again
        saved_matrix_str = model.get_attribute('apartment_type_data', 'overlap_matrix')
        if saved_matrix_str
          saved_matrix = JSON.parse(saved_matrix_str)
          puts "Verify saved matrix: #{saved_matrix.inspect}"
        else
          puts "Verify saved matrix: nil"
        end
      rescue => e
        puts "Error saving matrix: #{e.message}"
      end
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

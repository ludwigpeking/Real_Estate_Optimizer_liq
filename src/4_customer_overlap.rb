require 'sketchup.rb'
require 'json'

module Real_Estate_Optimizer
  module CustomerOverlap
    OVERLAP_MATRIX_KEY = 'overlap_matrix'
    OVERLAP_DATA_DICT = 'overlap_data'

 

    def self.ensure_overlap_matrix_exists(apartment_types)
      model = Sketchup.active_model
      overlap_data = model.attribute_dictionary(OVERLAP_DATA_DICT, true)

      existing_matrix_json = overlap_data[OVERLAP_MATRIX_KEY] || ''

      if existing_matrix_json.is_a?(String) && !existing_matrix_json.empty?
        begin
          existing_matrix = JSON.parse(existing_matrix_json)
          puts "Parsed existing overlap_matrix from JSON string."
        rescue JSON::ParserError
          puts "Failed to parse existing overlap_matrix JSON. Initializing a new matrix."
          existing_matrix = {}
        end
      else
        existing_matrix = {}
      end

      # Initialize or update the overlap matrix
      updated = false
      apartment_types.each do |type1|
        unless existing_matrix.key?(type1)
          existing_matrix[type1] = {}
          apartment_types.each do |type2|
            next if type1 == type2
            existing_matrix[type1][type2] = 0.0
          end
          puts "Added new type #{type1} to overlap_matrix."
          updated = true
        else
          apartment_types.each do |type2|
            next if type1 == type2
            unless existing_matrix[type1].key?(type2)
              existing_matrix[type1][type2] = 0.0
              puts "Added new type pair #{type1}-#{type2} to overlap_matrix."
              updated = true
            end
          end
        end
      end

      # Remove any types that no longer exist
      existing_matrix.keys.each do |type1|
        unless apartment_types.include?(type1)
          existing_matrix.delete(type1)
          puts "Removed type #{type1} from overlap_matrix."
          updated = true
        else
          existing_matrix[type1].keys.each do |type2|
            unless apartment_types.include?(type2)
              existing_matrix[type1].delete(type2)
              puts "Removed type pair #{type1}-#{type2} from overlap_matrix."
              updated = true
            end
          end
        end
      end

      if updated || existing_matrix.empty?
        overlap_data[OVERLAP_MATRIX_KEY] = existing_matrix.to_json
        puts "Initialized/Updated overlap_matrix."
      end
    end

    def self.show_dialog
      model = Sketchup.active_model
      apartment_type_names = model.get_attribute('apartment_type_data', 'apartment_type_names', [])
      apartment_type_names.uniq!
      apartment_type_names.sort_by! do |name|
        if match = name.match(/^(\d+)/)
          match[1].to_i
        else
          Float::INFINITY
        end
      end

      ensure_overlap_matrix_exists(apartment_type_names)

      dialog = UI::HtmlDialog.new(
        {
          :dialog_title => "Advanced Sales Overlap Calculator",
          :preferences_key => "com.example.sales_overlap_calculator",
          :scrollable => true,
          :resizable => true,
          :width => 800,  # Reduced from 900
          :height => 600, # Reduced from 700
          :left => 100,
          :top => 100,
          :min_width => 500,  # Reduced from 600
          :min_height => 400,
          :style => UI::HtmlDialog::STYLE_DIALOG
        }
      )
      
      html_content = <<-HTML
        <!DOCTYPE html>
        <html lang="en">
          <head>
            <meta charset="UTF-8" />
            <meta name="viewport" content="width=device-width, initial-scale=1" />
            <title>Advanced Sales Overlap Calculator</title>
          <style>
          body {
            font-family: Arial, sans-serif;
            margin: 15px;
            font-size: 14px;
          }
          h2 {
            font-size: 18px;
            margin-bottom: 15px;
          }
          h3 {
            font-size: 16px;
            color: #333;
            margin: 10px 0;
          }
          .input-section,
          .results-section {
            margin-bottom: 20px;
          }
          .grid-table {
            border-collapse: collapse;
            margin-bottom: 15px;
            width: 100%;
            font-size: 13px;
          }
          .grid-table th,
          .grid-table td {
            border: 1px solid #ddd;
            padding: 6px 8px;
            text-align: center;
          }
          .grid-table th {
            background-color: #f4f4f4;
            white-space: nowrap;
          }
          .grid-table input {
            width: 60px;
            padding: 2px 4px;
            text-align: center;
            font-size: 13px;
          }
          #salesScenariosTable {
            max-width: 800px;
          }
          #overlapTable {
            max-width: 800px;
          }
          .button {
            margin: 3px;
            padding: 4px 8px;
            color: white;
            border: none;
            cursor: pointer;
            font-size: 13px;
          }
          #saveBtn, #saveScenesBtn {
            background-color: #558855;
          }
          #saveBtn:hover, #saveScenesBtn:hover {
            background-color: #114411;
          }
          #recalcBtn {
            background-color: #555588;
          }
          #recalcBtn:hover {
            background-color: #117a8b;
          }
          .note {
            font-size: 13px;
            color: #666;
            margin: 10px 0;
          }
          .read-only {
            background-color: #f8f9fa;
          }
          .zero-volume {
            color: #dc3545;
            font-weight: bold;
          }
          p {
            margin: 8px 0;
            font-size: 13px;
          }
          .results-section {
            display: flex;
            flex-direction: column;
          }
          #results {
            font-size: 13px;
            line-height: 1.4;
          }
          .na-value {
            color: #999;
            font-style: italic;
          }
        </style>
          </head>
          <body>
            <h2>产品客户重叠测算 Customer Overlap Calculator</h2>

            <div class="input-section">
              <h3>1. 产品流速 Sales Scenarios</h3>
              <p> 假定每个产品独立销售，不考虑项目内其他产品的分流。 </p>
              <table class="grid-table" id="salesScenariosTable">
                <thead>
                  <tr>
                    <th rowspan="2">户型 Apartment Type</th>
                    <th colspan="2">量价关系1 Scene 1 保计划流速的量价关系</th>
                    <th colspan="2">量价关系2 Scene 2 保价格的量价关系（流速下降到计划一半）</th>
                  </tr>
                  <tr>
                    <th>月流速 Volume</th>
                    <th>单价 Price (元/平米)</th>
                    <th>月流速 Volume</th>
                    <th>单价 Price (元/平米)</th>
                  </tr>
                </thead>
                <tbody>
                  <!-- Dynamic Sales Scenarios -->
                </tbody>
              </table>
            </div>

            <div class="input-section">
              <h3>2. 客户重叠率估算 Overlap Rates</h3>
              <p>
              填写逻辑：假定没有左侧户型，左侧户型的客户中，可以接受上侧户型的比例，不小于0，不大于1。  
              Fill in the overlap rates between apartment types. Overlaps are
                <strong>asymmetrical</strong> (i.e., p<sub>ij</sub> can differ from p<sub>ji</sub>).
                Rates should be between <strong>0 and 1</strong>.
              </p>
              <table class="grid-table" id="overlapTable">
                <!-- Dynamic Overlap Table -->
              </table>
              <p class="note">
                <em>
                上半部分为可编辑区域，下半部分为自动计算区域。
                  Only the upper triangle is editable. Lower triangle rates are
                  automatically calculated based on the symmetry condition.
                </em>
              </p>

              <button id="saveBtn"> 保存 Save Overlap Rates</button>
              <button id="recalcBtn"> 重新计算调整后的总量 Recalculate Adjusted Sales</button>
            </div>

            <div class="results-section" id="resultsSection" style="display: none">
              <h3>3. 调整后的总量 Adjusted Sales Results</h3>
              <div id="results"></div>
            </div>

            <script>
              let apartmentTypes = [];
              let salesScenarios = {};
              let overlapMatrix = {};

              function initializeData(apartmentTypesData, salesScenariosData, overlapMatrixData) {
                console.log("Initializing data with:", apartmentTypesData, salesScenariosData, overlapMatrixData);
                apartmentTypes = apartmentTypesData;
                salesScenarios = salesScenariosData;
                overlapMatrix = overlapMatrixData;
        
                populateSalesScenariosTable();
                createOverlapTable();
                calculateAdjustedSales();
              }

              function getTypeColor(type) {
                // Check for commercial types first
                if (type.includes('商铺') || type.includes('办公') || type.includes('公寓')) {
                  return "hsl(0, 100%, 90%)";  // Red for commercial types
                }
                
                // Extract number using basic string operations
                let numberStr = '';
                for (let i = 0; i < type.length; i++) {
                  if (type[i] >= '0' && type[i] <= '9') {
                    numberStr += type[i];
                  }
                }
                
                if (numberStr === '') {
                  return "hsl(0, 0%, 95%)";  // Light gray for types without numbers
                }
                
                try {
                  const area = parseInt(numberStr);
                  if (isNaN(area)) {
                    return "hsl(0, 0%, 95%)";  // Light gray for invalid numbers
                  }
                  const hue = ((area - 50) * 2.5) % 360;
                  return `hsl(${hue}, 100%, 90%)`;
                } catch (e) {
                  console.error("Error calculating color for type:", type, e);
                  return "hsl(0, 0%, 95%)";  // Light gray as fallback
                }
              }
              function populateSalesScenariosTable() {
                const tbody = document.getElementById('salesScenariosTable').querySelector('tbody');
                tbody.innerHTML = '';
                
                apartmentTypes.forEach(type => {
                  const tr = document.createElement('tr');
                  
                  // Apartment Type Name
                  const tdName = document.createElement('td');
                  tdName.textContent = type;
                  tdName.style.backgroundColor = getTypeColor(type);
                  tdName.style.color = 'black';
                  tdName.style.textShadow = '0px 0px 3px white';
                  tr.appendChild(tdName);
                  
                  // Scene 1
                  let scene1 = { volume: 'NA', price: 'NA' };
                  if (salesScenarios[type] && salesScenarios[type].scenes && salesScenarios[type].scenes[0]) {
                    scene1 = salesScenarios[type].scenes[0];
                  }
                  
                  // Volume 1
                  const tdVolume1 = document.createElement('td');
                  const inputVolume1 = document.createElement('input');
                  inputVolume1.type = 'number';
                  inputVolume1.value = scene1.volume !== 'NA' ? scene1.volume : '';
                  inputVolume1.placeholder = 'NA';
                  inputVolume1.dataset.type = type;
                  inputVolume1.dataset.scene = '0';
                  inputVolume1.dataset.field = 'volume';
                  tdVolume1.appendChild(inputVolume1);
                  tr.appendChild(tdVolume1);
                  
                  // Price 1
                  const tdPrice1 = document.createElement('td');
                  const inputPrice1 = document.createElement('input');
                  inputPrice1.type = 'number';
                  inputPrice1.value = scene1.price !== 'NA' ? scene1.price : '';
                  inputPrice1.placeholder = 'NA';
                  inputPrice1.dataset.type = type;
                  inputPrice1.dataset.scene = '0';
                  inputPrice1.dataset.field = 'price';
                  tdPrice1.appendChild(inputPrice1);
                  tr.appendChild(tdPrice1);
                  
                  // Scene 2
                  let scene2 = { volume: 'NA', price: 'NA' };
                  if (salesScenarios[type] && salesScenarios[type].scenes && salesScenarios[type].scenes[1]) {
                    scene2 = salesScenarios[type].scenes[1];
                  }
                  
                  // Volume 2
                  const tdVolume2 = document.createElement('td');
                  const inputVolume2 = document.createElement('input');
                  inputVolume2.type = 'number';
                  inputVolume2.value = scene2.volume !== 'NA' ? scene2.volume : '';
                  inputVolume2.placeholder = 'NA';
                  inputVolume2.dataset.type = type;
                  inputVolume2.dataset.scene = '1';
                  inputVolume2.dataset.field = 'volume';
                  tdVolume2.appendChild(inputVolume2);
                  tr.appendChild(tdVolume2);
                  
                  // Price 2
                  const tdPrice2 = document.createElement('td');
                  const inputPrice2 = document.createElement('input');
                  inputPrice2.type = 'number';
                  inputPrice2.value = scene2.price !== 'NA' ? scene2.price : '';
                  inputPrice2.placeholder = 'NA';
                  inputPrice2.dataset.type = type;
                  inputPrice2.dataset.scene = '1';
                  inputPrice2.dataset.field = 'price';
                  tdPrice2.appendChild(inputPrice2);
                  tr.appendChild(tdPrice2);
                  
                  tbody.appendChild(tr);
                });
              
                // Add save button if it doesn't exist
                if (!document.getElementById('saveScenesBtn')) {
                  const saveButtonRow = document.createElement('div');
                  const saveScenesBtn = document.createElement('button');
                  saveScenesBtn.id = 'saveScenesBtn';
                  saveScenesBtn.className = 'button';
                  saveScenesBtn.textContent = '保存场景数据 Save Scenarios';
                  saveScenesBtn.addEventListener('click', function() {
                    const scenariosData = collectScenariosData();
                    console.log("Saving scenarios data:", JSON.stringify(scenariosData));
                    window.location = 'skp:save_scenarios@' + encodeURIComponent(JSON.stringify(scenariosData));
                  });
                  document.querySelector('.input-section').appendChild(saveScenesBtn);
                }
              }

              function collectScenariosData() {
                const scenariosData = {};
                
                apartmentTypes.forEach(type => {
                  scenariosData[type] = {
                    scenes: []
                  };
                  
                  // Collect data for both scenes
                  for (let sceneIndex = 0; sceneIndex < 2; sceneIndex++) {
                    const volumeInput = document.querySelector(`input[data-type="${type}"][data-scene="${sceneIndex}"][data-field="volume"]`);
                    const priceInput = document.querySelector(`input[data-type="${type}"][data-scene="${sceneIndex}"][data-field="price"]`);
                    
                    const volume = volumeInput.value ? parseFloat(volumeInput.value) : 'NA';
                    const price = priceInput.value ? parseFloat(priceInput.value) : 'NA';
                    
                    scenariosData[type].scenes.push({
                      volume: volume,
                      price: price
                    });
                  }
                });
                
                return scenariosData;
              }
              function createOverlapTable() {
                const table = document.getElementById("overlapTable");
                table.innerHTML = "";
              
                // Create table header
                const thead = document.createElement("thead");
                const headerRow = document.createElement("tr");
                const emptyHeader = document.createElement("th");
                headerRow.appendChild(emptyHeader);
              
                // Add colored headers to columns
                apartmentTypes.forEach(type => {
                  const th = document.createElement("th");
                  th.textContent = type;
                  th.style.backgroundColor = getTypeColor(type);
                  th.style.color = 'black';
                  th.style.textShadow = '0px 0px 3px white';
                  headerRow.appendChild(th);
                });
                thead.appendChild(headerRow);
                table.appendChild(thead);
              
                // Create table body
                const tbody = document.createElement("tbody");
                apartmentTypes.forEach((type1, i) => {
                  const row = document.createElement("tr");
                  const rowHeader = document.createElement("th");
                  rowHeader.textContent = type1;
                  // Color code the row headers
                  rowHeader.style.backgroundColor = getTypeColor(type1);
                  rowHeader.style.color = 'black';
                  rowHeader.style.textShadow = '0px 0px 3px white';
                  row.appendChild(rowHeader);
              
                  // Rest of the cell creation code remains the same
                  apartmentTypes.forEach((type2, j) => {
                    const cell = document.createElement("td");
                    if (i === j) {
                      cell.textContent = "—";
                    } else if (j < i) {
                      // Lower triangle (read-only)
                      const input = document.createElement("input");
                      input.type = "number";
                      input.id = `p_${i}_${j}`;
                      input.min = "0";
                      input.max = "1";
                      input.step = "0.01";
                      input.value = overlapMatrix[type1] && overlapMatrix[type1][type2] ? overlapMatrix[type1][type2] : 0;
                      input.disabled = true;
                      input.classList.add("read-only");
                      cell.appendChild(input);
                    } else {
                      // Upper triangle (editable)
                      const input = document.createElement("input");
                      input.type = "number";
                      input.id = `p_${i}_${j}`;
                      input.min = "0";
                      input.max = "1";
                      input.step = "0.01";
                      input.value = overlapMatrix[type1] && overlapMatrix[type1][type2] ? overlapMatrix[type1][type2] : 0;
              
                      input.addEventListener("input", () => {
                        console.log(`Input changed: p_${type1}_${type2} = ${input.value}`);
                        enforceOverlapConstraints(i, j);
                      });
              
                      cell.appendChild(input);
                    }
                    row.appendChild(cell);
                  });
                  tbody.appendChild(row);
                });
                table.appendChild(tbody);
              }

              function enforceOverlapConstraints(i, j) {
                const type1 = apartmentTypes[i];  // Left element (row)
                const type2 = apartmentTypes[j];  // Upper element (column)
                const p_ij_input = document.getElementById(`p_${i}_${j}`);
                const p_ji_input = document.getElementById(`p_${j}_${i}`);
              
                // Get volumes from first scene
                const D_i = salesScenarios[type1] && salesScenarios[type1].scenes && 
                            salesScenarios[type1].scenes[0] && 
                            salesScenarios[type1].scenes[0].volume !== 'NA' ? 
                            salesScenarios[type1].scenes[0].volume : 0;
              
                const D_j = salesScenarios[type2] && salesScenarios[type2].scenes && 
                            salesScenarios[type2].scenes[0] && 
                            salesScenarios[type2].scenes[0].volume !== 'NA' ? 
                            salesScenarios[type2].scenes[0].volume : 0;
              
                // Always cap at 100% regardless of volumes
                let max_p_ij = 1;
                if (D_i === 0) {
                  max_p_ij = 0;
                }
              
                if (parseFloat(p_ij_input.value) > max_p_ij) {
                  alert(`Overlap rate p_${type1}${type2} cannot exceed 100%.`);
                  p_ij_input.value = max_p_ij.toFixed(4);
                  console.log(`Adjusted p_${type1}_${type2} to max_p_ij: ${max_p_ij}`);
                }
              
                let p_ij = parseFloat(p_ij_input.value) || 0;
              
                // Calculate symmetric value for lower triangle
                if (D_j !== 0) {
                  let p_ji = (p_ij * D_i) / D_j;
                  p_ji = Math.min(1, p_ji).toFixed(4);
                  p_ji_input.value = p_ji;
                  console.log(`Calculated p_${type2}_${type1} = ${p_ji}`);
              
                  // Update overlapMatrix with new values
                  overlapMatrix[type1][type2] = p_ij;
                  overlapMatrix[type2][type1] = parseFloat(p_ji);
                  console.log(`Updated overlapMatrix: ${type1}->${type2} = ${p_ij}, ${type2}->${type1} = ${p_ji}`);
                } else {
                  p_ji_input.value = "0.0000";
                  console.log(`Set p_${type2}_${type1} to 0.0000 due to D_j = 0`);
              
                  // Update overlapMatrix with new values
                  overlapMatrix[type1][type2] = p_ij;
                  overlapMatrix[type2][type1] = 0;
                  console.log(`Updated overlapMatrix: ${type1}->${type2} = ${p_ij}, ${type2}->${type1} = 0`);
                }
              
                console.log("Current overlapMatrix after enforcing constraints:", JSON.stringify(overlapMatrix));
              }

              function collectOverlapMatrix() {
                const matrix = {};
                apartmentTypes.forEach((type1, i) => {
                  if (!matrix[type1]) {
                    matrix[type1] = {};
                  }
                  apartmentTypes.forEach((type2, j) => {
                    if (type1 === type2) return;
                    if (j > i) {
                      const input = document.getElementById(`p_${i}_${j}`);
                      const p_ij = parseFloat(input.value) || 0;
                      matrix[type1][type2] = p_ij;
                      console.log(`Collected p_${type1}_${type2} = ${p_ij}`);
              
                      // Calculate p_ji based on p_ij and demands
                      const D_i = (salesScenarios[type1] && 
                                  salesScenarios[type1].scenes && 
                                  salesScenarios[type1].scenes[0] &&
                                  salesScenarios[type1].scenes[0].volume !== 'NA') ? 
                                  salesScenarios[type1].scenes[0].volume : 0;
                                  
                      const D_j = (salesScenarios[type2] && 
                                  salesScenarios[type2].scenes && 
                                  salesScenarios[type2].scenes[0] &&
                                  salesScenarios[type2].scenes[0].volume !== 'NA') ? 
                                  salesScenarios[type2].scenes[0].volume : 0;
                      
                      let p_ji = 0;
                      if (D_j !== 0) {
                        p_ji = Math.min(1, (p_ij * D_i) / D_j);
                        p_ji = parseFloat(p_ji.toFixed(4));
                      }
                      if (!matrix[type2]) {
                        matrix[type2] = {};
                      }
                      matrix[type2][type1] = p_ji;
                      console.log(`Calculated p_${type2}_${type1} = ${p_ji}`);
                    }
                  });
                });
                console.log("Final collected overlap matrix:", JSON.stringify(matrix));
                return matrix;
              }
              function calculateAdjustedSales() {
                console.log("Calculating adjusted sales with overlapMatrix:", JSON.stringify(overlapMatrix));
                const finalSales = {};
                
                // First get all standalone volumes
                const volumes = {};
                apartmentTypes.forEach(type => {
                  volumes[type] = salesScenarios[type] && 
                                 salesScenarios[type].scenes && 
                                 salesScenarios[type].scenes[0] && 
                                 salesScenarios[type].scenes[0].volume !== 'NA' ? 
                                 salesScenarios[type].scenes[0].volume : 0;
                });
              
                // Calculate final sales for each type
                apartmentTypes.forEach(type => {
                  const baseVolume = volumes[type];
                  let finalSaleVolume = baseVolume;
                  
                  // Calculate adjustments from overlaps with other types
                  apartmentTypes.forEach(otherType => {
                    if (type === otherType) return;
                    
                    // Get the overlap rate from this type to other type
                    const overlapRate = overlapMatrix[type] && overlapMatrix[type][otherType] ? 
                                       overlapMatrix[type][otherType] : 0;
                    
                    // Calculate total shared customers from this type
                    const sharedCustomers = baseVolume * overlapRate;
                    
                    if (volumes[type] + volumes[otherType] > 0) {
                      // Split shared customers based on relative volumes
                      const lostToOther = sharedCustomers * (volumes[otherType] / (volumes[type] + volumes[otherType]));
                      finalSaleVolume -= lostToOther;
                    }
                  });
                  
                  finalSales[type] = Math.max(0, finalSaleVolume).toFixed(2);
                  console.log(`${type}: Base volume ${baseVolume}, Final sales ${finalSales[type]}`);
                });
              
                // Display Results
                let totalSales = 0;
                let resultsHTML = `<strong>调整后的总月销量（套/月）Total Adjusted Sales:</strong> `;
                
                // Calculate total
                apartmentTypes.forEach(type => {
                  totalSales += parseFloat(finalSales[type]);
                });
                
                // Generate results HTML
                resultsHTML += `${totalSales.toFixed(2)} units/month<br><strong>销量分布 Sales Distribution:</strong><br>`;
                apartmentTypes.forEach(type => {
                  const baseVolume = volumes[type];
                  const finalVolume = parseFloat(finalSales[type]);
                  const reductionPercentage = baseVolume > 0 ? 
                    ((baseVolume - finalVolume) / baseVolume * 100).toFixed(1) : 0;
                  
                  resultsHTML += `- ${type}: ${finalSales[type]} units/month (原始: ${baseVolume}, 分流: ${reductionPercentage}%)<br>`;
                });
              
                console.log("Adjusted Sales Results:", resultsHTML);
                document.getElementById("results").innerHTML = resultsHTML;
                document.getElementById("resultsSection").style.display = "block";
              }

              document.getElementById('saveBtn').addEventListener('click', function () {
                const matrix = collectOverlapMatrix();
                console.log("Saving overlap matrix:", JSON.stringify(matrix));
                window.location = 'skp:save_overlap_matrix@' + encodeURIComponent(JSON.stringify(matrix));
                overlapMatrix = matrix; // Update the overlapMatrix variable
                calculateAdjustedSales();
              });

              document.getElementById('recalcBtn').addEventListener('click', function () {
                console.log("Recalculating adjusted sales.");
                calculateAdjustedSales();
              });

              window.onload = function() {
                // Request data from Ruby
                console.log("Dialog loaded. Requesting overlap data.");
                window.location = 'skp:get_overlap_data';
              }

              function receiveData(apartmentTypesData, salesScenariosData, overlapMatrixData) {
                console.log("Received data from Ruby:", apartmentTypesData, salesScenariosData, overlapMatrixData);
                apartmentTypes = apartmentTypesData;
                salesScenarios = salesScenariosData;
                overlapMatrix = overlapMatrixData;

                populateSalesScenariosTable();
                createOverlapTable();
                calculateAdjustedSales();
              }

            </script>
          </body>
        </html>
      HTML

      dialog.set_html(html_content)

      dialog.add_action_callback("save_scenarios") do |action_context, scenarios_json|
        begin
          scenarios_data = JSON.parse(scenarios_json)
          model = Sketchup.active_model
          
          scenarios_data.each do |type_name, type_data|
            # Get existing apartment data
            apartment_data_json = model.get_attribute('apartment_type_data', type_name, '{}')
            apartment_data = JSON.parse(apartment_data_json)
            
            # Update the sales scenes
            apartment_data['sales_scenes'] = type_data['scenes'].map do |scene|
              {
                'volumn' => scene['volume'] == 'NA' ? nil : scene['volume'],
                'price' => scene['price'] == 'NA' ? nil : scene['price']
              }
            end
            
            # Save back to model
            model.set_attribute('apartment_type_data', type_name, apartment_data.to_json)
          end
          
          UI.messagebox("场景数据已保存 Scenarios data has been saved successfully.")
        rescue JSON::ParserError => e
          puts "Failed to parse scenarios JSON: #{e.message}"
          UI.messagebox("保存场景数据失败 Failed to save scenarios data.")
        end
      end

      dialog.add_action_callback("get_overlap_data") do |action_context|
        model = Sketchup.active_model
        apartment_type_names = model.get_attribute('apartment_type_data', 'apartment_type_names', [])
        apartment_type_names.uniq!
        apartment_type_names.sort_by! do |name|
          if match = name.match(/^(\d+)/)
            match[1].to_i
          else
            Float::INFINITY
          end
        end
      
        puts "Retrieving overlap data for apartment types: #{apartment_type_names.inspect}"
      
        # Gather sales scenarios
        sales_scenarios = {}
        apartment_type_names.each do |type|
          apartment_data_json = model.get_attribute('apartment_type_data', type, '{}')
          apartment_data = JSON.parse(apartment_data_json) rescue {}
          
          sales_scenarios[type] = {
            scenes: []
          }
          
          if apartment_data['sales_scenes']
            apartment_data['sales_scenes'].each do |scene|
              sales_scenarios[type][:scenes] << {
                volume: scene['volumn'] || 'NA',
                price: scene['price'] || 'NA'
              }
            end
          end
          
          # Ensure we always have 2 scenes, fill with NA if missing
          while sales_scenarios[type][:scenes].length < 2
            sales_scenarios[type][:scenes] << {
              volume: 'NA',
              price: 'NA'
            }
          end
        end
      
        # Get overlap matrix data
        overlap_data = model.attribute_dictionaries[OVERLAP_DATA_DICT]
        overlap_matrix_json = overlap_data ? overlap_data[OVERLAP_MATRIX_KEY] : ''
        overlap_matrix = {}
        if overlap_matrix_json && !overlap_matrix_json.empty?
          overlap_matrix = JSON.parse(overlap_matrix_json) rescue {}
          puts "Retrieved overlap_matrix: #{overlap_matrix.inspect}"
        else
          puts "No existing overlap_matrix found. Using empty matrix."
        end
      
        # Send data to JS
        dialog.execute_script("initializeData(#{apartment_type_names.to_json}, #{sales_scenarios.to_json}, #{overlap_matrix.to_json})")
      end
      
      # Action callback to save overlap matrix
      dialog.add_action_callback("save_overlap_matrix") do |action_context, matrix_json|
        begin
          matrix = JSON.parse(matrix_json)
          model = Sketchup.active_model
          overlap_data = model.attribute_dictionary(OVERLAP_DATA_DICT, true)
          overlap_data[OVERLAP_MATRIX_KEY] = matrix.to_json
          puts "Saved overlap_matrix: #{matrix.inspect}"

          # Verify by retrieving it back
          saved_matrix_json = overlap_data[OVERLAP_MATRIX_KEY]
          saved_matrix = JSON.parse(saved_matrix_json) rescue {}
          puts "Verified saved_overlap_matrix: #{saved_matrix.inspect}"

          UI.messagebox("客户重叠矩阵成功保存 Overlap matrix has been saved successfully.")
        rescue JSON::ParserError => e
          puts "Failed to parse overlap_matrix JSON: #{e.message}"
          UI.messagebox("客户重叠矩阵保存失败 Failed to parse overlap matrix JSON.")
        end
      end

      # Show the dialog
      dialog.show
    end
  end
end


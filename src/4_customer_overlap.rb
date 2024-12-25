require 'sketchup.rb'
require 'json'

module Real_Estate_Optimizer
  module CustomerOverlap
    OVERLAP_MATRIX_KEY = 'overlap_matrix'
    OVERLAP_DATA_DICT = 'overlap_data'

    def self.ensure_overlap_matrix_exists(apartment_types)
      model = Sketchup.active_model
      overlap_data = model.attribute_dictionaries[OVERLAP_DATA_DICT] || model.attribute_dictionaries.add(OVERLAP_DATA_DICT)
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
      apartment_type_names.sort!

      ensure_overlap_matrix_exists(apartment_type_names)

      dialog = UI::HtmlDialog.new(
        {
          :dialog_title => "Advanced Sales Overlap Calculator",
          :preferences_key => "com.example.sales_overlap_calculator",
          :scrollable => true,
          :resizable => true,
          :width => 900,
          :height => 700,
          :left => 100,
          :top => 100,
          :min_width => 600,
          :min_height => 400,
          :max_width => 1200,
          :max_height => 800,
          :style => UI::HtmlDialog::STYLE_DIALOG
        }
      )

      html_content = <<-HTML
        <!DOCTYPE html>
        <html lang="en">
          <head>
            <meta charset="UTF-8" />
            <link rel="stylesheet" type="text/css" href="file:///#{File.join(__dir__, 'style.css')}">
            <meta name="viewport" content="width=device-width, initial-scale=1" />
            <title>Advanced Sales Overlap Calculator</title>
            <style>
              body {
                font-family: Arial, sans-serif;
                margin: 20px;
              }
              h1,
              h3 {
                color: #333;
              }
              .input-section,
              .results-section {
                margin-bottom: 30px;
              }
              .grid-table {
                border-collapse: collapse;
                margin-bottom: 20px;
                width: 100%;
              }
              .grid-table th,
              .grid-table td {
                border: 1px solid #ccc;
                padding: 8px 12px;
                text-align: center;
              }
              .grid-table th {
                background-color: #f4f4f4;
              }
              #saveBtn, #recalcBtn {
                margin: 5px;
                padding: 5px 10px;
                background-color: #558855;
                color: white;
                border: none;
                cursor: pointer;
                font-size: 13px;
              }
              #saveBtn:hover {
                background-color: #114411;
              }
              #recalcBtn {
                background-color: #555588;
              }
              #recalcBtn:hover {
                background-color: #117a8b;
              }
              .note {
                font-size: 14px;
                color: #555;
                margin-bottom: 20px;
              }
              .read-only {
                background-color: #e9ecef;
              }
              .zero-volume {
                color: red;
                font-weight: bold;
              }
              .results-section {
                display: flex;
                flex-direction: column;
                align-items: center;
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
                    <th>户型 Apartment Type</th>
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

              // Initialize the dialog with data from Ruby
              function initializeData(apartmentTypesData, salesScenariosData, overlapMatrixData) {
                console.log("Initializing data with:", apartmentTypesData, salesScenariosData, overlapMatrixData);
                apartmentTypes = apartmentTypesData;
                salesScenarios = salesScenariosData;
                overlapMatrix = overlapMatrixData;

                populateSalesScenariosTable();
                createOverlapTable();
                calculateAdjustedSales();
              }

              function populateSalesScenariosTable() {
                const tbody = document.getElementById('salesScenariosTable').querySelector('tbody');
                tbody.innerHTML = '';
                apartmentTypes.forEach(type => {
                  const tr = document.createElement('tr');

                  // Apartment Type Name
                  const tdName = document.createElement('td');
                  tdName.textContent = type;
                  tr.appendChild(tdName);

                  // Volume
                  const tdVolume = document.createElement('td');
                  const volume = salesScenarios[type] && salesScenarios[type].volume ? salesScenarios[type].volume : 0;
                  if (volume === 0) {
                    tdVolume.innerHTML = '<span class="zero-volume">0</span>';
                  } else {
                    tdVolume.textContent = volume;
                  }
                  tr.appendChild(tdVolume);

                  // Price
                  const tdPrice = document.createElement('td');
                  const price = salesScenarios[type] && salesScenarios[type].price ? salesScenarios[type].price : 0;
                  tdPrice.textContent = price;
                  tr.appendChild(tdPrice);

                  tbody.appendChild(tr);
                });
              }

              function createOverlapTable() {
                const table = document.getElementById("overlapTable");
                table.innerHTML = "";

                // Create table header
                const thead = document.createElement("thead");
                const headerRow = document.createElement("tr");
                const emptyHeader = document.createElement("th");
                headerRow.appendChild(emptyHeader);

                apartmentTypes.forEach(type => {
                  const th = document.createElement("th");
                  th.textContent = type;
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
                  row.appendChild(rowHeader);

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
                      // Corrected Line: Set p_ji from overlapMatrix[type2][type1]
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
                const type1 = apartmentTypes[i];
                const type2 = apartmentTypes[j];
                const p_ij_input = document.getElementById(`p_${i}_${j}`);
                const p_ji_input = document.getElementById(`p_${j}_${i}`);

                const D_i = salesScenarios[type1] && salesScenarios[type1].volume ? salesScenarios[type1].volume : 0;
                const D_j = salesScenarios[type2] && salesScenarios[type2].volume ? salesScenarios[type2].volume : 0;

                let max_p_ij = 1;
                if (D_i !== 0) {
                  max_p_ij = Math.min(1, D_j / D_i);
                } else {
                  max_p_ij = 0;
                }

                if (parseFloat(p_ij_input.value) > max_p_ij) {
                  alert(`Overlap rate p_${type1}${type2} cannot exceed ${max_p_ij.toFixed(4)} based on the demands.`);
                  p_ij_input.value = max_p_ij.toFixed(4);
                  console.log(`Adjusted p_${type1}_${type2} to max_p_ij: ${max_p_ij}`);
                }

                let p_ij = parseFloat(p_ij_input.value) || 0;

                if (D_j !== 0) {
                  let p_ji = (p_ij * D_i) / D_j;
                  p_ji = Math.min(1, p_ji).toFixed(4);
                  p_ji_input.value = p_ji;
                  console.log(`Calculated p_${type2}_${type1} = ${p_ji}`);

                  // **Update overlapMatrix with new values**
                  overlapMatrix[type1][type2] = p_ij;
                  overlapMatrix[type2][type1] = parseFloat(p_ji);
                  console.log(`Updated overlapMatrix: ${type1}->${type2} = ${p_ij}, ${type2}->${type1} = ${p_ji}`);
                } else {
                  p_ji_input.value = "0.0000";
                  console.log(`Set p_${type2}_${type1} to 0.0000 due to D_j = 0`);

                  // **Update overlapMatrix with new values**
                  overlapMatrix[type1][type2] = p_ij;
                  overlapMatrix[type2][type1] = 0;
                  console.log(`Updated overlapMatrix: ${type1}->${type2} = ${p_ij}, ${type2}->${type1} = 0`);
                }

                // Debug: Log the entire overlapMatrix after constraints enforcement
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
                      const D_i = salesScenarios[type1] && salesScenarios[type1].volume ? salesScenarios[type1].volume : 0;
                      const D_j = salesScenarios[type2] && salesScenarios[type2].volume ? salesScenarios[type2].volume : 0;
                      let p_ji = 0;
                      if (D_j !== 0) {
                        p_ji = Math.min(1, (p_ij * D_i) / D_j).toFixed(4);
                      }
                      if (!matrix[type2]) {
                        matrix[type2] = {};
                      }
                      matrix[type2][type1] = parseFloat(p_ji);
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
                apartmentTypes.forEach((type, i) => {
                  const D_i = salesScenarios[type] && salesScenarios[type].volume ? salesScenarios[type].volume : 0;
                  let adjustment = 0;
                  apartmentTypes.forEach((otherType, j) => {
                    if (type === otherType) return;
                    const D_j = salesScenarios[otherType] && salesScenarios[otherType].volume ? salesScenarios[otherType].volume : 0;
                    const p_ij = overlapMatrix[type] && overlapMatrix[type][otherType] ? overlapMatrix[type][otherType] : 0;
                    console.log(`Using p_ij=${p_ij} for ${type} due to ${otherType}`);
                    if (D_i + D_j === 0) return;
                    adjustment += (p_ij * (D_j * D_i)) / (D_i + D_j);
                    console.log(`Adjustment for ${type} due to ${otherType}: p_ij=${p_ij}, D_i=${D_i}, D_j=${D_j}, adjustment += ${(p_ij * (D_j * D_i)) / (D_i + D_j)}`);
                  });
                  const sales = D_i - adjustment;
                  finalSales[type] = sales >= 0 ? sales.toFixed(2) : 0;
                  console.log(`Calculated final sales for ${type}: ${finalSales[type]}`);
                });

                // Calculate total adjusted sales
                let totalSales = 0;
                let resultsHTML = `<strong>调整后的总月销量（套/月）Total Adjusted Sales:</strong> `;
                apartmentTypes.forEach(type => {
                  totalSales += parseFloat(finalSales[type]);
                });
                resultsHTML += `${totalSales.toFixed(2)} units/month<br><strong>销量分布 Sales Distribution:</strong><br>`;
                apartmentTypes.forEach(type => {
                  resultsHTML += `- ${type}: ${finalSales[type]} units/month<br>`;
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

      # Action callback to receive data
      dialog.add_action_callback("get_overlap_data") do |action_context|
        model = Sketchup.active_model
        apartment_type_names = model.get_attribute('apartment_type_data', 'apartment_type_names', [])
        apartment_type_names.uniq!
        apartment_type_names.sort!
      
        puts "Retrieving overlap data for apartment types: #{apartment_type_names.inspect}"
      
        # Gather sales scenarios
        sales_scenarios = {}
        apartment_type_names.each do |type|
          apartment_data_json = model.get_attribute('apartment_type_data', type, '{}')
          apartment_data = JSON.parse(apartment_data_json) rescue {}
          if apartment_data['sales_scenes'] && !apartment_data['sales_scenes'].empty?
            # Use only the first sales scene
            first_scene = apartment_data['sales_scenes'].first
            sales_scenarios[type] = {
              volume: first_scene['volumn'].to_i,
              price: first_scene['price'].to_f
            }
            puts "Apartment Type: #{type}, Volume: #{sales_scenarios[type][:volume]}, Price: #{sales_scenarios[type][:price]}"
          else
            sales_scenarios[type] = {
              volume: 0,
              price: 0
            }
            puts "Apartment Type: #{type} has no sales scenarios. Volume and Price set to 0."
          end
        end
      
        # Rest of the code remains the same...
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
          overlap_data = model.attribute_dictionaries[OVERLAP_DATA_DICT] || model.attribute_dictionaries.add(OVERLAP_DATA_DICT)
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


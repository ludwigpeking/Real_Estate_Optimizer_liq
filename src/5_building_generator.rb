require 'sketchup.rb'
require 'json'
require_relative '5_building_type_component'

# Ruby code starts here
module Real_Estate_Optimizer
    module BuildingGenerator
      BUILDING_TYPE_LIST_KEY = 'building_type_names'
      def self.show_dialog
        dialog = UI::HtmlDialog.new(
          {
            :dialog_title => "楼型管理 Building Type Management",
            :preferences_key => "com.example.building_generator",
            :scrollable => true,
            :resizable => true,
            :width => 800,
            :height => 600,
            :left => 100,
            :top => 100,
            :min_width => 600,
            :min_height => 400,
            :style => UI::HtmlDialog::STYLE_DIALOG
          }
        )

        html_content = <<-HTML
        <!DOCTYPE html>
        <html>
            <head>
                <meta charset="UTF-8">
                <link rel="stylesheet" type="text/css" href="file:///#{File.join(__dir__, 'style.css')}">

            <script>
                function addFloorType() {
                    const container = document.getElementById('floorTypesContainer');
                    const floorTypeId = Date.now(); // It seems problematic to use Date.now() as an ID, the added floor types should be all the same as the default
                    const floorTypeHtml = `
                        <div id="floorType${floorTypeId}" class="floor-type">
                            <h4>楼层类型 Floor Type</h4>
                            <label>楼层数量 Number of Floors: <input type="number" id="numberFloors${floorTypeId}" value="1" onchange="updateBuildingTypeName()"></label>
                            <label>层高 Level Height (m): <input type="number" id="levelHeight${floorTypeId}" value="3" step="0.1"></label>
                            <div id="apartmentTypesContainer${floorTypeId}"></div> 
                            <button onclick="addApartmentType(${floorTypeId})">添加户型 Add Apartment Type</button>
                            <button onclick="removeFloorType(${floorTypeId})">删除楼层类型 Remove Floor Type</button>
                        </div>
                    `;
                    container.insertAdjacentHTML('beforeend', floorTypeHtml);
                    updateBuildingTypeName(); //this is ok
                }
                
                function addApartmentType(floorTypeId) {
                    const container = document.getElementById(`apartmentTypesContainer${floorTypeId}`);
                    const apartmentTypeId = Date.now(); //this is not understood
                    const apartmentTypeHtml = `
                        <div id="apartmentType${apartmentTypeId}" class="apartment-type">
                            <label>户型名称 Apartment Name: 
                                <select id="apartmentName${apartmentTypeId}" onchange="updateBuildingTypeName()">
                                    <option value="">选择户型 Select an apartment type</option>
                                </select>
                            </label>
                            <label>X 坐标 X Position: <input type="number" id="apartmentX${apartmentTypeId}" value="0" step="0.1"></label>
                            <label>Y 坐标 Y Position: <input type="number" id="apartmentY${apartmentTypeId}" value="0" step="0.1"></label>
                            <button onclick="removeApartmentType(${apartmentTypeId})">删除 Remove</button>
                        </div>
                    `;
                    container.insertAdjacentHTML('beforeend', apartmentTypeHtml);
                    populateApartmentOptions();
                    updateBuildingTypeName(); //this is ok
                }

                function removeFloorType(floorTypeId) {
                    const floorType = document.getElementById(`floorType${floorTypeId}`);
                    floorType.remove();
                    updateBuildingTypeName(); //this is ok
                }

                function removeApartmentType(apartmentTypeId) {
                    const apartmentType = document.getElementById(`apartmentType${apartmentTypeId}`);
                    apartmentType.remove();
                    updateBuildingTypeName(); //this is ok
                }

                function populateApartmentOptions() {
                    window.location = 'skp:populate_all_apartment_types';
                }

               

                function updateBuildingTypeName() {
                    let floorTypes = document.querySelectorAll('.floor-type');
                    console.log('Floor Types:', floorTypes); // For debugging
                    let apartmentAreas = {};
                    let totalFloors = 0;

                    floorTypes.forEach(function(floorType) {
                        let numberFloorsElement = floorType.querySelector('input[id^="numberFloors"]'); // The list of the number of floors DOM
                        let numberOfFloors = numberFloorsElement ? parseInt(numberFloorsElement.value) || 0 : 0;
                        console.log('Number of Floors:', numberOfFloors); // For debugging
                        totalFloors += numberOfFloors;

                        let apartments = floorType.querySelectorAll('select[id^="apartmentName"]'); // The list of the apartment name DOMs
                        apartments.forEach(function(apartment) {
                            if (apartment && apartment.value) {
                                console.log('Apartment Value:', apartment.value); // For debugging
                                let area = extractFirstNumber(apartment.value);
                                console.log('Extracted Area:', area); // For debugging
                                if (area) {
                                    apartmentAreas[area] = (apartmentAreas[area] || 0) + numberOfFloors;
                                }
                            }
                        });
                    });
                    console.log('apartmentAreas', apartmentAreas); // For debugging

                    let sortedAreas = [];
                    for (var area in apartmentAreas) {
                        if (apartmentAreas.hasOwnProperty(area)) {
                            sortedAreas.push([area, apartmentAreas[area]]);
                        }
                    }
                    sortedAreas.sort(function(a, b) {
                        return b[1] - a[1];
                    });
                    sortedAreas = sortedAreas.map(function(entry) {
                        return entry[0];
                    });

                    let buildingTypeName = sortedAreas.join('+') + ' ' + totalFloors + '层';
                    console.log('sortedAreas', sortedAreas); // For debugging
                    console.log('name', buildingTypeName); // For debugging
                    document.getElementById('buildingTypeName').textContent = buildingTypeName;
                }

                function extractFirstNumber(input) {
                    let result = '';
                    for (let i = 0; i < input.length; i++) {
                        if (!isNaN(input[i]) && input[i] !== ' ') {
                            result += input[i];
                        } else if (result.length > 0) {
                            break; // Stop collecting digits once a non-digit character is encountered after the first number
                        }
                    }
                    return result.length > 0 ? result : null;
                }





                function populatePaymentTable(tableId, data) {
                    console.log(`Populating table ${tableId} with data:`, data);
                    const table = document.getElementById(tableId);
                    const inputs = table.querySelectorAll('input');
                    
                    inputs.forEach((input, index) => {
                        input.value = data[index] || 0;
                    });
                    
                    validatePaymentSum(tableId);
                }

                function verifyAllCellsPopulated() {
                    ['supervisionFundReleaseSchedule', 'constructionPaymentSchedule'].forEach(tableId => {
                        const table = document.getElementById(tableId);
                        const inputs = table.querySelectorAll('input');
                        const values = Array.from(inputs).map(input => parseFloat(input.value) || 0);
                        console.log(`Verified ${tableId} values:`, values);
                    });
                }

                function validatePaymentSum(tableId) {
                    console.log(`Validating sum for table ${tableId}`);
                    const inputs = document.querySelectorAll(`#${tableId} input`);
                    let sum = Array.from(inputs).reduce((acc, input) => acc + Number(input.value), 0);
                    document.getElementById(`${tableId}_sum`).textContent = sum.toFixed(2);
                    document.getElementById(`${tableId}_error`).style.display = Math.abs(sum - 1) < 0.0001 ? 'none' : 'block';
                }

                

                function submitForm() {
                  let formData = {
                    name: document.getElementById('buildingTypeName') ? document.getElementById('buildingTypeName').textContent : '',
                    floorTypes: [],
                    standardConstructionTime: {},
                    supervisionFundReleaseSchedule: [],
                    constructionPaymentSchedule: [],
                    total_area: parseFloat(document.getElementById('totalArea').textContent) || 0,
                    footprint_area: parseFloat(document.getElementById('footprintArea').textContent) || 0
                  };

                  // Standard Construction Time
                  ['monthsFromConstructionInitToZeroLevel', 'monthsFromZeroLevelToRoofLevel', 
                  'monthsFromRoofLevelToDelivery', 'monthsFromConstructionInitToSale', 'supervisionFundPercentage'].forEach(function(id) {
                    let element = document.getElementById(id);
                    formData.standardConstructionTime[id] = element ? parseFloat(element.value) : 0;
                  });

                  // Floor Types
                  document.querySelectorAll('.floor-type').forEach(function(floorType) {
                    let numberFloorsElement = floorType.querySelector('input[id^="numberFloors"]');
                    let levelHeightElement = floorType.querySelector('input[id^="levelHeight"]');
                    let floorTypeData = {
                      number: numberFloorsElement ? parseInt(numberFloorsElement.value) || 0 : 0,
                      levelHeight: levelHeightElement ? parseFloat(levelHeightElement.value) || 0 : 0,
                      apartmentTypes: []
                    };

                    floorType.querySelectorAll('.apartment-type').forEach(function(apartmentType) {
                      let nameElement = apartmentType.querySelector('select[id^="apartmentName"]');
                      let xElement = apartmentType.querySelector('input[id^="apartmentX"]');
                      let yElement = apartmentType.querySelector('input[id^="apartmentY"]');
                      floorTypeData.apartmentTypes.push({
                        name: nameElement ? nameElement.value : '',
                        x: xElement ? parseFloat(xElement.value) || 0 : 0,
                        y: yElement ? parseFloat(yElement.value) || 0 : 0
                      });
                    });

                    formData.floorTypes.push(floorTypeData);
                  });

                  // Payment Schedules
                  formData.supervisionFundReleaseSchedule = getPaymentData('supervisionFundReleaseSchedule');
                  formData.constructionPaymentSchedule = getPaymentData('constructionPaymentSchedule');

                  console.log('Supervision Fund Release Schedule:', formData.supervisionFundReleaseSchedule);
                  console.log('Construction Payment Schedule:', formData.constructionPaymentSchedule);
                  console.log('Form Data:', formData); // For debugging

                  window.location = 'skp:save_building_type@' + encodeURIComponent(JSON.stringify(formData));
                }

                function getPaymentData(tableId) {
                  return Array.from(document.querySelectorAll(`#${tableId} input`)).map(input => parseFloat(input.value) || 0);
                }

                function loadBuildingType() {
                    const select = document.getElementById('savedBuildingTypes');
                    const selectedName = select.value;
                    if (selectedName) {
                        window.location = 'skp:load_building_type@' + encodeURIComponent(selectedName);
                    }
                }

                function deleteBuildingType() {
                    const select = document.getElementById('savedBuildingTypes');
                    const selectedName = select.value;
                    if (selectedName && confirm('Are you sure you want to delete this building type?')) {
                        window.location = 'skp:delete_building_type@' + encodeURIComponent(selectedName);
                    }
                }

                window.onload = function() {
                    createScheduleTables();
                    populateApartmentOptions();
                    loadSavedBuildingTypes();
                }

                function loadSavedBuildingTypes() {
                    window.location = 'skp:get_saved_building_types';
                }

                function createScheduleTables() {
                  const supervisionTable = document.getElementById('supervisionFundReleaseSchedule');
                  const constructionTable = document.getElementById('constructionPaymentSchedule');
                  const defaultSupervisionSchedule = #{Real_Estate_Optimizer::DefaultValues::PROJECT_DEFAULTS[:inputs][:supervision_fund_release_schedule].to_json};
                  const defaultConstructionSchedule = #{Real_Estate_Optimizer::DefaultValues::PROJECT_DEFAULTS[:inputs][:construction_payment_schedule].to_json};
                  
                  [
                    { table: supervisionTable, defaultSchedule: defaultSupervisionSchedule, id: 'supervisionFundReleaseSchedule' },
                    { table: constructionTable, defaultSchedule: defaultConstructionSchedule, id: 'constructionPaymentSchedule' }
                  ].forEach(({ table, defaultSchedule, id }) => {
                    table.innerHTML = '';
                    
                    for (let i = 0; i < 6; i++) {
                      let row = table.insertRow();
                      for (let j = 0; j < 12; j++) {
                        let index = i * 12 + j;
                        let cell = row.insertCell();
                        let input = document.createElement('input');
                        input.type = 'number';
                        input.step = '0.01';
                        input.min = '0';
                        input.max = '1';
                        input.value = defaultSchedule[index];
                        input.style.width = '40px';
                        input.oninput = function() { validatePaymentSum(id); };
                        cell.appendChild(input);
                      }
                    }
                    validatePaymentSum(id);
                  });
                }
            </script>
            </head>
            <body>
            <div id="floorTypesContainer" class="form-section">
                <h3>楼层类型 Floor Types</h3>
            </div>
            <button type="button" onclick="addFloorType()" class="add-btn">+ 增加楼层类型 Add Floor Type</button>
        
            <div class="form-section">
                <h3>标准施工时间 Standard Construction Time</h3>
                <label>开工到正负零月数 Months From Construction Init To Zero Level:</label>
                <input type="number" id="monthsFromConstructionInitToZeroLevel" value="2"><br>
                <label>正负零到封顶月数 Months From Zero Level To Roof Level:</label>
                <input type="number" id="monthsFromZeroLevelToRoofLevel" value="4"><br>
                <label>封顶到交付月数 Months From Roof Level To Delivery:</label>
                <input type="number" id="monthsFromRoofLevelToDelivery" value="6"><br>
                <label>开工到取销售证月数 Months From Construction Init To Sale:</label>
                <input type="number" id="monthsFromConstructionInitToSale" value="2"><br>
                <label>资金监管比例 Supervision Fund Percentage:</label>
                <input type="number" id="supervisionFundPercentage" value="1"><br>
            </div>
        
            <div class="form-section">
                <h3>资金监管解活时间 (从开工开始计算) Supervision Fund Release Schedule</h3>
                <table id="supervisionFundReleaseSchedule"></table>
                <p>总和 Sum: <span id="supervisionFundReleaseSchedule_sum">0.00</span></p>
                <p id="supervisionFundReleaseSchedule_error" class="error" style="display:none;">总和应为1 Sum should be 1</p>
            </div>
        
            <div class="form-section">
                <h3>施工付款计划 (从开工开始计算) Construction Payment Schedule</h3>
                <table id="constructionPaymentSchedule"></table>
                <p>总和 Sum: <span id="constructionPaymentSchedule_sum">0.00</span></p>
                <p id="constructionPaymentSchedule_error" class="error" style="display:none;">总和应为1 Sum should be 1</p>
            </div>
        
            <div class="form-section">
              <h3>保存与加载 Save and Load</h3>
              <p>楼型名称 Building Type Name: <span id="buildingTypeName"></span></p>
              <p>建筑面积 Total Area: <span id="totalArea">0</span> m²</p>
              <p>占地面积 Footprint Area: <span id="footprintArea">0</span> m²</p>
              <button type="button" onclick="submitForm()">保存楼型 Save Building Type</button>
              <select id="savedBuildingTypes" onchange="loadBuildingType()">
                <option value="">选择楼型 Select a building type</option>
              </select>
              <button type="button" onclick="deleteBuildingType()">删除楼型 Delete Building Type</button>
            </div>
            </body>
        </html>
        HTML

        dialog.set_html(html_content)
  
        dialog.add_action_callback("save_building_type") do |action_context, form_data|
          begin
            form_data = JSON.parse(URI.decode_www_form_component(form_data))
            model = Sketchup.active_model
            
            # Update the building type list
            building_type_names = model.get_attribute('project_data', BuildingGenerator::BUILDING_TYPE_LIST_KEY, [])
            building_type_names |= [form_data['name']]  # Add name if not present
            model.set_attribute('project_data', BuildingGenerator::BUILDING_TYPE_LIST_KEY, building_type_names)
            
            # Create or update the building type component
            updated_building_def = BuildingTypeComponent.create_or_update_component(form_data)
            
            # Update form_data with the calculated values
            form_data['total_area'] = updated_building_def.get_attribute('building_data', 'total_area')
            form_data['footprint_area'] = updated_building_def.get_attribute('building_data', 'footprint_area')
            
            # Save data in component definition
            updated_building_def.set_attribute('building_data', 'details', form_data.to_json)
            
            # Save data in project_data (as a backup)
            project_data_json = model.get_attribute('project_data', 'data', '{}')
            project_data = JSON.parse(project_data_json)
            project_data['building_types'] ||= []
            project_data['building_types'].reject! { |bt| bt['name'] == form_data['name'] }
            project_data['building_types'] << form_data
            model.set_attribute('project_data', 'data', project_data.to_json)
            
            puts "Saved building type: #{form_data['name']}"
            puts "Updated building type list: #{building_type_names.inspect}"
            
            # Update the dialog with new values
            dialog.execute_script("document.getElementById('totalArea').textContent = '#{form_data['total_area']}'")
            dialog.execute_script("document.getElementById('footprintArea').textContent = '#{form_data['footprint_area']}'")
            
            UI.messagebox("Building type '#{form_data['name']}' saved successfully.")
            update_saved_building_types(dialog)
          rescue => e
            puts "Error in save_building_type: #{e.message}"
            puts e.backtrace.join("\n")
            UI.messagebox("An error occurred while saving the building type. Check the Ruby Console for details.")
          end
        end

        dialog.add_action_callback("populate_all_apartment_types") do |action_context|
          model = Sketchup.active_model
          apartment_type_names = model.get_attribute('property_data', 'apartment_type_names', [])
          js_code = "var selects = document.querySelectorAll('select[id^=\"apartmentName\"]');"
          js_code += "selects.forEach(function(select) {"
          js_code += "  var currentValue = select.value;"
          js_code += "  select.innerHTML = '<option value=\"\">选择户型 Select an apartment type</option>';"
          apartment_type_names.each do |type|
            js_code += "  select.innerHTML += '<option value=\"#{type}\">#{type}</option>';"
          end
          js_code += "  select.value = currentValue;" # it has restored the existing values, which is good
          js_code += "});"
          dialog.execute_script(js_code)
        end
  
        dialog.add_action_callback("load_building_type") do |action_context, name|
          begin
            model = Sketchup.active_model
            
            # Get the list of building type names
            building_type_names = model.get_attribute('project_data', BuildingGenerator::BUILDING_TYPE_LIST_KEY, [])
            
            puts "Available building types: #{building_type_names.inspect}"
            
            if !building_type_names.include?(name)
              puts "Warning: Building type '#{name}' not found in the list"
              UI.messagebox("Building type '#{name}' not found.")
              next  # Use 'next' instead of 'return' in a block
            end
            
            # Try to get the building type data from the component definition
            definition = model.definitions[name]
            if definition && definition.attribute_dictionaries && definition.attribute_dictionaries['building_data']
              building_type_json = definition.get_attribute('building_data', 'details')
              if building_type_json
                building_type = JSON.parse(building_type_json)
                load_building_data(dialog, building_type)
                next  # Use 'next' instead of 'return' in a block
              end
            end
            
            # If not found in component definition, try to get from project_data
            project_data_json = model.get_attribute('project_data', 'data')
            if project_data_json
              project_data = JSON.parse(project_data_json)
              if project_data['building_types']
                building_type = project_data['building_types'].find { |bt| bt['name'] == name }
                if building_type
                  load_building_data(dialog, building_type)
                  next  # Use 'next' instead of 'return' in a block
                end
              end
            end
            
            puts "Warning: Building type '#{name}' data not found"
            UI.messagebox("Building type '#{name}' data not found.")
          rescue => e
            puts "Error in load_building_type: #{e.message}"
            puts e.backtrace.join("\n")
            UI.messagebox("An error occurred while loading the building type. Check the Ruby Console for details.")
          end
        end
  
        dialog.add_action_callback("delete_building_type") do |action_context, name|
          model = Sketchup.active_model
          building_type_names = model.get_attribute('project_data', BUILDING_TYPE_LIST_KEY, [])
          building_type_names.delete(name)
          model.set_attribute('project_data', BUILDING_TYPE_LIST_KEY, building_type_names)
          
          project_data = JSON.parse(model.get_attribute('project_data', 'data', '{}'))
          project_data['building_types'].delete_if { |bt| bt['name'] == name }
          model.set_attribute('project_data', 'data', project_data.to_json)
          
          UI.messagebox("Building type '#{name}' deleted.")
          update_saved_building_types(dialog)
        end
  
        dialog.add_action_callback("get_saved_building_types") do |action_context|
          update_saved_building_types(dialog)
        end
  
        dialog.show
      end
  
      def self.update_saved_building_types(dialog)
        model = Sketchup.active_model
        building_type_names = model.get_attribute('project_data', BUILDING_TYPE_LIST_KEY, [])
        puts "Available building types: #{building_type_names.inspect}"
        js_code = "var select = document.getElementById('savedBuildingTypes');"
        js_code += "select.innerHTML = '<option value=\"\">选择已有楼型 Select a building type</option>';"
        building_type_names.each do |name|
          js_code += "select.innerHTML += '<option value=\"#{name}\">#{name}</option>';"
        end
        dialog.execute_script(js_code)
      end
  
      def self.load_building_data(dialog, building_data)
        js_code_lines = []
        js_code_lines << "document.getElementById('floorTypesContainer').innerHTML = '';"
      
        building_data['floorTypes'].each_with_index do |floor_type, index|
          js_code_lines << "addFloorType();"
          js_code_lines << "document.getElementById('numberFloors' + document.querySelector('.floor-type:last-child').id.replace('floorType', '')).value = #{floor_type['number']};"
          js_code_lines << "document.getElementById('levelHeight' + document.querySelector('.floor-type:last-child').id.replace('floorType', '')).value = #{floor_type['levelHeight']};"
      
          floor_type['apartmentTypes'].each do |apt|
            js_code_lines << "addApartmentType(document.querySelector('.floor-type:last-child').id.replace('floorType', ''));"
            js_code_lines << "var lastApartment = document.querySelector('.floor-type:last-child .apartment-type:last-child');"
            js_code_lines << "lastApartment.querySelector('select').innerHTML = '<option value=\"#{apt['name']}\">#{apt['name']}</option>';"
            js_code_lines << "lastApartment.querySelector('select').value = '#{apt['name']}';"
            js_code_lines << "lastApartment.querySelector('input[id^=\"apartmentX\"]').value = #{apt['x']};"
            js_code_lines << "lastApartment.querySelector('input[id^=\"apartmentY\"]').value = #{apt['y']};"
          end
        end
      
        js_code_lines << "document.getElementById('totalArea').textContent = #{building_data['total_area'] || 0};"
        js_code_lines << "document.getElementById('footprintArea').textContent = #{building_data['footprint_area'] || 0};"
      
        js_code_lines << "document.getElementById('monthsFromConstructionInitToZeroLevel').value = #{building_data['standardConstructionTime']['monthsFromConstructionInitToZeroLevel']};"
        js_code_lines << "document.getElementById('monthsFromZeroLevelToRoofLevel').value = #{building_data['standardConstructionTime']['monthsFromZeroLevelToRoofLevel']};"
        js_code_lines << "document.getElementById('monthsFromRoofLevelToDelivery').value = #{building_data['standardConstructionTime']['monthsFromRoofLevelToDelivery']};"
        js_code_lines << "document.getElementById('monthsFromConstructionInitToSale').value = #{building_data['standardConstructionTime']['monthsFromConstructionInitToSale']};"
        js_code_lines << "document.getElementById('supervisionFundPercentage').value = #{building_data['standardConstructionTime']['supervisionFundPercentage']};"
      
        # Populate payment schedules
        js_code_lines << "console.log('Loading Supervision Fund Release Schedule:', #{building_data['supervisionFundReleaseSchedule'].to_json});"
        js_code_lines << "console.log('Loading Construction Payment Schedule:', #{building_data['constructionPaymentSchedule'].to_json});"
        js_code_lines << "populatePaymentTable('supervisionFundReleaseSchedule', #{(building_data['supervisionFundReleaseSchedule'] || Real_Estate_Optimizer::DefaultValues::PROJECT_DEFAULTS[:inputs][:supervision_fund_release_schedule]).to_json});"
        js_code_lines << "populatePaymentTable('constructionPaymentSchedule', #{(building_data['constructionPaymentSchedule'] || Real_Estate_Optimizer::DefaultValues::PROJECT_DEFAULTS[:inputs][:construction_payment_schedule]).to_json});"
      
        # Validate payment sums after populating
        js_code_lines << "validatePaymentSum('supervisionFundReleaseSchedule');"
        js_code_lines << "validatePaymentSum('constructionPaymentSchedule');"
        js_code_lines << "verifyAllCellsPopulated();"
      
        js_code_lines << "updateBuildingTypeName();"
        
        # Populate apartment options after setting values
        js_code_lines << "populateApartmentOptions();"
        
        # Restore the previously set values for apartment types
        building_data['floorTypes'].each_with_index do |floor_type, floor_index|
          floor_type['apartmentTypes'].each_with_index do |apt, apt_index|
            js_code_lines << "document.querySelectorAll('.floor-type')[#{floor_index}].querySelectorAll('.apartment-type select')[#{apt_index}].value = '#{apt['name']}';"
          end
        end
      
        # Add verification function
        js_code_lines << "
          function verifyLoadedData() {
            let supervisionData = [];
            let constructionData = [];
            
            document.querySelectorAll('#supervisionFundReleaseSchedule input').forEach(input => {
              supervisionData.push(parseFloat(input.value) || 0);
            });
            
            document.querySelectorAll('#constructionPaymentSchedule input').forEach(input => {
              constructionData.push(parseFloat(input.value) || 0);
            });
            
            console.log('Verified Supervision Fund Release Schedule:', supervisionData);
            console.log('Verified Construction Payment Schedule:', constructionData);
          }
        "
        
        # Call verification function
        js_code_lines << "verifyLoadedData();"
      
        # Join all lines into a single string
        js_code = js_code_lines.join("\n")
        
        dialog.execute_script(js_code)
      end
    end
  end
  
# To show the dialog, call:
# Real_Estate_Optimizer::BuildingGenerator.show_dialog
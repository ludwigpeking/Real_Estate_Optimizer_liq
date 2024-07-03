require 'sketchup.rb'
require 'json'

module Real_Estate_Optimizer
  module BuildingGenerator
    BUILDING_TYPE_LIST_KEY = 'building_type_names'

    def self.show_dialog
      dialog = UI::HtmlDialog.new(
        {
          :dialog_title => "Building Type Management Panel",
          :preferences_key => "com.example.building_generator",
          :scrollable => true,
          :resizable => true,
          :width => 600,
          :height => 800,
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
          <style>
            body { font-family: Arial, sans-serif; }
            .form-section { margin-bottom: 20px; }
            .form-section h3 { margin-top: 0; }
            .form-section table { width: 80%; table-layout: fixed; }
            .form-section th, .form-section td { border: 1px solid #ddd; border-collapse: collapse; padding: 5px; text-align: left; }
            .form-section th { background-color: #f2f2f2; font-weight: normal; font-size: 12px; }
            .form-section td { width: 6.6%; font-size: 12px; }
            .add-btn { margin-top: 10px; }
            input[type="text"], input[type="number"] { width: 50px; }
            .pricing-scene {
              display: flex;
              align-items: center;
              margin-bottom: 10px;
            }
            .pricing-scene input {
              margin-right: 10px;
            }
            .pricing-scene button {
              width: 20px;
              height: 20px;
              border-radius: 50%;
              border: 1px solid black;
              font-size: 15px;
            }
            .pricing-scene button.add {
              background-color: #eee;
              color: black;
            }
            .pricing-scene button.remove {
              background-color: #eee;
              color: black;
            }
          </style>
          <script>
            function addFloorType() {
              var floorTypesContainer = document.getElementById('floorTypesContainer');
              var floorTypeIndex = Date.now(); // Use timestamp to ensure unique IDs
              var floorTypeHtml = '<div class="form-section" id="floorType' + floorTypeIndex + '">'
                  + '<h3>楼层类型 Floor Type ' + (floorTypesContainer.children.length + 1) + '</h3>'
                  + '<label>该楼层类型的数量 Number of Floors:</label>'
                  + '<input type="number" id="numberFloors' + floorTypeIndex + '" value="1"><br>'
                  + '<label>该楼层层高 Level Height (m):</label>'
                  + '<input type="number" id="levelHeight' + floorTypeIndex + '" value="3" step="0.1"><br>'
                  + '<label>该楼层包含户型 Apartment Types:</label>'
                  + '<div id="apartmentTypesContainer' + floorTypeIndex + '"></div>'
                  + '<button type="button" class="add-btn" onclick="addApartmentType(' + floorTypeIndex + ')">+ 增加该楼层户型 Add Apartment Type</button>'
                  + '<button type="button" class="remove-btn" onclick="removeFloorType(' + floorTypeIndex + ')">- 删除楼层类型 Remove Floor Type</button>'
                  + '</div>';
              floorTypesContainer.insertAdjacentHTML('beforeend', floorTypeHtml);
              addApartmentType(floorTypeIndex);
              updateBuildingTypeName();
            }

            function addApartmentType(floorTypeIndex) {
              var container = document.getElementById('apartmentTypesContainer' + floorTypeIndex);
              var apartmentIndex = Date.now(); // Use timestamp to ensure unique IDs
              var apartmentHtml = '<div>'
                  + '<label>户型名称 Apartment Name:</label>'
                  + '<select id="apartmentName' + floorTypeIndex + '_' + apartmentIndex + '">'
                  + '</select>'
                  + '<label>相对原点的平面位移 X Position:</label>'
                  + '<input type="number" id="apartmentX' + floorTypeIndex + '_' + apartmentIndex + '" value="0" step="0.1">'
                  + '<label>相对原点的平面位移 Y Position:</label>'
                  + '<input type="number" id="apartmentY' + floorTypeIndex + '_' + apartmentIndex + '" value="0" step="0.1">'
                  + '<button type="button" class="remove" onclick="removeApartmentType(' + floorTypeIndex + ', ' + apartmentIndex + ')">-</button>'
                  + '</div>';
              container.insertAdjacentHTML('beforeend', apartmentHtml);
              populateApartmentOptions();
              updateBuildingTypeName();
            }

            function removeFloorType(floorTypeIndex) {
              var floorType = document.getElementById('floorType' + floorTypeIndex);
              floorType.parentNode.removeChild(floorType);
              updateBuildingTypeName();
            }

            function removeApartmentType(floorTypeIndex, apartmentIndex) {
              var container = document.getElementById('apartmentTypesContainer' + floorTypeIndex);
              var apartmentType = container.children[apartmentIndex];
              apartmentType.parentNode.removeChild(apartmentType);
              updateBuildingTypeName();
            }

            function updateAllApartmentSelects() {
              var selects = document.querySelectorAll('select[id^="apartmentName"]');
              selects.forEach(function(select) {
                window.location = 'skp:populate_apartment_types@' + select.id.split('_')[1] + '@' + select.id.split('_')[2];
              });
            }

            

            function extractAreaFromName(name) {
                let match = name.match(/^(\d+)/);
                return match ? match[1] : null;
            }

            // Add event listeners to update the building type name whenever changes are made
            document.addEventListener('input', function(e) {
                if (e.target.id.startsWith('numberFloors') || e.target.id.startsWith('apartmentName')) {
                    updateBuildingTypeName();
                }
            });

            function populateApartmentOptions(floorTypeIndex, apartmentIndex) {
              var select = document.getElementById('apartmentName' + floorTypeIndex + '_' + apartmentIndex);
              window.location = 'skp:populate_apartment_types@' + floorTypeIndex + '@' + apartmentIndex;
            }

            // MODIFIED: Updated submitForm function
            function updateBuildingTypeName() {
    let floorTypes = document.querySelectorAll('[id^="floorType"]');
    let apartmentAreas = {};
    let totalFloors = 0;

    floorTypes.forEach((floorType) => {
        let numberFloorsElement = floorType.querySelector('input[id^="numberFloors"]');
        let numberOfFloors = numberFloorsElement ? parseInt(numberFloorsElement.value) || 0 : 0;
        totalFloors += numberOfFloors;

        let apartments = floorType.querySelectorAll('select[id^="apartmentName"]');
        apartments.forEach(apartment => {
            if (apartment && apartment.value) {
                let area = extractAreaFromName(apartment.value);
                if (area) {
                    apartmentAreas[area] = (apartmentAreas[area] || 0) + numberOfFloors;
                }
            }
        });
    });

    let sortedAreas = [];
    for (let area in apartmentAreas) {
        sortedAreas.push([area, apartmentAreas[area]]);
    }
    sortedAreas.sort(function(a, b) {
        return b[1] - a[1];
    });
    sortedAreas = sortedAreas.map(function(entry) {
        return entry[0];
    });

    let buildingTypeName = sortedAreas.join('+') + ' ' + totalFloors + '层';
    let buildingTypeNameElement = document.getElementById('buildingTypeName');
    if (buildingTypeNameElement) {
        buildingTypeNameElement.textContent = buildingTypeName;
    }
    console.log("Generated building type name:", buildingTypeName);
}

function submitForm() {
    try {
        var formData = { floorTypes: [] };

        var floorTypesContainer = document.getElementById('floorTypesContainer');
        if (!floorTypesContainer) {
            throw new Error("Floor types container not found");
        }

        var floorTypeDivs = floorTypesContainer.querySelectorAll('[id^="floorType"]');
        console.log("Number of floor types:", floorTypeDivs.length);

        for (var i = 0; i < floorTypeDivs.length; i++) {
            var floorTypeDiv = floorTypeDivs[i];
            var floorTypeId = floorTypeDiv.id;
            console.log("Processing floor type:", floorTypeId);

            var numberFloorsElement = floorTypeDiv.querySelector('input[id^="numberFloors"]');
            var levelHeightElement = floorTypeDiv.querySelector('input[id^="levelHeight"]');

            if (!numberFloorsElement) {
                console.error("Number of floors element not found for floor type", floorTypeId);
            }
            if (!levelHeightElement) {
                console.error("Level height element not found for floor type", floorTypeId);
            }

            var floorTypeData = {
                number: numberFloorsElement ? parseInt(numberFloorsElement.value) || 1 : 1,
                levelHeight: levelHeightElement ? parseFloat(levelHeightElement.value) || 3 : 3,
                apartmentTypes: []
            };

            var apartmentTypesContainer = floorTypeDiv.querySelector('div[id^="apartmentTypesContainer"]');
            if (!apartmentTypesContainer) {
                console.error("Apartment types container not found for floor type", floorTypeId);
            } else {
                var apartmentDivs = apartmentTypesContainer.children;
                console.log("Number of apartment types:", apartmentDivs.length);

                for (var j = 0; j < apartmentDivs.length; j++) {
                    var apartmentDiv = apartmentDivs[j];
                    var apartmentNameElement = apartmentDiv.querySelector('select[id^="apartmentName"]');
                    var apartmentXElement = apartmentDiv.querySelector('input[id^="apartmentX"]');
                    var apartmentYElement = apartmentDiv.querySelector('input[id^="apartmentY"]');

                    if (!apartmentNameElement) {
                        console.error("Apartment name element not found for apartment", j, "in floor type", floorTypeId);
                    }
                    if (!apartmentXElement) {
                        console.error("Apartment X element not found for apartment", j, "in floor type", floorTypeId);
                    }
                    if (!apartmentYElement) {
                        console.error("Apartment Y element not found for apartment", j, "in floor type", floorTypeId);
                    }

                    var apartmentTypeData = {
                        name: apartmentNameElement ? apartmentNameElement.value : '',
                        x: apartmentXElement ? parseFloat(apartmentXElement.value) || 0 : 0,
                        y: apartmentYElement ? parseFloat(apartmentYElement.value) || 0 : 0
                    };
                    floorTypeData.apartmentTypes.push(apartmentTypeData);
                }
            }

            formData.floorTypes.push(floorTypeData);
        }

                    var constructionTimeElements = [
                      'monthsFromConstructionInitToZeroLevel',
                      'monthsFromZeroLevelToRoofLevel',
                      'monthsFromRoofLevelToDelivery',
                      'monthsFromConstructionInitToSale',
                      'supervisionFundPercentage'
                  ];

                  formData.standardConstructionTime = {};
                  constructionTimeElements.forEach(function(elementId) {
                      var element = document.getElementById(elementId);
                      if (!element) {
                          throw new Error(`Element not found: ${elementId}`);
                      }
                      formData.standardConstructionTime[elementId] = parseFloat(element.value);
                  });

                  formData.supervisionFundReleaseSchedule = [];
                  formData.constructionPaymentSchedule = [];

                  for (var k = 0; k < 36; k++) {
                      var supervisionElement = document.getElementById('supervisionFundReleaseSchedule' + k);
                      var constructionElement = document.getElementById('constructionPaymentSchedule' + k);

                      if (!supervisionElement || !constructionElement) {
                          throw new Error(`Missing elements for schedule index ${k}`);
                      }

                      formData.supervisionFundReleaseSchedule.push(parseFloat(supervisionElement.value));
                      formData.constructionPaymentSchedule.push(parseFloat(constructionElement.value));
                  }

                  var buildingTypeNameElement = document.getElementById('buildingTypeName');
                  if (!buildingTypeNameElement) {
                      throw new Error("Building type name element not found");
                  }
                  formData.name = buildingTypeNameElement.textContent;

                  console.log("Submitting form data:", JSON.stringify(formData)); // Debug line
                  window.location = 'skp:submit_form@' + encodeURIComponent(JSON.stringify(formData));
              

          } catch (error) {
                    console.error("Error in submitForm:", error);
                    alert("An error occurred while saving the building type: " + error.message);
                }
            }

            // ADDED: Function to load a building type
            function loadBuildingType() {
              var select = document.getElementById('savedBuildingTypes');
              var selectedName = select.value;
              if (selectedName) {
                window.location = 'skp:load_building_type@' + selectedName;
              }
            }

            // ADDED: Function to delete a building type
            function deleteBuildingType() {
              var select = document.getElementById('savedBuildingTypes');
              var selectedName = select.value;
              if (selectedName) {
                if (confirm('Are you sure you want to delete this building type?')) {
                  window.location = 'skp:delete_building_type@' + selectedName;
                }
              } else {
                alert('Please select a building type to delete.');
              }
            }

            // ADDED: Function to update the saved building types dropdown
            function updateSavedBuildingTypes(buildingTypes) {
              var select = document.getElementById('savedBuildingTypes');
              select.innerHTML = '<option value="">Select a building type</option>';
              buildingTypes.forEach(function(type) {
                var option = document.createElement('option');
                option.value = type;
                option.textContent = type;
                select.appendChild(option);
              });
            }

            window.onload = function() {
              window.location = 'skp:get_saved_building_types';
              window.location = 'skp:populate_apartment_types';
              updateBuildingTypeName();
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
            <input type="number" id="supervisionFundPercentage" value="60"><br>
          </div>

          <div class="form-section">
            <h3>资金监管解活时间 (从开工开始计算) Supervision Fund Release Schedule</h3>
            <table>
              <tr>
                #{(1..12).map { |i| "<th>Month #{i}</th>" }.join}
              </tr>
              #{(0...3).map { |i| "<tr>#{(0...12).map { |j| "<td><input type='number' id='supervisionFundReleaseSchedule#{i * 12 + j}' value='0' step='0.01'></td>" }.join}</tr>" }.join}
            </table>
          </div>

          <div class="form-section">
            <h3>施工付款计划 (从开工开始计算) Construction Payment Schedule</h3>
            <table>
              <tr>
                #{(1..12).map { |i| "<th>Month #{i}</th>" }.join}
              </tr>
              #{(0...3).map { |i| "<tr>#{(0...12).map { |j| "<td><input type='number' id='constructionPaymentSchedule#{i * 12 + j}' value='0' step='0.01'></td>" }.join}</tr>"}.join}
              </table>
            </div>
  
            <!-- MODIFIED: Updated Save and Load section -->
            <div class="form-section">
              <h3>保存与加载 Save and Load</h3>
              <p>楼型名称 Building Type Name: <span id="buildingTypeName"></span></p>
              <button type="button" onclick="submitForm()">保存楼型 Save Building Type</button>
              <select id="savedBuildingTypes" onchange="loadBuildingType()">
                <option value="">Select a building type</option>
              </select>
              <button type="button" onclick="deleteBuildingType()">删除楼型 Delete Building Type</button>
            </div>
            <button type="button" onclick="console.log('Debug button clicked')">Debug</button>
          </body>
          </html>
        HTML
  
        dialog.set_html(html_content)
  
        dialog.add_action_callback("populate_apartment_types") do |action_context, params|
          model = Sketchup.active_model
          apartment_type_names = model.get_attribute('property_data', 'apartment_type_names', [])
          js_code = "function populateApartmentOptions() { "
          js_code += "  var selects = document.querySelectorAll('select[id^=\"apartmentName\"]');"
          js_code += "  selects.forEach(function(select) {"
          js_code += "    select.innerHTML = '';" # Clear existing options
          apartment_type_names.each do |type|
            js_code += "    select.insertAdjacentHTML('beforeend', '<option value=\"#{type}\">#{type}</option>');"
          end
          js_code += "  });"
          js_code += "}"
          js_code += "populateApartmentOptions();"
          dialog.execute_script(js_code)
        end
  
        dialog.add_action_callback("submit_form") do |action_context, form_data|
          begin
            puts "Received form data: #{form_data}" # Debug line
            form_data = JSON.parse(URI.decode_www_form_component(form_data))
            puts "Parsed form data: #{form_data.inspect}" # Debug line
            
            model = Sketchup.active_model
            building_type_names = model.get_attribute('project_data', BUILDING_TYPE_LIST_KEY, [])
            puts "Existing building type names: #{building_type_names.inspect}" # Debug line
        
            if building_type_names.include?(form_data['name'])
              result = UI.messagebox("楼型名已存在。是否覆盖？ Building type name already exists. Overwrite?", MB_YESNO)
              return if result == IDNO
            else
              building_type_names << form_data['name']
              model.set_attribute('project_data', BUILDING_TYPE_LIST_KEY, building_type_names)
            end
        
            project_data = model.get_attribute('project_data', 'data')
            puts "Existing project data: #{project_data.inspect}" # Debug line
            project_data = project_data ? JSON.parse(project_data) : {}
            project_data['building_types'] ||= []
            project_data['building_types'].delete_if { |bt| bt['name'] == form_data['name'] }
            project_data['building_types'] << form_data
            model.set_attribute('project_data', 'data', project_data.to_json)
        
            puts "Saved project data: #{project_data.inspect}" # Debug line
            UI.messagebox("Building type '#{form_data['name']}' saved.")
            update_saved_building_types(dialog)
          rescue => e
            puts "Error in submit_form: #{e.message}"
            puts e.backtrace.join("\n")
            UI.messagebox("An error occurred while saving the building type. Check the Ruby Console for details.")
          end
        end
        
        dialog.add_action_callback("load_building_type") do |action_context, name|
          model = Sketchup.active_model
          project_data = model.get_attribute('project_data', 'data')
          if project_data
            project_data = JSON.parse(project_data)
            building_data = project_data['building_types'].find { |bt| bt['name'] == name }
            if building_data
              puts "Loading building data: #{building_data.inspect}" # Debug line
              load_building_data(dialog, building_data)
            else
              UI.messagebox("未找到该楼型数据 Building type data not found.")
            end
          else
            UI.messagebox("No project data found.")
          end
        end
  
        # ADDED: Callback for deleting a building type
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
        puts "Updating saved building types: #{building_type_names.inspect}" # Debug line
        dialog.execute_script("console.log('Updating saved building types:', #{building_type_names.to_json}); updateSavedBuildingTypes(#{building_type_names.to_json})")
      end
  
      def self.load_building_data(dialog, building_data)
  js_code = <<-JS
    var floorTypesContainer = document.getElementById('floorTypesContainer');
    floorTypesContainer.innerHTML = '';
  JS

  building_data['floorTypes'].each_with_index do |floor_type, ft_index|
    js_code += "addFloorType();\n"
    js_code += "document.getElementById('numberFloors#{ft_index}').value = #{floor_type['number']};\n"
    js_code += "document.getElementById('levelHeight#{ft_index}').value = #{floor_type['levelHeight']};\n"
    floor_type['apartmentTypes'].each_with_index do |apt, apt_index|
      js_code += "addApartmentType(#{ft_index});\n"
      js_code += "document.getElementById('apartmentName#{ft_index}_#{apt_index}').value = '#{apt['name']}';\n"
      js_code += "document.getElementById('apartmentX#{ft_index}_#{apt_index}').value = #{apt['x']};\n"
      js_code += "document.getElementById('apartmentY#{ft_index}_#{apt_index}').value = #{apt['y']};\n"
    end
  end
  
  js_code += "document.getElementById('monthsFromConstructionInitToZeroLevel').value = #{building_data['standardConstructionTime']['monthsFromConstructionInitToZeroLevel']};\n"
  js_code += "document.getElementById('monthsFromZeroLevelToRoofLevel').value = #{building_data['standardConstructionTime']['monthsFromZeroLevelToRoofLevel']};\n"
  js_code += "document.getElementById('monthsFromRoofLevelToDelivery').value = #{building_data['standardConstructionTime']['monthsFromRoofLevelToDelivery']};\n"
  js_code += "document.getElementById('monthsFromConstructionInitToSale').value = #{building_data['standardConstructionTime']['monthsFromConstructionInitToSale']};\n"
  js_code += "document.getElementById('supervisionFundPercentage').value = #{building_data['standardConstructionTime']['supervisionFundPercentage']};\n"

  building_data['supervisionFundReleaseSchedule'].each_with_index do |value, index|
    js_code += "document.getElementById('supervisionFundReleaseSchedule#{index}').value = #{value};\n"
  end

  building_data['constructionPaymentSchedule'].each_with_index do |value, index|
    js_code += "document.getElementById('constructionPaymentSchedule#{index}').value = #{value};\n"
  end

  js_code += "populateApartmentOptions();\n"
  js_code += "updateBuildingTypeName();\n"
  puts "Executing JavaScript: #{js_code}" # Debug line
  dialog.execute_script(js_code)
end
    end
  end
  
  # To show the dialog, call:
  # Real_Estate_Optimizer::BuildingGenerator.show_dialog
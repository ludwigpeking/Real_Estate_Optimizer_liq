require 'sketchup.rb'
require 'json'

module Urban_Banal
  module Real_Estate_Optimizer
    module BuildingGenerator
      def self.generate
        dialog = UI::WebDialog.new("Building Type Management Panel", false, "BuildingGenerator", 600, 800, 150, 150, true)

        html = <<-HTML
          <html>
          <head>
            <meta charset="UTF-8">
            <style>
              body { font-family: Arial, sans-serif; }
              .form-section { margin-bottom: 20px; }
              .form-section h3 { margin-top: 0; }
              .form-section table { width: 80%; table-layout: fixed; }
              .form-section th, .form-section td { border: 1px solid #ddd; border-collapse: collapse; padding: 5px; text-align: left; }
              .form-section th { background-color: #f2f2f2; font-weight: normal; font-size: 12px; }
              .form-section td { width: 6.6%; font-size: 12px; } /* Set each cell to be 1/3 of the original width */
              .add-btn { margin-top: 10px; }
              input[type="text"], input[type="number"] { width: 50px; } /* Adjust the width as needed */
              .modal {
                display: none;
                position: fixed;
                z-index: 1;
                left: 0;
                top: 0;
                width: 100%;
                height: 100%;
                overflow: auto;
                background-color: rgb(0,0,0);
                background-color: rgba(0,0,0,0.4);
                padding-top: 60px;
              }
              .modal-content {
                background-color: #fefefe;
                margin: 5% auto;
                padding: 20px;
                border: 1px solid #888;
                width: 80%;
              }
              .close {
                color: #aaa;
                float: right;
                font-size: 28px;
                font-weight: bold;
              }
              .close:hover,
              .close:focus {
                color: black;
                text-decoration: none;
                cursor: pointer;
              }
            </style>

            <script type="text/javascript">
              function addFloorType() {
                var floorTypesContainer = document.getElementById('floorTypesContainer');
                var floorTypeIndex = floorTypesContainer.children.length;
                var floorTypeHtml = '<div class="form-section" id="floorType' + floorTypeIndex + '">'
                  + '<h3>楼层类型 Floor Type ' + (floorTypeIndex + 1) + '</h3>'
                  + '<label>该楼层类型的数量 Number of Floors:</label>'
                  + '<input type="number" id="numberFloors' + floorTypeIndex + '" value="1"><br>'
                  + '<label>该楼层层高 Level Height (m):</label>'
                  + '<input type="number" id="levelHeight' + floorTypeIndex + '" value="3" step="0.1"><br>'
                  + '<label>该楼层包含户型 Apartment Types:</label>'
                  + '<div id="apartmentTypesContainer' + floorTypeIndex + '">'
                  + '<div>'
                  + '<label>户型名称 Apartment Name:</label>'
                  + '<select id="apartmentName' + floorTypeIndex + '_0">'
                  + '<!-- Options will be dynamically filled from SketchUp -->'
                  + '</select>'
                  + '<label>相对原点的平面位移 X Position:</label>'
                  + '<input type="number" id="apartmentX' + floorTypeIndex + '_0" value="0" step="0.1">'
                  + '<label>相对原点的平面位移 Y Position:</label>'
                  + '<input type="number" id="apartmentY' + floorTypeIndex + '_0" value="0" step="0.1">'
                  + '</div>'
                  + '</div>'
                  + '<button type="button" onclick="addApartmentType(' + floorTypeIndex + ')">+ 增加该楼层户型 Add Apartment Type</button>'
                  + '</div>';
                floorTypesContainer.insertAdjacentHTML('beforeend', floorTypeHtml);
                populateApartmentOptions(floorTypeIndex, 0);
              }

              function addApartmentType(floorTypeIndex) {
                var container = document.getElementById('apartmentTypesContainer' + floorTypeIndex);
                var apartmentIndex = container.children.length;
                var apartmentHtml = '<div>'
                  + '<label>户型名称 Apartment Name:</label>'
                  + '<select id="apartmentName' + floorTypeIndex + '_' + apartmentIndex + '">'
                  + '<!-- Options will be dynamically filled from SketchUp -->'
                  + '</select>'
                  + '<label>相对原点的平面位移 X Position:</label>'
                  + '<input type="number" id="apartmentX' + floorTypeIndex + '_' + apartmentIndex + '" value="0" step="0.1">'
                  + '<label>相对原点的平面位移 Y Position:</label>'
                  + '<input type="number" id="apartmentY' + floorTypeIndex + '_' + apartmentIndex + '" value="0" step="0.1">'
                  + '</div>';
                container.insertAdjacentHTML('beforeend', apartmentHtml);
                populateApartmentOptions(floorTypeIndex, apartmentIndex);
              }

              function populateApartmentOptions(floorTypeIndex, apartmentIndex) {
                var select = document.getElementById('apartmentName' + floorTypeIndex + '_' + apartmentIndex);
                window.location = 'skp:populate_apartment_types@' + floorTypeIndex + '@' + apartmentIndex;
              }

              function submitForm() {
                console.log("submitForm called"); // Debugging statement
                var formData = { floorTypes: [] };

                var floorTypesContainer = document.getElementById('floorTypesContainer');
                for (var i = 0; i < floorTypesContainer.children.length; i++) {
                  var floorTypeDiv = floorTypesContainer.children[i];
                  var floorTypeIndex = floorTypeDiv.id.replace('floorType', '');

                  var floorTypeData = {
                    number: parseInt(document.getElementById('numberFloors' + floorTypeIndex).value),
                    levelHeight: parseFloat(document.getElementById('levelHeight' + floorTypeIndex).value),
                    apartmentTypes: []
                  };

                  var apartmentTypesContainer = document.getElementById('apartmentTypesContainer' + floorTypeIndex);
                  for (var j = 0; j < apartmentTypesContainer.children.length; j++) {
                    var apartmentTypeData = {
                      name: document.getElementById('apartmentName' + floorTypeIndex + '_' + j).value,
                      x: parseFloat(document.getElementById('apartmentX' + floorTypeIndex + '_' + j).value),
                      y: parseFloat(document.getElementById('apartmentY' + floorTypeIndex + '_' + j).value)
                    };
                    floorTypeData.apartmentTypes.push(apartmentTypeData);
                  }

                  formData.floorTypes.push(floorTypeData);
                }

                formData.standardConstructionTime = {
                  daysFromConstructionInitToZeroLevel: parseInt(document.getElementById('daysFromConstructionInitToZeroLevel').value),
                  daysFromZeroLevelToRoofLevel: parseInt(document.getElementById('daysFromZeroLevelToRoofLevel').value),
                  daysFromRoofLevelToDelivery: parseInt(document.getElementById('daysFromRoofLevelToDelivery').value),
                  daysFromConstructionInitToSale: parseInt(document.getElementById('daysFromConstructionInitToSale').value),
                  supervisionFundPercentage: parseFloat(document.getElementById('supervisionFundPercentage').value)
                };

                formData.supervisionFundReleaseSchedule = [];
                formData.constructionPaymentSchedule = [];

                for (var k = 0; k < 36; k++) {
                  formData.supervisionFundReleaseSchedule.push(parseFloat(document.getElementById('supervisionFundReleaseSchedule' + k).value));
                  formData.constructionPaymentSchedule.push(parseFloat(document.getElementById('constructionPaymentSchedule' + k).value));
                }

                var buildingName = document.getElementById('buildingTypeName').value;
                if (buildingName) {
                  formData.name = buildingName;
                  console.log("Submitting form with name: " + buildingName); // Debugging statement
                  window.location = 'skp:submit_form@' + JSON.stringify(formData);
                } else {
                  alert('Please enter a building name.');
                }
              }

              function loadBuildingType(name) {
                console.log("Loading building type: " + name); // Debugging statement
                window.location = 'skp:load_building_type@' + name;
              }

              function updateSavedBuildingTypes(buildingNames) {
                console.log("Updating saved building types: " + buildingNames); // Debugging statement
                var savedTypesContainer = document.getElementById('savedTypesContainer');
                savedTypesContainer.innerHTML = '';
                buildingNames.forEach(function(name) {
                  var button = document.createElement('button');
                  button.textContent = name;
                  button.onclick = function() {
                    loadBuildingType(name);
                  };
                  savedTypesContainer.appendChild(button);
                });
              }

              window.onload = function() {
                console.log("Window loaded"); // Debugging statement
                window.location = 'skp:get_saved_building_types';
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
              <label>开工到正负零天数 Days From Construction Init To Zero Level:</label>
              <input type="number" id="daysFromConstructionInitToZeroLevel" value="45"><br>
              <label>正负零到封顶天数 Days From Zero Level To Roof Level:</label>
              <input type="number" id="daysFromZeroLevelToRoofLevel" value="120"><br>
              <label>封顶到交付天数 Days From Roof Level To Delivery:</label>
              <input type="number" id="daysFromRoofLevelToDelivery" value="180"><br>
              <label>开工到取销售证天数 Days From Construction Init To Sale:</label>
              <input type="number" id="daysFromConstructionInitToSale" value="60"><br>
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
                #{(0...3).map { |i| "<tr>#{(0...12).map { |j| "<td><input type='number' id='constructionPaymentSchedule#{i * 12 + j}' value='0' step='0.01'></td>" }.join}</tr>" }.join}
              </table>
            </div>

            <div class="form-section">
              <h3>保存与加载 Save and Load</h3>
              <label>楼型名称 Building Type Name:</label>
              <input type="text" id="buildingTypeName" name="buildingTypeName"><br>
              <button type="button" onclick="submitForm()">保存楼型 Save Building Type</button>
              <div id="savedTypesContainer"></div>
            </div>
          </body>
          </html>
        HTML

        dialog.set_html(html)
        
        dialog.add_action_callback("populate_apartment_types") do |dialog, params|
          floor_type_index, apartment_index = params.split('@')
          apartment_types = ['80小高层首层', '110小高层首层', '90小高层', '120小高层'] # Retrieve from SketchUp or Apartment Manager
          js_code = apartment_types.map { |type| "document.getElementById('apartmentName#{floor_type_index}_#{apartment_index}').insertAdjacentHTML('beforeend', '<option value=\"#{type}\">#{type}</option>');" }.join
          dialog.execute_script(js_code)
        end

        dialog.add_action_callback("submit_form") do |dialog, form_data|
          puts "submit_form callback called with form_data: #{form_data}" # Debugging statement
          form_data = JSON.parse(form_data)
          model = Sketchup.active_model
          model.set_attribute('Urban_Banal', form_data['name'], form_data.to_json)
          UI.messagebox("Building type '#{form_data['name']}' saved.")
          update_saved_building_types(dialog)
        end

        dialog.add_action_callback("load_building_type") do |dialog, name|
          puts "load_building_type callback called with name: #{name}" # Debugging statement
          model = Sketchup.active_model
          if model.attribute_dictionaries && model.attribute_dictionaries['Urban_Banal']
            building_data = JSON.parse(model.get_attribute('Urban_Banal', name))
            load_building_data(dialog, building_data)
          else
            UI.messagebox("No saved building types found.")
          end
        end

        dialog.add_action_callback("get_saved_building_types") do |dialog|
          puts "get_saved_building_types callback called" # Debugging statement
          model = Sketchup.active_model
          if model.attribute_dictionaries && model.attribute_dictionaries['Urban_Banal']
            keys = model.attribute_dictionaries['Urban_Banal'].keys
            dialog.execute_script("updateSavedBuildingTypes(#{keys.to_json})")
          end
        end

        dialog.show
      end

      def self.update_saved_building_types(dialog)
        model = Sketchup.active_model
        if model.attribute_dictionaries && model.attribute_dictionaries['Urban_Banal']
          keys = model.attribute_dictionaries['Urban_Banal'].keys
          dialog.execute_script("updateSavedBuildingTypes(#{keys.to_json})")
        end
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
            js_code += "populateApartmentOptions(#{ft_index}, #{apt_index});\n"
            js_code += "document.getElementById('apartmentName#{ft_index}_#{apt_index}').value = '#{apt['name']}';\n"
            js_code += "document.getElementById('apartmentX#{ft_index}_#{apt_index}').value = #{apt['x']};\n"
            js_code += "document.getElementById('apartmentY#{ft_index}_#{apt_index}').value = #{apt['y']};\n"
          end
        end

        dialog.execute_script(js_code)
      end
    end
  end
end

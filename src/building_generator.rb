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
            <style>
              body { font-family: Arial, sans-serif; }
              .form-section { margin-bottom: 20px; }
              .form-section h2 { margin-top: 0; }
              .form-section table { width: 100%; }
              .form-section table, .form-section th, .form-section td { border: 1px solid #ddd; border-collapse: collapse; }
              .form-section th, .form-section td { padding: 8px; text-align: left; }
              .form-section th { background-color: #f2f2f2; }
              .add-btn { margin-top: 10px; }
            </style>
            <script type="text/javascript">
              function addFloorType() {
                alert("Adding a new floor type"); // Debugging alert
                var floorTypesContainer = document.getElementById('floorTypesContainer');
                var floorTypeIndex = floorTypesContainer.children.length;
                var floorTypeHtml = '<div class="form-section" id="floorType' + floorTypeIndex + '">'
                  + '<h2>Floor Type ' + (floorTypeIndex + 1) + '</h2>'
                  + '<label>Number of Floors:</label>'
                  + '<input type="number" id="numberFloors' + floorTypeIndex + '" value="1"><br>'
                  + '<label>Level Height (m):</label>'
                  + '<input type="number" id="levelHeight' + floorTypeIndex + '" value="3" step="0.1"><br>'
                  + '<label>Apartment Types:</label>'
                  + '<div id="apartmentTypesContainer' + floorTypeIndex + '">'
                  + '<div>'
                  + '<label>Apartment Name:</label>'
                  + '<select id="apartmentName' + floorTypeIndex + '_0">'
                  + '<!-- Options will be dynamically filled from SketchUp -->'
                  + '</select>'
                  + '<label>X Position:</label>'
                  + '<input type="number" id="apartmentX' + floorTypeIndex + '_0" value="0" step="0.1">'
                  + '<label>Y Position:</label>'
                  + '<input type="number" id="apartmentY' + floorTypeIndex + '_0" value="0" step="0.1">'
                  + '</div>'
                  + '</div>'
                  + '<button type="button" onclick="addApartmentType(' + floorTypeIndex + ')">+ Add Apartment Type</button>'
                  + '</div>';
                floorTypesContainer.insertAdjacentHTML('beforeend', floorTypeHtml);
                populateApartmentOptions(floorTypeIndex, 0);
              }

              function addApartmentType(floorTypeIndex) {
                alert("Adding a new apartment type to floor type " + floorTypeIndex); // Debugging alert
                var container = document.getElementById('apartmentTypesContainer' + floorTypeIndex);
                var apartmentIndex = container.children.length;
                var apartmentHtml = '<div>'
                  + '<label>Apartment Name:</label>'
                  + '<select id="apartmentName' + floorTypeIndex + '_' + apartmentIndex + '">'
                  + '<!-- Options will be dynamically filled from SketchUp -->'
                  + '</select>'
                  + '<label>X Position:</label>'
                  + '<input type="number" id="apartmentX' + floorTypeIndex + '_' + apartmentIndex + '" value="0" step="0.1">'
                  + '<label>Y Position:</label>'
                  + '<input type="number" id="apartmentY' + floorTypeIndex + '_' + apartmentIndex + '" value="0" step="0.1">'
                  + '</div>';
                container.insertAdjacentHTML('beforeend', apartmentHtml);
                populateApartmentOptions(floorTypeIndex, apartmentIndex);
              }

              function populateApartmentOptions(floorTypeIndex, apartmentIndex) {
                alert("Populating apartment options for floor type " + floorTypeIndex + ", apartment " + apartmentIndex); // Debugging alert
                var select = document.getElementById('apartmentName' + floorTypeIndex + '_' + apartmentIndex);
                // Dynamically fill options from SketchUp
                window.location = 'skp:populate_apartment_types@' + floorTypeIndex + '@' + apartmentIndex;
              }

              function submitForm() {
                alert("Submitting form"); // Debugging alert
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

                // Send form data to SketchUp
                window.location = 'skp:submit_form@' + JSON.stringify(formData);
              }

              function loadBuildingType() {
                alert("Loading building type"); // Debugging alert
                window.location = 'skp:load_building_type';
              }
            </script>
          </head>
          <body>
            <div id="floorTypesContainer" class="form-section">
              <h2>Floor Types</h2>
            </div>
            <button type="button" onclick="addFloorType()" class="add-btn">+ Add Floor Type</button>

            <div class="form-section">
              <h2>Standard Construction Time</h2>
              <label>Days From Construction Init To Zero Level:</label>
              <input type="number" id="daysFromConstructionInitToZeroLevel" value="45"><br>
              <label>Days From Zero Level To Roof Level:</label>
              <input type="number" id="daysFromZeroLevelToRoofLevel" value="120"><br>
              <label>Days From Roof Level To Delivery:</label>
              <input type="number" id="daysFromRoofLevelToDelivery" value="180"><br>
              <label>Days From Construction Init To Sale:</label>
              <input type="number" id="daysFromConstructionInitToSale" value="60"><br>
              <label>Supervision Fund Percentage:</label>
              <input type="number" id="supervisionFundPercentage" value="60"><br>
            </div>

            <div class="form-section">
              <h2>Supervision Fund Release Schedule</h2>
              <table>
                <tr>
                  #{(1..12).map { |i| "<th>Month #{i}</th>" }.join}
                </tr>
                #{(0...3).map { |i| "<tr>#{(0...12).map { |j| "<td><input type='number' id='supervisionFundReleaseSchedule#{i * 12 + j}' value='0' step='0.01'></td>" }.join}</tr>" }.join}
              </table>
            </div>

            <div class="form-section">
              <h2>Construction Payment Schedule</h2>
              <table>
                <tr>
                  #{(1..12).map { |i| "<th>Month #{i}</th>" }.join}
                </tr>
                #{(0...3).map { |i| "<tr>#{(0...12).map { |j| "<td><input type='number' id='constructionPaymentSchedule#{i * 12 + j}' value='0' step='0.01'></td>" }.join}</tr>" }.join}
              </table>
            </div>

            <button type="button" onclick="submitForm()">Save Building Type</button>
            <button type="button" onclick="loadBuildingType()">Load Building Type</button>
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
          form_data = JSON.parse(form_data)
          # Process and save form data
          puts "Form Data: #{form_data.inspect}"
        end

        dialog.add_action_callback("load_building_type") do |dialog|
          # Logic to load building type from SketchUp (to be implemented)
          puts "Loading building type..."
        end

        dialog.show
      end
    end
  end
end

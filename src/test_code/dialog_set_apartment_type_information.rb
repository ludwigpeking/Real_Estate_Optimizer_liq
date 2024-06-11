#TODO: Variable Names are to be cleaned up
#TODO: Add add some more input fields

# ok, so now I will give you a more complex scenario:
# the dialog title is "户型维护”，there are many DOMs following:
# "户型属于类型" apartment_in_building_type: list select "高层“ high_rise, ”小高层“ minor_high_rise, ”洋房“ middle_rise; (str), default value ”小高层“
# ”户型建筑面积“ apartment_type_area: input ____ ”平米“ (int) default value: 110
# ”备注“ tag: input : string , default ""
# display a generated text: "户型名" apartment_type_name:   =  apartment_type_area + apartment_in_building_type + tag (str)
# "地价外分摊外单方成本": input (float) "元/平米”；
# “面宽” width: input (float) "m"
# "进深“ depth: input (float) "m",
# after these, come the DOMs that represents pricing scenes:
# "销售场景"：
# ”销售场景1“ pricing_scene1: input ____(float)"元/平米”；_____ (int)"套/月", this is a pair, the (+) and (-) button follows to allow adding, removing scenes like ”销售场景2“ pricing_scene2: input ____(float)"元/平米”；_____ (int)"套/月". 
# give me the implementation

# since I will have multiple apartment types, I need to save them to the dictionary with a distinguishable name, apartment_type_name generated in the code can be used as the unique name of the apartment type. I want you to save the apartment type in this way. 
# another thing is: I need to be able to access the saved apartment types from the dialog, load, edit and save. give me implementation to allow this function. (if you are overwriting an apartment_type_name that exists, it should prompt a warning but still allow you to confirm to overwrite)


require 'sketchup.rb'
require 'json'

module Urban_Banal
  module Real_Estate_Optimizer
    APARTMENT_TYPE_LIST_KEY = 'apartment_type_names'

    def self.show_dialog
      dialog = UI::HtmlDialog.new(
        {
          :dialog_title => "户型维护",
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
          <style>
            body { font-family: Arial, sans-serif; margin: 20px; }
            .form-section { margin-bottom: 20px; }
            .form-section label { display: block; margin-bottom: 5px; }
            .form-section input, .form-section select { display: block; margin-bottom: 10px; }
            .form-section button { margin: 5px; }
            .pricing-scene { display: flex; align-items: center; margin-bottom: 10px; }
            .pricing-scene input { margin-right: 10px; }
            .pricing-scene button { width: 30px; height: 30px; border-radius: 50%; border: none; font-size: 20px; }
            .pricing-scene button.add { background-color: #4CAF50; color: white; }
            .pricing-scene button.remove { background-color: #f44336; color: white; }
          </style>
          <script>
            function updateApartmentTypeName() {
              var area = document.getElementById('apartment_type_area').value;
              var type = document.getElementById('apartment_in_building_type').value;
              var tag = document.getElementById('tag').value;
              document.getElementById('apartment_type_name').innerText = area + type + tag;
            }

            function saveAttributes() {
              var apartmentData = {
                apartment_in_building_type: document.getElementById('apartment_in_building_type').value,
                apartment_type_area: parseFloat(document.getElementById('apartment_type_area').value),
                tag: document.getElementById('tag').value,
                apartment_type_name: document.getElementById('apartment_type_name').innerText,
                external_cost_per_sqm: parseFloat(document.getElementById('external_cost_per_sqm').value),
                width: parseFloat(document.getElementById('width').value),
                depth: parseFloat(document.getElementById('depth').value),
                pricing_scenes: []
              };

              document.querySelectorAll('.pricing-scene').forEach(function(scene, index) {
                var price_per_sqm = parseFloat(scene.querySelector('.price_per_sqm').value);
                var units_per_month = parseInt(scene.querySelector('.units_per_month').value);
                apartmentData.pricing_scenes.push({ price_per_sqm: price_per_sqm, units_per_month: units_per_month });
              });

              var apartmentTypeName = apartmentData.apartment_type_name;
              window.location = 'skp:save_attributes@' + apartmentTypeName + '@' + JSON.stringify(apartmentData);
            }

            function addPricingScene(price_per_sqm = '', units_per_month = '') {
              var container = document.getElementById('pricingScenesContainer');
              var index = container.children.length;
              var div = document.createElement('div');
              div.className = 'pricing-scene';
              div.innerHTML = '<input class="price_per_sqm" type="text" value="' + price_per_sqm + '" placeholder="销售场景' + (index + 1) + ' (元/平米)">'
                + '<input class="units_per_month" type="text" value="' + units_per_month + '" placeholder="套/月">'
                + '<button class="add" onclick="addPricingScene()">+</button>';
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
              document.getElementById('apartment_in_building_type').value = data.apartment_in_building_type;
              document.getElementById('apartment_type_area').value = data.apartment_type_area;
              document.getElementById('tag').value = data.tag;
              document.getElementById('apartment_type_name').innerText = data.apartment_type_name;
              document.getElementById('external_cost_per_sqm').value = data.external_cost_per_sqm;
              document.getElementById('width').value = data.width;
              document.getElementById('depth').value = data.depth;

              var container = document.getElementById('pricingScenesContainer');
              container.innerHTML = '';
              data.pricing_scenes.forEach(function(scene) {
                addPricingScene(scene.price_per_sqm, scene.units_per_month);
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
              document.getElementById('apartment_type_area').oninput = updateApartmentTypeName;
              document.getElementById('apartment_in_building_type').onchange = updateApartmentTypeName;
              document.getElementById('tag').oninput = updateApartmentTypeName;
              addPricingScene();
              window.location = 'skp:get_saved_apartment_types';
            }
          </script>
        </head>
        <body>
          <h2>户型维护</h2>
          <div class="form-section">
            <label for="apartment_in_building_type">户型属于类型</label>
            <select id="apartment_in_building_type">
              <option value="高层">高层</option>
              <option value="小高层" selected>小高层</option>
              <option value="洋房">洋房</option>
            </select>
            <label for="apartment_type_area">户型建筑面积 (平米)</label>
            <input type="number" id="apartment_type_area" value="110">
            <label for="tag">备注</label>
            <input type="text" id="tag" value="">
            <label for="apartment_type_name">户型名</label>
            <div id="apartment_type_name">110小高层</div>
          </div>
          <div class="form-section">
            <label for="external_cost_per_sqm">地价外分摊外单方成本 (元/平米)</label>
            <input type="number" id="external_cost_per_sqm">
            <label for="width">面宽 (m)</label>
            <input type="number" id="width">
            <label for="depth">进深 (m)</label>
            <input type="number" id="depth">
          </div>
          <div class="form-section">
            <h3>销售场景</h3>
            <div id="pricingScenesContainer"></div>
            <button onclick="saveAttributes()">保存属性 Save Attributes</button>
          </div>
          <div class="form-section">
            <h3>加载户型 Load Apartment Type</h3>
            <select id="savedApartmentTypes" onchange="loadApartmentType(this.value)">
              <option value="">选择户型...</option>
            </select>
          </div>
        </body>
        </html>
      HTML

      dialog.set_html(html_content)

      dialog.add_action_callback("save_attributes") do |action_context, params|
        apartment_type_name, apartment_data_json = params.split('@', 2)
        apartment_data = JSON.parse(apartment_data_json)
        model = Sketchup.active_model

        # Retrieve the current list of apartment type names
        apartment_type_names = model.get_attribute('Urban_Banal', APARTMENT_TYPE_LIST_KEY, [])
        
        if apartment_type_names.include?(apartment_type_name)
          result = UI.messagebox("户型名已存在。是否覆盖？ Apartment type name already exists. Overwrite?", MB_YESNO)
          return if result == IDNO
        else
          apartment_type_names << apartment_type_name
          model.set_attribute('Urban_Banal', APARTMENT_TYPE_LIST_KEY, apartment_type_names)
        end

        model.set_attribute('Urban_Banal', apartment_type_name, apartment_data.to_json)
        puts "Stored data for #{apartment_type_name}: #{apartment_data.inspect}"  # Debugging line
        UI.messagebox("属性已保存 Attributes saved: " + apartment_data['apartment_type_name'])
        update_saved_apartment_types(dialog)
      end

      dialog.add_action_callback("load_apartment_type") do |action_context, apartment_type_name|
        model = Sketchup.active_model
        apartment_data_json = model.get_attribute('Urban_Banal', apartment_type_name)
        if apartment_data_json
          dialog.execute_script("populateApartmentType('#{apartment_data_json}')")
        else
          UI.messagebox("未找到该户型数据 Apartment type data not found.")
        end
      end

      dialog.add_action_callback("get_saved_apartment_types") do |dialog|
        update_saved_apartment_types(dialog)
      end

      dialog.show
    end

    def self.update_saved_apartment_types(dialog)
      model = Sketchup.active_model
      apartment_type_names = model.get_attribute('Urban_Banal', APARTMENT_TYPE_LIST_KEY, [])
      dialog.execute_script("updateSavedApartmentTypes(#{apartment_type_names.to_json})")
    end
  end
end

Urban_Banal::Real_Estate_Optimizer.show_dialog

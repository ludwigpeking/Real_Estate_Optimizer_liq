require 'sketchup.rb'
require 'json'

module Real_Estate_Optimizer
  module ApartmentManager
    APARTMENT_TYPE_LIST_KEY = 'apartment_type_names'

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
          <script>
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
              document.getElementById('apartment_type_area').oninput = updateApartmentTypeName;
              document.getElementById('apartment_category').onchange = updateApartmentTypeName;
              document.getElementById('tag').oninput = updateApartmentTypeName;
              addPricingScene();
              window.location = 'skp:get_saved_apartment_types';
            }
          </script>
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
        </body>
        </html>
      HTML

      dialog.set_html(html_content)

      dialog.add_action_callback("save_attributes") do |action_context, params|
        apartment_type_name, apartment_data_json = params.split('@', 2)
        apartment_data = JSON.parse(apartment_data_json)
        model = Sketchup.active_model

        # Retrieve the current list of apartment type names
        apartment_type_names = model.get_attribute('aparment_type_data', APARTMENT_TYPE_LIST_KEY, [])
        
        if apartment_type_names.include?(apartment_type_name)
          result = UI.messagebox("户型名已存在。是否覆盖？ Apartment type name already exists. Overwrite?", MB_YESNO)
          return if result == IDNO
        else
          apartment_type_names << apartment_type_name
          model.set_attribute('aparment_type_data', APARTMENT_TYPE_LIST_KEY, apartment_type_names)
        end

        model.set_attribute('aparment_type_data', apartment_type_name, apartment_data.to_json)
        puts "Stored data for #{apartment_type_name}: #{apartment_data.inspect}"  # Debugging line

        # Create or update the apartment component
        create_apartment_component(apartment_data)

        UI.messagebox("属性已保存 Attributes saved: " + apartment_data['apartment_type_name'])
        update_saved_apartment_types(dialog)
      end

      dialog.add_action_callback("delete_apartment_type") do |action_context, apartment_type_name|
        model = Sketchup.active_model
        model.delete_attribute('aparment_type_data', apartment_type_name)
        
        apartment_type_names = model.get_attribute('aparment_type_data', APARTMENT_TYPE_LIST_KEY, [])
        apartment_type_names.delete(apartment_type_name)
        model.set_attribute('aparment_type_data', APARTMENT_TYPE_LIST_KEY, apartment_type_names)

        puts "Deleted data for #{apartment_type_name}"  # Debugging line
        UI.messagebox("户型已删除 Apartment type deleted: " + apartment_type_name)
        update_saved_apartment_types(dialog)
      end

      dialog.add_action_callback("load_apartment_type") do |action_context, apartment_type_name|
        model = Sketchup.active_model
        apartment_data_json = model.get_attribute('aparment_type_data', apartment_type_name)
        if apartment_data_json
          dialog.execute_script("populateApartmentType('#{apartment_data_json}')")
        else
          UI.messagebox("未找到该户型数据 Apartment type data not found.")
        end
      end

      dialog.add_action_callback("get_saved_apartment_types") do |action_context|
        update_saved_apartment_types(dialog)
      end

      dialog.show
    end

    def self.ensure_layers_exist
      model = Sketchup.active_model
      ['liq_0', 'liq_color_mass', 'liq_architecture', 'liq_sunlight', 'liq_phasing', 'liq_price'].each do |layer_name|
        model.layers.add(layer_name) unless model.layers[layer_name]
      end
      model.layers['liq_0'].visible = true
    end


    def self.create_apartment_component(apartment_data)
      model = Sketchup.active_model
      definitions = model.definitions
      
      component_name = apartment_data['apartment_type_name']
      puts "Creating/Updating component: #{component_name}"  # Debug line
      
      model.start_operation('Create/Update Apartment Component', true)
    
      # Create or get the component definition
      apartment_def = definitions[component_name] || definitions.add(component_name)
      
      # Clear existing entities
      apartment_def.entities.clear!
      puts "Cleared existing entities. Entity count: #{apartment_def.entities.size}"  # Debug line
    
      # Create layers if they don't exist
      layers = ['liq_color_mass', 'liq_architecture', 'liq_sunlight', 'liq_phasing', 'liq_price']
      layers.each do |layer_name|
        puts "Setting up layer: #{layer_name}"  # Debug line
        layer = model.layers[layer_name] || model.layers.add(layer_name)
        puts "Layer #{layer_name} is defined as: #{layer}"  # Debug line
        layer.visible = true
        puts "Layer #{layer_name} visibility set to: #{layer.visible?}"  # Debug line
      end
    
      # Get or create a default white material
      default_material = model.materials["Default White"] || model.materials.add("Default White")
      default_material.color = Sketchup::Color.new(255, 255, 255)
    
      # Store the current active layer
      original_active_layer = model.active_layer
      puts "Original active layer: #{original_active_layer.name}"  # Debug line
    
      # Create geometry for each layer
      puts "Layers to process: #{layers.join(', ')}"  # Debug line
      layers.each do |layer_name|
        puts "\nProcessing layer: #{layer_name}"  # Debug line
    
        # Temporarily set the current layer as active
        model.active_layer = model.layers[layer_name]
        puts "Current active layer set to: #{model.active_layer.name}"  # Debug line
    
        group = apartment_def.entities.add_group
        puts "Created group for layer #{layer_name}. Group ID: #{group.entityID}"  # Debug line
        
        # Create the geometry for the apartment within the group
        width = apartment_data['width'].to_f.m
        depth = apartment_data['depth'].to_f.m
        height = 3.m  # Assuming a standard floor height of 3 meters
    
        begin
          face = group.entities.add_face([0, 0, 0], [0, depth, 0], [width, depth, 0], [width, 0, 0])
          face.pushpull(-height)
          puts "Created face for layer: #{layer_name}. Face ID: #{face.entityID}"  # Debug line
        rescue => e
          puts "Error creating face for layer #{layer_name}: #{e.message}"  # Debug line
        end
    
        if layer_name == 'liq_color_mass'
          # Create a new material only for liq_color_mass
          material = model.materials.add("#{component_name}_color_mass")
          category = apartment_data['apartment_category']
          if ['商铺', '办公', '公寓'].include?(category)
            material.color = Sketchup::Color.new(255, 0, 0)  # Red for commercial, office, and apartment
          else
            hue = (apartment_data['area'].to_f - 50) * 2 % 360
            rgb = hsl_to_rgb(hue, 100, 50)
            material.color = Sketchup::Color.new(*rgb)
          end
        else
          # Use the default white material for other layers
          material = default_material
        end
        
        group.entities.grep(Sketchup::Face).each { |entity| entity.material = material }
        puts "Applied material to faces in group. Face count: #{group.entities.grep(Sketchup::Face).size}"  # Debug line
      end
    
      # Restore the original active layer
      model.active_layer = original_active_layer
      puts "Restored original active layer: #{model.active_layer.name}"  # Debug line
    
      # Add attributes to the component
      apartment_def.set_attribute('apartment_data', 'area', apartment_data['area'])
      apartment_def.set_attribute('apartment_data', 'category', apartment_data['apartment_category'])
      apartment_def.set_attribute('apartment_data', 'product_baseline_unit_cost', apartment_data['product_baseline_unit_cost_before_allocation'])
    
      model.commit_operation
    
      puts "Component creation completed. Total entities in component: #{apartment_def.entities.size}"  # Debug line
      apartment_def
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
      model.layers['liq_0'].visible = true  # Always keep 'liq_0' visible
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
      apartment_type_names = model.get_attribute('aparment_type_data', APARTMENT_TYPE_LIST_KEY, [])
      dialog.execute_script("updateSavedApartmentTypes(#{apartment_type_names.to_json})")
    end
  end
end

# Real_Estate_Optimizer::ApartmentManager.show_dialog

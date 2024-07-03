require 'sketchup.rb'
require 'json'

module Urban_Banal
  module Real_Estate_Optimizer
    module DataHandler
      def self.save_project(data_json)
        model = Sketchup.active_model
        model.set_attribute('Urban_Banal', 'project_data', data_json)
        UI.messagebox("Data saved successfully!")
      end

      def self.get_project
        model = Sketchup.active_model
        data_json = model.get_attribute('Urban_Banal', 'project_data', '{}')
        data_json
      end
    end
  end
end

# Callbacks from HTML dialogs
dialog = UI::HtmlDialog.new(
  {
    :dialog_title => "输入管理",
    :preferences_key => "com.example.input_dialog",
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

html_content = <<~HTML
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <script>
    function populateForm() {
      document.getElementById('site_area').value = project.inputs.site_area;
      document.getElementById('FAR').value = project.inputs.FAR;
      document.getElementById('amenity_GFA_in_FAR').value = project.inputs.amenity_GFA_in_FAR;
      document.getElementById('management_fee').value = project.inputs.management_fee;
      document.getElementById('sales_fee').value = project.inputs.sales_fee;
      document.getElementById('land_cost').value = project.inputs.land_cost;
      // Populate other fields as needed
    }

    function saveAttributes() {
      project.inputs.site_area = parseFloat(document.getElementById('site_area').value);
      project.inputs.FAR = parseFloat(document.getElementById('FAR').value);
      project.inputs.amenity_GFA_in_FAR = parseFloat(document.getElementById('amenity_GFA_in_FAR').value);
      project.inputs.management_fee = parseFloat(document.getElementById('management_fee').value);
      project.inputs.sales_fee = parseFloat(document.getElementById('sales_fee').value);
      project.inputs.land_cost = parseFloat(document.getElementById('land_cost').value);
      // Save other fields as needed
      project.saveToSketchUp();
    }

    window.onload = function () {
      window.location = 'skp:get_project';
    }
  </script>
</head>
<body>
  <h2>输入管理</h2>
  <div class="form-section">
    <label for="site_area">用地面积 (平米)</label>
    <input type="number" id="site_area" value="50000">
    
    <label for="FAR">容积率 (FAR)</label>
    <input type="number" id="FAR" value="2.0">
    
    <label for="amenity_GFA_in_FAR">计容配套面积 (平米)</label>
    <input type="number" id="amenity_GFA_in_FAR" value="1400">
    
    <label for="management_fee">管理费用 (%)</label>
    <input type="number" id="management_fee" value="0.03">
    
    <label for="sales_fee">销售费用 (%)</label>
    <input type="number" id="sales_fee" value="0.25">
    
    <label for="land_cost">土地成本 (万元)</label>
    <input type="number" id="land_cost" value="30000">
    
    <!-- Add other input fields similarly -->
  </div>
  <button onclick="saveAttributes()">保存属性 Save Attributes</button>
</body>
</html>

HTML

dialog.set_html(html_content)

dialog.add_action_callback("save_project") do |action_context, data_json|
  Urban_Banal::Real_Estate_Optimizer::DataHandler.save_project(data_json)
end

dialog.add_action_callback("get_project") do |action_context|
  data_json = Urban_Banal::Real_Estate_Optimizer::DataHandler.get_project
  dialog.execute_script("project.loadFromSketchUp(#{data_json.to_json})")
end

dialog.show

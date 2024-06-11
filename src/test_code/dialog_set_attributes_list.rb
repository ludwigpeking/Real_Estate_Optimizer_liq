require 'sketchup.rb'
require 'json'

module Urban_Banal
  module Real_Estate_Optimizer
    def self.show_dialog
      dialog = UI::HtmlDialog.new(
        {
          :dialog_title => "Input Attribute",
          :preferences_key => "com.example.attribute_input",
          :scrollable => true,
          :resizable => true,
          :width => 400,
          :height => 300,
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
            label, input { display: block; margin-bottom: 10px; }
            .far-input { display: flex; align-items: center; }
            .far-input input { margin-right: 10px; }
            .far-input button { width: 30px; height: 30px; border-radius: 50%; border: none; font-size: 20px; }
            .far-input button.add { background-color: #4CAF50; color: white; }
            .far-input button.remove { background-color: #f44336; color: white; }
          </style>
          <script>
            function saveAttributes() {
              var farValues = [];
              document.querySelectorAll('.far-input input').forEach(function(input) {
                farValues.push(input.value);
              });
              window.location = 'skp:save_attributes@' + JSON.stringify(farValues);
            }

            function addFarInput(value = '') {
              var container = document.getElementById('farContainer');
              var index = container.children.length;
              var div = document.createElement('div');
              div.className = 'far-input';
              div.innerHTML = '<input type="text" value="' + value + '" placeholder="输入容积率 ' + (index + 1) + '">'
                + '<button class="add" onclick="addFarInput()">+</button>';
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

            window.onload = function() {
              addFarInput();
            }
          </script>
        </head>
        <body>
          <h2>输入容积率</h2>
          <div id="farContainer"></div>
          <button onclick="saveAttributes()">保存属性 Save Attributes</button>
        </body>
        </html>
      HTML

      dialog.set_html(html_content)

      dialog.add_action_callback("save_attributes") do |action_context, far_values_json|
        far_values = JSON.parse(far_values_json)
        model = Sketchup.active_model
        model.set_attribute('Urban_Banal', 'FAR_list', far_values)
        UI.messagebox("属性已保存 Attributes saved: 容积率 (FAR_list) = #{far_values.join(', ')}")
      end

      dialog.show
    end
  end
end

Urban_Banal::Real_Estate_Optimizer.show_dialog

require 'sketchup.rb'

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
          </style>
          <script>
            function saveAttribute() {
              var attrValue = document.getElementById('attrValue').value;
              window.location = 'skp:save_attribute@' + attrValue;
            }
          </script>
        </head>
        <body>
          <h2>输入容积率</h2>
          <label for="attrValue">容积率 (FAR):</label>
          <input type="text" id="attrValue">
          <button onclick="saveAttribute()">保存属性 Save Attribute</button>
        </body>
        </html>
      HTML

      dialog.set_html(html_content)

      dialog.add_action_callback("save_attribute") do |action_context, attr_value|
        attr_name = 'FAR'
        model = Sketchup.active_model
        model.set_attribute('Urban_Banal', attr_name, attr_value)
        UI.messagebox("属性已保存 Attribute saved: 容积率 (FAR) = #{attr_value}")
      end

      dialog.show
    end
  end
end

Urban_Banal::Real_Estate_Optimizer.show_dialog

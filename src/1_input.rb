require 'sketchup'
require 'json'
require_relative '1_data_handler'
require_relative '0_default_values'

module Real_Estate_Optimizer
  module Input
    def self.show_dialog
      dialog = UI::HtmlDialog.new(
        {
          :dialog_title => "项目基本信息输入 Project General Inputs",
          :preferences_key => "com.example.project_inputs",
          :scrollable => true,
          :resizable => true,
          :width => 800,
          :height => 800,
          :left => 100,
          :top => 100,
          :min_width => 600,
          :min_height => 600,
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
          let project = #{DefaultValues::PROJECT_DEFAULTS.to_json};

          function loadProjectData(data) {
            if (data) {
              project = JSON.parse(data);
            }
  
            for (let key in project.inputs) {
              if (document.getElementById(key)) {
                document.getElementById(key).value = project.inputs[key];
              }
            }
  
            populatePaymentTable('land_cost_payment', project.inputs.land_cost_payment);
            populatePaymentTable('unsaleable_amenity_cost_payment', project.inputs.unsaleable_amenity_cost_payment);
            populatePropertyLines(project.propertyLines);
          }

          function populatePropertyLines(lines) {
            propertyLines = lines.sort((a, b) => {
              const aMatch = a.name.match(/(\d+)([A-Za-z]*)/);
              const bMatch = b.name.match(/(\d+)([A-Za-z]*)/);
              if (aMatch && bMatch) {
                const aNum = parseInt(aMatch[1]);
                const bNum = parseInt(bMatch[1]);
                if (aNum !== bNum) return aNum - bNum;
                return aMatch[2].localeCompare(bMatch[2]);
              }
              return a.name.localeCompare(b.name);
            });
            
            const container = document.getElementById('propertyLinesContainer');
            container.innerHTML = '';
            propertyLines.forEach((line, index) => {
              container.innerHTML += `
                <div>
                  <h4>${line.name} (${line.area} m²)</h4>
                  <label for="amenity_GFA_in_FAR_${index}">计容配套面积 Amenity GFA in FAR (平米):</label>
                  <input type="number" id="amenity_GFA_in_FAR_${index}" 
                         value="${line.amenity_GFA_in_FAR || 0}" 
                         min="0" step="1"
                         oninput="updateTotalAmenityGFA()">
                </div>
              `;
            });
            
            // Call initially to set the total
            updateTotalAmenityGFA();
            updateAmenityGFANote();
          }

          function updateTotalAmenityGFA() {
            const totalAmenityGFA = propertyLines.reduce((sum, _, index) => {
              const input = document.getElementById(`amenity_GFA_in_FAR_${index}`);
              return sum + (parseFloat(input.value) || 0);
            }, 0);
            
            // Update the general input
            const generalAmenityInput = document.getElementById('amenity_GFA_in_FAR');
            generalAmenityInput.value = totalAmenityGFA;
            // Make it readonly if there are property lines
            generalAmenityInput.readOnly = propertyLines.length > 0;
            // Add visual indication that it's calculated
            generalAmenityInput.style.backgroundColor = propertyLines.length > 0 ? '#f0f0f0' : 'white';
          }

          function populatePaymentTable(tableId, data) {
            const table = document.getElementById(tableId);
            table.innerHTML = '';

            for (let year = 1; year <= 6; year++) {
              let row = table.insertRow();
              for (let month = 1; month <= 12; month++) {
                let cell = row.insertCell();
                let input = document.createElement('input');
                input.type = 'number';
                input.step = '0.01';
                input.min = '0';
                input.max = '1';
                input.value = data[(year - 1) * 12 + (month - 1)];
                input.style.width = '40px';
                input.oninput = function() { validatePaymentSum(tableId); };
                cell.appendChild(input);
              }
            }
            validatePaymentSum(tableId);
          }

          function validatePaymentSum(tableId) {
            const inputs = document.querySelectorAll(`#${tableId} input`);
            let sum = Array.from(inputs).reduce((acc, input) => acc + Number(input.value), 0);
            document.getElementById(`${tableId}_sum`).textContent = sum.toFixed(2);
            document.getElementById(`${tableId}_error`).style.display = Math.abs(sum - 1) < 0.0001 ? 'none' : 'block';
          }
          function saveProjectData() {
            for (let key in project.inputs) {
              if (document.getElementById(key)) {
                if (key === 'amenity_GFA_in_FAR' && propertyLines.length > 0) {
                  // For amenity GFA, use the calculated total when property lines exist
                  project.inputs[key] = parseFloat(document.getElementById(key).value);
                } else {
                  project.inputs[key] = parseFloat(document.getElementById(key).value);
                }
              }
            }
          
            project.propertyLines = propertyLines.map((line, index) => ({
              ...line,
              amenity_GFA_in_FAR: parseFloat(document.getElementById(`amenity_GFA_in_FAR_${index}`).value) || 0
            }));
          
            project.inputs.land_cost_payment = getPaymentData('land_cost_payment');
            project.inputs.unsaleable_amenity_cost_payment = getPaymentData('unsaleable_amenity_cost_payment');
          
            const data = JSON.stringify(project);
            window.location = 'skp:save_project_data@' + encodeURIComponent(data);
          }

          function toggleSection(sectionId) {
            const section = document.getElementById(sectionId);
            section.classList.toggle('active');
            const toggle = section.querySelector('.section-toggle');
            toggle.textContent = section.classList.contains('active') ? '-' : '+';
          }

          function updateAmenityGFANote() {
            const note = document.getElementById('amenity_GFA_calculation_note');
            note.style.display = propertyLines.length > 0 ? 'inline' : 'none';
          }

          function getPaymentData(tableId) {
            return Array.from(document.querySelectorAll(`#${tableId} input`)).map(input => parseFloat(input.value));
          }

          window.onload = function() {
            // Keep Essential Information expanded by default
            document.getElementById('essential').classList.add('active');
            document.querySelector('#essential .section-toggle').textContent = '-';
            
            // Add click handlers to all section headers
            document.querySelectorAll('.section-header').forEach(header => {
              header.addEventListener('click', () => {
                const section = header.parentElement;
                toggleSection(section.id);
              });
            });
          
            // Load project data
            window.location = 'skp:load_project_data';
          }
        </script>
      </head>
      <body>
  <div class="section" id="essential">
    <div class="section-header">
      <div class="section-toggle">-</div>
      <h3>核心信息 Essential Information</h3>
    </div>
    <div class="section-content">
      <div class="form-group">
        <label for="site_area">总用地面积 Site Area (平米):</label>
        <input type="number" id="site_area" min="0" step="1">
      </div>
      <div class="form-group">
        <label for="FAR">容积率 FAR:</label>
        <input type="number" id="FAR" min="0" step="0.01">
      </div>
      <div class="form-group">
        <label for="discount_rate">测算用折现率 General Discount Rate:</label>
        <input type="number" id="discount_rate" min="0" step="0.01">
      </div>
      <div class="form-group">
        <label for="land_cost">土地成本 Land Cost (万元):</label>
        <input type="number" id="land_cost" min="0" step="1">
      </div>
      <div class="form-group">
        <label for="unsaleable_amenity_cost">不可售配套成本 Unsaleable Amenity Cost (万元):</label>
        <input type="number" id="unsaleable_amenity_cost" min="0" step="1">
      </div>
    </div>
  </div>

  <div class="section" id="property-lines">
    <div class="section-header">
      <div class="section-toggle">+</div>
      <h3>地块列表 Property Lines</h3>
    </div>
    <div class="section-content">
      <div id="propertyLinesContainer"></div>
    </div>
  </div>

  <div class="section" id="amenity-parking">
    <div class="section-header">
      <div class="section-toggle">+</div>
      <h3>配套、车位有关信息 Amenity, Parking Related Info</h3>
    </div>
    <div class="section-content">
      <div class="form-group">
        <label for="amenity_GFA_in_FAR">计容配套面积 Amenity GFA in FAR (平米):</label>
        <input type="number" id="amenity_GFA_in_FAR" min="0" step="1">
        <span id="amenity_GFA_calculation_note" style="display: none; margin-left: 10px; color: #666; font-size: 0.9em;">
          (自动计算自地块列表 Calculated from Property Lines)
        </span>
      </div>
      <div class="form-group">
        <label for="commercial_percentage_upper_limit">商业比例上限 Commercial Percentage Upper Limit:</label>
        <input type="number" id="commercial_percentage_upper_limit" min="0" max="1" step="0.01">
      </div>
      <div class="form-group">
        <label for="commercial_percentage_lower_limit">商业比例下限 Commercial Percentage Lower Limit:</label>
        <input type="number" id="commercial_percentage_lower_limit" min="0" max="1" step="0.01">
      </div>
      <div class="form-group">
        <label for="parking_lot_average_price">停车位平均价格 Parking Lot Average Price (元):</label>
        <input type="number" id="parking_lot_average_price" min="0" step="0.01">
      </div>
      <div class="form-group">
        <label for="parking_lot_sales_velocity">停车位销售速度 Parking Lot Sales Velocity (个/月):</label>
        <input type="number" id="parking_lot_sales_velocity" min="0" step="1">
      </div>
    </div>
  </div>

    <div class="section" id="cost-info">
    <div class="section-header">
      <div class="section-toggle">+</div>
      <h3>成本信息 Cost Information</h3>
    </div>
    <div class="section-content">
      <div class="form-group">
        <label for="management_fee">管理费率 Management Fee Rate:</label>
        <input type="number" id="management_fee" min="0" max="1" step="0.001">
      </div>
      <div class="form-group">
        <label for="sales_fee">销售费率 Sales Fee Rate:</label>
        <input type="number" id="sales_fee" min="0" max="1" step="0.001">
      </div>
      <div class="form-group">
        <label for="product_baseline_unit_cost_before_allocation">产品基准单位成本 Product Baseline Unit Cost (元/平米):</label>
        <input type="number" id="product_baseline_unit_cost_before_allocation" min="0" step="1">
      </div>
      <div class="form-group">
        <label for="basement_unit_cost_before_allocation">地下室单位成本 Basement Unit Cost (元/平米):</label>
        <input type="number" id="basement_unit_cost_before_allocation" min="0" step="1">
      </div>
    </div>
  </div>

  <div class="section" id="tax-info">
    <div class="section-header">
      <div class="section-toggle">+</div>
      <h3>税费信息 Tax Information</h3>
    </div>
    <div class="section-content">
      <div class="form-group">
        <label for="VAT_surchage_rate">增值税附加税率 VAT Surcharge Rate:</label>
        <input type="number" id="VAT_surchage_rate" min="0" max="1" step="0.0001">
      </div>
      <div class="form-group">
        <label for="corp_pretax_gross_profit_rate_threshould">所得税预征收毛利率 Corp Pretax Gross Profit Rate Threshold:</label>
        <input type="number" id="corp_pretax_gross_profit_rate_threshould" min="0" max="1" step="0.01">
      </div>
      <div class="form-group">
        <label for="corp_tax_rate">企业所得税率 Corp Tax Rate:</label>
        <input type="number" id="corp_tax_rate" min="0" max="1" step="0.01">
      </div>
      <div class="form-group">
        <label for="LVIT_provisional_rate">土地增值税预缴税率 LVIT Provisional Rate:</label>
        <input type="number" id="LVIT_provisional_rate" min="0" max="1" step="0.01">
      </div>
    </div>
  </div>

  <div class="section" id="land-cost-payment">
    <div class="section-header">
      <div class="section-toggle">+</div>
      <h3>土地成本支付计划（72个月） Land Cost Payment (72 months)</h3>
    </div>
    <div class="section-content">
      <table id="land_cost_payment"></table>
      <div>总和 Sum: <span id="land_cost_payment_sum">0</span></div>
      <div id="land_cost_payment_error" class="error" style="display: none;">总和必须等于1 Sum must equal 1</div>
    </div>
  </div>

  <div class="section" id="amenity-cost-payment">
    <div class="section-header">
      <div class="section-toggle">+</div>
      <h3>不可售配套成本支付计划（72个月） Unsaleable Amenity Cost Payment (72 months)</h3>
    </div>
    <div class="section-content">
      <table id="unsaleable_amenity_cost_payment"></table>
      <div>总和 Sum: <span id="unsaleable_amenity_cost_payment_sum">0</span></div>
      <div id="unsaleable_amenity_cost_payment_error" class="error" style="display: none;">总和必须等于1 Sum must equal 1</div>
    </div>
  </div>

  <div style="text-align: center; margin: 20px 0;">
      <button class="save-button" onclick="saveProjectData()">
          <span style="font-size: 15px;">保存项目数据</span><br>
          <span style="font-size: 13px;">Save Project Data</span>
      </button>
  </div>
</body>
</html>

      
      HTML

      dialog.set_html(html_content)

      dialog.add_action_callback("load_project_data") do |action_context|
        project_data = Real_Estate_Optimizer::DataHandler.load_project_data
        dialog.execute_script("loadProjectData('#{project_data.to_json.gsub("'", "\\'")}');")
      end

      dialog.add_action_callback("save_project_data") do |action_context, data_json|
        Real_Estate_Optimizer::DataHandler.save_project_data(data_json)
        UI.messagebox("项目数据保存成功！ Project data saved successfully!")
      end

      dialog.show
    end
  end   
end

# Call this method to show the dialog when necessary
# Real_Estate_Optimizer::Input.show_dialog

# code to test the input dialog
# puts JSON.parse(Sketchup.active_model.get_attribute('project_data', 'data', '{}'), symbolize_names: true).fetch(:inputs, {}).map { |k, v| "#{k}: #{v.inspect}" }.join("\n")

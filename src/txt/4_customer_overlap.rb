require_relative '4_apartment_manager'

module Real_Estate_Optimizer
  module CustomerOverlap
    def self.show_dialog
      dialog = UI::HtmlDialog.new(
        {
          dialog_title: "客户重叠计算 Customer Overlap Calculator",
          preferences_key: "com.example.customer_overlap",
          scrollable: true,
          resizable: true,
          width: 800,
          height: 600,
          left: 100,
          top: 100,
          min_width: 400,
          min_height: 400,
          style: UI::HtmlDialog::STYLE_DIALOG
        }
      )

      html_content = <<-HTML
   <!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <style>
        .apartment-info {
            margin: 7px;
            padding: 7px;
            border: 1px solid #ccc;
            border-radius: 4px;
        }
        .apartment-name {
            font-weight: bold;
            margin-bottom: 5px;
        }
        .sales-info {
            color: #666;
        }
        .grid-table {
            border-collapse: collapse;
            margin-bottom: 20px;
            width: 100%;
        }
        .grid-table th, .grid-table td {
            border: 1px solid #ccc;
            padding: 8px 12px;
            text-align: center;
        }
        .grid-table th {
            background-color: #f4f4f4;
        }
        .results-section {
            display: flex;
            flex-direction: column;
            align-items: center;
        }
        #myChart {
            height: 400px !important;
            width: 100% !important;
            max-width: 800px !important;
        }
    </style>

</head>
<body>
    <div id="apartmentContainer"></div>
    <div class="overlap-section">
        <h3>客户重叠矩阵 Customer Overlap Matrix</h3>
        <p class="note">Enter overlap rates between apartment types. Values between 0 and 1.</p>
        <table class="grid-table" id="overlapTable"></table>
    </div>
    <button id="calcBtn" onclick="calculateAdjustedSales()">Calculate</button>
   <div class="results-section" id="resultsSection">
      <h3>Results</h3>
      <div id="salesResults"></div>
      <canvas id="myChart"></canvas>
  </div>


    <script>
    function displayApartmentData(data) {
      // First display apartment info
      const container = document.getElementById('apartmentContainer');
      container.innerHTML = '';
      console.log("Displaying apartment data:", data);
      
      Object.entries(data).forEach(([name, info]) => {
          if (info.sales_scenes && info.sales_scenes.length > 0) {
              const scene = info.sales_scenes[0];
              const div = document.createElement('div');
              div.className = 'apartment-info';
              div.innerHTML = `
                  <div class="apartment-name">${name}</div>
                  <div class="sales-info">
                      Price: ${scene.price} 元/㎡<br>
                      Volume: ${scene.volumn} 套/月
                  </div>
              `;
              container.appendChild(div);
          }
      });
  
      // Then handle overlap matrix
      const types = Object.keys(data);
      window.apartmentVolumes = {};
      types.forEach(name => {
          if (data[name].sales_scenes && data[name].sales_scenes.length > 0) {
              window.apartmentVolumes[name] = data[name].sales_scenes[0].volumn;
          }
      });
      createOverlapTable(types);
  }
  


function createOverlapTable(types) {
    const table = document.getElementById('overlapTable');
    table.innerHTML = '';
    
    // Create header row
    const headerRow = document.createElement('tr');
    headerRow.appendChild(document.createElement('th'));
    types.forEach(type => {
        const th = document.createElement('th');
        th.textContent = type;
        headerRow.appendChild(th);
    });
    table.appendChild(headerRow);
    
    // Create matrix rows
    types.forEach((rowType, i) => {
        const row = document.createElement('tr');
        const header = document.createElement('th');
        header.textContent = rowType;
        row.appendChild(header);
        
        types.forEach((colType, j) => {
            const cell = document.createElement('td');
            if (i === j) {
                cell.textContent = '—';
            } else if (j > i) {
                const input = document.createElement('input');
                input.type = 'number';
                input.min = '0';
                input.max = '1';
                input.step = '0.1';
                input.id = `overlap_${rowType}_${colType}`;
                input.className = 'overlap-input';
                input.value = '0.0';
                input.onchange = () => validateOverlap(input);
                cell.appendChild(input);
            } else {
                const input = document.createElement('input');
                input.type = 'number';
                input.id = `overlap_${rowType}_${colType}`;
                input.className = 'overlap-input read-only';
                input.value = '0.0';
                input.readOnly = true;
                cell.appendChild(input);
            }
            row.appendChild(cell);
        });
        table.appendChild(row);
    });
}

function validateOverlap(input) {
    let value = parseFloat(input.value) || 0;
    value = Math.min(1, Math.max(0, value));
    input.value = value.toFixed(2);
    
    const parts = input.id.split('_');
    if (parts.length === 3) {
        const type1 = parts[1];
        const type2 = parts[2];
        const params = JSON.stringify({type1: type1, type2: type2});
        window.location = 'skp:get_apartment_volumes@' + encodeURIComponent(params);
    }
}

  function enforceOverlapConstraints(type1, type2) {
      const vol1 = window.apartmentVolumes[type1];
      const vol2 = window.apartmentVolumes[type2];
      const input = document.getElementById(`overlap_${type1}_${type2}`);
      const value = parseFloat(input.value) || 0;
      const symmetricInput = document.getElementById(`overlap_${type2}_${type1}`);
      
      if (symmetricInput && vol1 && vol2) {
          const symmetric_value = (value * vol1) / vol2;
          symmetricInput.value = Math.min(1, symmetric_value).toFixed(2);
      }
  }
  function calculateAdjustedSales() {
    const types = Array.from(document.querySelectorAll('#overlapTable th'))
        .slice(1)
        .map(th => th.textContent);
    
    if (types.length === 0) return;
    
    const demands = {};
    const overlaps = {};
    
    // Get volumes from global object
    types.forEach(type => {
        demands[type] = window.apartmentVolumes[type] || 0;
        overlaps[type] = {};
        types.forEach(otherType => {
            if (type !== otherType) {
                const input = document.getElementById(`overlap_${type}_${otherType}`);
                if (input) {
                    overlaps[type][otherType] = parseFloat(input.value) || 0;
                }
            }
        });
    });
    
    // Calculate adjusted sales
    const adjustedSales = {};
    let totalSales = 0;
    
    types.forEach(type => {
        let adjustment = 0;
        types.forEach((otherType, j) => {
            // Only consider upper triangle of overlap matrix
            if (type !== otherType && types.indexOf(type) < j) {
                const overlap = overlaps[type][otherType] || 0;
                if (demands[type] + demands[otherType] > 0) {
                    adjustment += (overlap * (demands[otherType] * demands[type])) / 
                                (demands[type] + demands[otherType]);
                }
            }
        });
        adjustedSales[type] = Math.max(0, demands[type] - adjustment);
        totalSales += adjustedSales[type];
    });
    
    // Update results
    const resultsDiv = document.getElementById('salesResults');
    const container = document.getElementById('resultsSection');
    container.style.display = 'block';
    
    let html = `<strong>总调整销量 Total Adjusted Sales:</strong> ${totalSales.toFixed(2)} 套/月<br>`;
    html += '<strong>销售分布 Sales Distribution:</strong><br>';
    
    Object.entries(adjustedSales).forEach(([type, sales]) => {
        html += `- ${type}: ${sales.toFixed(2)} 套/月<br>`;
    });
    
    resultsDiv.innerHTML = html;
}


function updateResults(totalSales, adjustedSales) {
  const resultsDiv = document.getElementById('salesResults');
  const container = document.getElementById('resultsSection');
  
  
    container.style.display = 'block';
    
    let html = `<strong>总调整销量 Total Adjusted Sales:</strong> ${totalSales.toFixed(2)} 套/月<br>`;
    html += '<strong>销售分布 Sales Distribution:</strong><br>';
    
    const labels = [];
    const data = [];
    const backgroundColors = [];
    
    Object.entries(adjustedSales).forEach(([type, sales], index) => {
        html += `- ${type}: ${sales.toFixed(2)} 套/月<br>`;
        labels.push(type);
        data.push(sales.toFixed(2));
        const hue = ((index * 360) / Object.keys(adjustedSales).length) % 360;
        backgroundColors.push(`hsl(${hue}, 70%, 50%)`);
    });
    
    resultsDiv.innerHTML = html;
    updateChart(labels, data, backgroundColors);
}

function updateChart(labels, data, backgroundColors) {
    const ctx = document.getElementById('salesChart').getContext('2d');
    
    if (window.salesChartInstance) {
        window.salesChartInstance.destroy();
    }
    
    window.salesChartInstance = new Chart(ctx, {
        type: 'bar',
        data: {
            labels: labels,
            datasets: [{
                label: '销售量 (套/月)',
                data: data,
                backgroundColor: backgroundColors,
                barPercentage: 0.3,
                categoryPercentage: 0.7
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            scales: {
                y: {
                    beginAtZero: true
                }
            },
            plugins: {
                legend: {
                    display: false
                },
                title: {
                    display: true,
                    text: '户型销售分布',
                    font: { size: 16 }
                }
            }
        }
    });
}
window.onload = function() {
  console.log("Window loaded, requesting apartment data...");
  window.location = 'skp:get_apartment_data';
}
</script>
</body>
</html>

      HTML

      dialog.set_html(html_content)

      dialog.add_action_callback("get_apartment_data") do |action_context|
        model = Sketchup.active_model
        apartment_types = {}
        
        # Get all apartment type names - directly use the list
        type_names = model.get_attribute('apartment_type_data', ApartmentManager::APARTMENT_TYPE_LIST_KEY, [])
        puts "Found apartment types: #{type_names.inspect}"
        
        # Get data for each apartment type
        type_names.each do |name|
          data_json = model.get_attribute('apartment_type_data', name)
          if data_json
            apartment_types[name] = JSON.parse(data_json)
            puts "Loaded data for #{name}: #{apartment_types[name].inspect}"
          end
        end
      
        dialog.execute_script("displayApartmentData(#{apartment_types.to_json})")
      end

      dialog.add_action_callback("get_apartment_volumes") do |action_context, params_json|
        begin
          model = Sketchup.active_model
          params = JSON.parse(URI.decode_www_form_component(params_json))
          type1 = params['type1']
          type2 = params['type2']
          
          data1_raw = model.get_attribute('apartment_type_data', type1)
          data2_raw = model.get_attribute('apartment_type_data', type2)
          
          data1 = JSON.parse(data1_raw || '{}')
          data2 = JSON.parse(data2_raw || '{}')
          
          vol1 = data1.dig('sales_scenes', 0, 'volumn') || 0
          vol2 = data2.dig('sales_scenes', 0, 'volumn') || 0
          
          puts "Retrieved volumes: #{type1}=#{vol1}, #{type2}=#{vol2}"
          
          js_command = "enforceOverlapConstraints('#{type1}', '#{type2}');"


          dialog.execute_script(js_command)
        rescue => e
          puts "Error in get_apartment_volumes: #{e.message}"
          puts e.backtrace
        end
      end
      
      

      dialog.show
    end


  end
end

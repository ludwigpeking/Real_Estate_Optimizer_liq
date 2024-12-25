require_relative '8_cashflow'  
require 'csv'
require 'json'
require_relative  '8_traversal_utils'
require_relative '8_financial_calculations'


module Real_Estate_Optimizer
  module Output
    def self.show_dialog
      dialog = UI::HtmlDialog.new(
        {
          :dialog_title => "Project Output",
          :preferences_key => "com.example.real_estate_optimizer_output",
          :scrollable => true,
          :resizable => true,
          :width => 800,
          :height => 600,
          :left => 100,
          :top => 100
        }
      )

      html_content = <<-HTML
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="UTF-8">
          <title>Project Output</title>
          <style>
          body { 
            font-family: Tahoma, sans-serif; 
            font-size: 12px;
            padding: 20px; 
          }
          
          :lang(zh) {
            font-family: 'Microsoft YaHei', sans-serif; 
          }
          
          /* Tab styles */
          .tab {
            overflow: hidden;
            border: 1px solid #ccc;
            background-color: #f1f1f1;
            margin-bottom: 8px;
          }
          
          .tab button {
            background-color: inherit;
            float: left;
            border: none;
            outline: none;
            cursor: pointer;
            padding: 8px 12px;
            transition: 0.3s;
            font-size: 12px;
          }
          
          .tab button:hover { background-color: #ddd; }
          .tab button.active { background-color: #ccc; }
          
          .tabcontent {
            display: none;
            padding: 6px 12px;
            border: 1px solid #ccc;
            border-top: none;
          }
          
          /* Table styles */
          table {
            border-collapse: collapse;
            width: 100%;
            margin: 8px 0;
          }
          
          th, td {
            border: 1px solid #ddd;
            padding: 4px 6px;
            text-align: right;
            font-size: 12px;
          }
          
          th {
            background-color: #f2f2f2;
            font-weight: normal;
          }
          
          /* Property line stats */
          .property-line-stats {
            margin-top: 12px;
          }
          
          /* Refresh button */
          .refresh-button {
            position: absolute;
            top: 20px;
            right: 20px;
            padding: 4px 8px;
            background-color: #f00;
            color: white;
            border: none;
            border-radius: 3px;
            cursor: pointer;
            font-size: 12px;
          }
          
          /* Headers */
          h3 {
            font-size: 13px;
            margin: 12px 0 8px 0;
            padding: 4px 0;
            border-bottom: 1px solid #ddd;
          }
          
          /* Summary section */
          #Summary p {
            margin: 4px 0;
            line-height: 1.4;
          }
          
          /* Value spans */
          span[id$="Area"], 
          span[id="totalSellableValue"] {
            font-weight: normal;
            color: #333;
          }
          
          /* Action buttons */
          button {
            padding: 4px 8px;
            font-size: 12px;
            border: 1px solid #ddd;
            border-radius: 3px;
            background: #fff;
            cursor: pointer;
          }
          
          button:hover {
            background: #f5f5f5;
          }

          .chart-container {
            width: 800px;
            height: 400px;
            margin: 20px auto;
            position: relative;
          }

          canvas#salesChart,
          canvas#cashflowChart {
            display: block;
          }
          .download-button {
            padding: 8px 16px;
            background-color: #4CAF50;
            color: white;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            font-size: 12px;
            margin: 5px;
          }

          .download-button:hover {
            background-color: #45a049;
          }
        </style>
        </head>
        <body>
          <button class="refresh-button" onclick="refreshData()">刷新 Refresh</button>
          <div class="tab">
            <button class="tablinks" onclick="openTab('Summary')" id="defaultOpen">面积和户型统计 Summary</button>
            <button class="tablinks" onclick="openTab('CashflowReport')">现金流报表 Cashflow Report</button>
            <button class="tablinks" onclick="openTab('SalesChart')">产品销售表 Sales Chart</button>
          </div>

          <div id="Summary" class="tabcontent">
            <h3>模型经济技术指标汇总 Project Output</h3>
            <p>地上部分总建筑面积 Total Construction Area: <span id="totalArea" style="font-weight: bold;">Calculating...</span> m²</p>
            <p>地上可售部分总建筑面积 Total Sellable Construction Area: <span id="totalSellableArea" style="font-weight: bold;">Calculating...</span> m²</p>
            <p>地上可售部分总货值 Total Sellable Value: <span id="totalSellableValue" style="font-weight: bold;">Calculating...</span> 万元</p>
            
            <div id="propertyLineStats" class="property-line-stats"></div>
            <button onclick="generateCSV()">Generate CSV Report</button>
          </div>

          <div id="SalesChart" class="tabcontent">
            <div class="chart-container" style="height: 400px; position: relative;">
              <h3>产品销售表 Sales Chart</h3>
              <canvas id="salesChart" style="width: 100%; height: 100%;"></canvas>
              <div id="chartLegend" style="position: absolute; top: 10px; right: 10px;"></div>
            </div>
            <div style="text-align: center; margin: 10px;">
              <button onclick="downloadCanvas('salesChart', '销售曲线')" class="download-button">
                保存销售曲线图 Save Sales Chart
              </button>
            </div>
            <div class="chart-container" style="height: 400px; position: relative; margin-top: 20px;">
              <h3>现金流曲线 Cashflow Curves</h3>
              <canvas id="cashflowChart" style="width: 100%; height: 100%;"></canvas>
              <div id="cashflowLegend" style="position: absolute; top: 10px; right: 10px;"></div>
            </div>
            <div style="text-align: center; margin: 10px;">
              <button onclick="downloadCanvas('cashflowChart', '现金流曲线')" class="download-button">
                保存现金流图 Save Cashflow Chart
              </button>
            </div>
          </div>
          <div id="CashflowReport" class="tabcontent">
            <p>Loading cashflow report...</p>
          </div>

          <script>
          let lastSalesData = null;
          let lastCashflowData = null;
          let activeTab = 'Summary';

          function updateCashflowChart(data) {
            console.log('Received cashflow data:', data);
            lastCashflowData = data;
            
            if (activeTab === 'SalesChart') {
              requestAnimationFrame(() => renderCashflowChart(data));
            }
          }

          function renderCashflowChart(data) {
            console.log("Starting cashflow chart render process...");
            const canvas = document.getElementById('cashflowChart');
            const legendDiv = document.getElementById('cashflowLegend');
            
            if (!canvas) {
              console.error("Cashflow chart canvas not found!");
              return;
            }
          
            // Set fixed canvas dimensions
            canvas.width = 800;
            canvas.height = 400;
            
            const ctx = canvas.getContext('2d');
            ctx.clearRect(0, 0, canvas.width, canvas.height);
            legendDiv.innerHTML = '';
            
            // Rest of the chart rendering logic with fixed dimensions
            const padding = 60;
            const graphWidth = canvas.width - padding * 2;
            const graphHeight = canvas.height - padding * 2;
            
            // Find max and min values for Y scale
            const monthlyCashflow = data.monthly || Array(72).fill(0);
            const accumulatedCashflow = data.accumulated || Array(72).fill(0);
            const allValues = [...monthlyCashflow, ...accumulatedCashflow];
            let maxValue = Math.max(...allValues);
            let minValue = Math.min(...allValues);
            
            // Convert to 亿 and round to next whole number
            maxValue = Math.ceil(maxValue / 100000000) * 100000000;
            minValue = Math.floor(minValue / 100000000) * 100000000;
            
            // Create evenly spaced grid lines in 亿 increments
            const interval = 100000000; // 1亿
            const gridValues = [];
            let currentValue = Math.floor(minValue / interval) * interval;
            while (currentValue <= maxValue) {
              gridValues.push(currentValue);
              currentValue += interval;
            }
            
            const valueRange = maxValue - minValue;
            
            // Helper function to convert value to Y coordinate
            const getY = (value) => {
              const normalizedValue = (maxValue - value) / valueRange;
              return padding + (graphHeight * normalizedValue);
            };
            
            // Draw Y-axis
            ctx.beginPath();
            ctx.strokeStyle = '#000';
            ctx.lineWidth = 1;
            ctx.moveTo(padding, padding);
            ctx.lineTo(padding, canvas.height - padding);
            ctx.stroke();
            
            // Draw horizontal grid lines and labels
            ctx.textAlign = 'right';
            ctx.textBaseline = 'middle';
            gridValues.forEach(value => {
              const y = getY(value);
              
              // Grid line
              ctx.beginPath();
              ctx.strokeStyle = value === 0 ? '#000' : '#eee';
              ctx.lineWidth = value === 0 ? 1 : 0.5;
              ctx.moveTo(padding, y);
              ctx.lineTo(canvas.width - padding, y);
              ctx.stroke();
              
              // Label (in 亿 units)
              ctx.fillStyle = '#000';
              ctx.fillText(value / 100000000 + '亿', padding - 5, y);
            });
            
            // X-axis labels (every 6 months)
            ctx.textAlign = 'center';
            ctx.textBaseline = 'top';
            for (let month = 0; month <= 72; month += 6) {
              const x = padding + (graphWidth * (month / 72));
              ctx.fillText(month.toString(), x, canvas.height - padding + 5);
            }
            
            // Draw monthly cashflow line
            ctx.beginPath();
            ctx.strokeStyle = 'rgb(50, 50, 255)';  
            ctx.lineWidth = 2;
            monthlyCashflow.forEach((value, month) => {
              const x = padding + (graphWidth * (month / 72));
              const y = getY(value);
              if (month === 0) ctx.moveTo(x, y);
              else ctx.lineTo(x, y);
            });
            ctx.stroke();
            
            // Draw accumulated cashflow line
            ctx.beginPath();
            ctx.strokeStyle = 'rgb(255, 50, 50)';  
            ctx.lineWidth = 2;
            accumulatedCashflow.forEach((value, month) => {
              const x = padding + (graphWidth * (month / 72));
              const y = getY(value);
              if (month === 0) ctx.moveTo(x, y);
              else ctx.lineTo(x, y);
            });
            ctx.stroke();
            
            // Add legend
            legendDiv.innerHTML = `
              <div style="background: rgba(255,255,255,0.8); padding: 5px;">
                <div style="color: rgb(50, 50, 255); margin: 2px;">● 月度现金流 Monthly Cashflow</div>
                <div style="color: rgb(255, 50, 50); margin: 2px;">● 累计现金流 Accumulated Cashflow</div>
              </div>
            `;
          }
          
          // Simplified openTab function
          function openTab(tabName) {
            var i, tabcontent, tablinks;
            tabcontent = document.getElementsByClassName("tabcontent");
            for (i = 0; i < tabcontent.length; i++) {
              tabcontent[i].style.display = "none";
            }
            
            document.getElementById(tabName).style.display = "block";
            activeTab = tabName;
            
            if (tabName === 'SalesChart') {
              if (lastSalesData) {
                requestAnimationFrame(() => renderSalesChart(lastSalesData));
              }
              if (lastCashflowData) {
                requestAnimationFrame(() => renderCashflowChart(lastCashflowData));
              }
            }
          }

          function renderSalesChart(salesData) {
            console.log("Starting chart render process...");
            const canvas = document.getElementById('salesChart');
            const chartContainer = document.getElementById('SalesChart');
            const legendDiv = document.getElementById('chartLegend');
            
            if (!canvas || chartContainer.style.display === 'none') {
              console.log("Chart container is hidden or not found, skipping render");
              return;
            }
            
            if (!salesData || !salesData.apartmentSales || !salesData.metadata) {
              console.error("Invalid sales data structure:", salesData);
              return;
            }
            
            // Set fixed canvas dimensions
            canvas.width = 800;
            canvas.height = 400;
            
            const ctx = canvas.getContext('2d');
            ctx.clearRect(0, 0, canvas.width, canvas.height);
            legendDiv.innerHTML = '';
            
            // Calculate scales
            const padding = 40;
            const graphWidth = canvas.width - padding * 2;
            const graphHeight = canvas.height - padding * 2;
            
            // Find max value for Y scale
            let maxSales = 0;
            Object.entries(salesData.apartmentSales).forEach(([type, data]) => {
              if (Array.isArray(data)) {
                const max = Math.max(...data.map(v => v || 0));
                if (max > maxSales) maxSales = max;
              }
            });
            
            // Draw axes
            ctx.beginPath();
            ctx.strokeStyle = '#000';
            ctx.moveTo(padding, padding);
            ctx.lineTo(padding, canvas.height - padding);
            ctx.lineTo(canvas.width - padding, canvas.height - padding);
            ctx.stroke();
            
            // Draw grid and labels
            ctx.fillStyle = '#000';
            ctx.textAlign = 'right';
            ctx.textBaseline = 'middle';
            
            // Y-axis labels
            for (let i = 0; i <= 5; i++) {
              const y = padding + (graphHeight - graphHeight * (i / 5));
              const value = Math.round(maxSales * (i / 5));
              ctx.fillText(value.toLocaleString(), padding - 5, y);
              
              ctx.beginPath();
              ctx.strokeStyle = '#eee';
              ctx.moveTo(padding, y);
              ctx.lineTo(canvas.width - padding, y);
              ctx.stroke();
            }
            
            // X-axis labels (every 6 months)
            ctx.textAlign = 'center';
            ctx.textBaseline = 'top';
            for (let month = 0; month <= 72; month += 6) {
              const x = padding + (graphWidth * (month / 72));
              ctx.fillText(month.toString(), x, canvas.height - padding + 5);
            }
            
            // Draw data lines and scene change indicators
            let legendHTML = '<div style="background: rgba(255,255,255,0.8); padding: 5px;">';
            console.log('Processing sales data:', salesData);
          console.log('Price changes data:', salesData.priceChanges);
          
          Object.entries(salesData.apartmentSales).forEach(([type, data], index) => {
              console.log(`Processing apartment type: ${type}`);
              console.log(`Scene changes for ${type}:`, salesData.priceChanges[type]);
              
              if (!Array.isArray(data) || !salesData.metadata[type]) {
                console.log(`Skipping invalid data for ${type}`);
                return;
              }
              
              const metadata = salesData.metadata[type];
              const typeNumber = metadata.number;
              
              if (!typeNumber) {
                console.log(`Skipping type ${type} - no valid number in metadata`);
                return;
              }
              
              // Calculate color based on apartment size number
              const hue = ((typeNumber - 50) * 2) % 360;
              const color = `hsl(${hue}, 70%, 50%)`;
              
              // Draw the sales line
              ctx.beginPath();
              ctx.strokeStyle = color;
              ctx.lineWidth = 2;
              
              let hasDrawnPoint = false;
              data.forEach((value, month) => {
                const x = padding + (graphWidth * (month / 72));
                const y = canvas.height - padding - (graphHeight * ((value || 0) / maxSales));
                
                if (!hasDrawnPoint) {
                  ctx.moveTo(x, y);
                  hasDrawnPoint = true;
                } else {
                  ctx.lineTo(x, y);
                }
              });
              ctx.stroke();
              
              // Draw scene change indicators with enhanced visibility
              if (salesData.priceChanges[type] && Array.isArray(salesData.priceChanges[type])) {
                console.log(`Drawing scene change indicators for ${type}`);
                salesData.priceChanges[type].forEach(month => {
                  console.log(`Drawing indicator at month ${month} for ${type}`);
                  const x = padding + (graphWidth * (month / 72));
                  const value = data[month] || 0;
                  const y = canvas.height - padding - (graphHeight * (value / maxSales));
                  
                  // Draw outer circle
                  ctx.beginPath();
                  ctx.arc(x, y, 6, 0, Math.PI * 2);
                  ctx.fillStyle = 'white';
                  ctx.fill();
                  ctx.strokeStyle = color;
                  ctx.lineWidth = 2;
                  ctx.stroke();
                  
                  // Draw inner circle
                  ctx.beginPath();
                  ctx.arc(x, y, 4, 0, Math.PI * 2);
                  ctx.fillStyle = color;
                  ctx.fill();
                });
              }
              
              // Add to legend with the full original name
              legendHTML += `<div style="color: ${color}; margin: 2px;">● ${metadata.originalName}</div>`;
            });
            
            legendHTML += '</div>';
            legendDiv.innerHTML = legendHTML;
          }
          
          function updateSalesChart(data) {
            console.log('Received sales data:', data);
            lastSalesData = data;
            
            if (activeTab === 'SalesChart') {
              requestAnimationFrame(() => renderSalesChart(data));
            }
          }
            
          function updatePropertyLineStats(statsHtml) {
            console.log("Updating property line stats");
            console.log("Received HTML length:", statsHtml.length);
            document.getElementById('propertyLineStats').innerHTML = statsHtml;
            console.log("Property line stats updated");
          }

            function generateCSV() {
              window.location = 'skp:generate_csv';
            }
            function updateTotalArea(totalArea, totalSellableArea) {
              document.getElementById('totalArea').textContent = totalArea;
              document.getElementById('totalSellableArea').textContent = totalSellableArea;
            }
            function updateCashflowReport(html) {
              try {
                document.getElementById('CashflowReport').innerHTML = html;
                console.log("Cashflow report updated successfully");
              } catch (error) {
                console.error("Error updating cashflow report:", error);
              }
            }
            function downloadCanvas(canvasId, fileName) {
              const canvas = document.getElementById(canvasId);
              if (!canvas) {
                console.error('Canvas not found');
                return;
              }
            
              try {
                // Create a new canvas for the complete image
                const exportCanvas = document.createElement('canvas');
                exportCanvas.width = canvas.width;
                exportCanvas.height = canvas.height;
                const ctx = exportCanvas.getContext('2d');
            
                // Fill white background
                ctx.fillStyle = 'white';
                ctx.fillRect(0, 0, exportCanvas.width, exportCanvas.height);
            
                // Draw the original canvas content
                ctx.drawImage(canvas, 0, 0);
            
                // Get the chart container
                const container = canvas.closest('.chart-container');
                if (!container) {
                  console.error('Chart container not found');
                  return;
                }
            
                // Find the header and legend
                const header = container.querySelector('h3');
                const legendDiv = canvasId === 'salesChart' ? 
                  document.getElementById('chartLegend') : 
                  document.getElementById('cashflowLegend');
            
                // Save context state
                ctx.save();
            
                // Draw header
                if (header) {
                  ctx.font = '13px Arial';
                  ctx.fillStyle = 'black';
                  ctx.textAlign = 'left';
                  ctx.textBaseline = 'top';
                  ctx.fillText(header.textContent, 20, 10);
                }
            
                // Draw legend
                if (legendDiv) {
                  const legendContent = legendDiv.querySelector('div');
                  if (legendContent) {
                    ctx.font = '12px Arial';
                    const legendItems = legendContent.children;
                    let yOffset = 30;
            
                    Array.from(legendItems).forEach((item) => {
                      // Extract color and text
                      const color = item.style.color;
                      const text = item.textContent.replace('●', '').trim();
                      
                      // Draw colored dot
                      ctx.fillStyle = color;
                      ctx.beginPath();
                      ctx.arc(canvas.width - 150, yOffset + 4, 4, 0, Math.PI * 2);
                      ctx.fill();
                      
                      // Draw text
                      ctx.fillStyle = 'black';
                      ctx.textAlign = 'left';
                      ctx.fillText(text, canvas.width - 140, yOffset);
                      
                      yOffset += 20;
                    });
                  }
                }
            
                // Restore context state
                ctx.restore();
            
                // Convert to blob and trigger download
                exportCanvas.toBlob(function(blob) {
                  const url = URL.createObjectURL(blob);
                  const downloadLink = document.createElement('a');
                  downloadLink.download = `${fileName}_${formatDate(new Date())}.png`;
                  downloadLink.href = url;
                  document.body.appendChild(downloadLink);
                  downloadLink.click();
                  document.body.removeChild(downloadLink);
                  URL.revokeObjectURL(url);
                }, 'image/png');
            
              } catch (error) {
                console.error('Error saving canvas:', error);
              }
            }

            function formatDate(date) {
              const year = date.getFullYear();
              const month = String(date.getMonth() + 1).padStart(2, '0');
              const day = String(date.getDate()).padStart(2, '0');
              const hours = String(date.getHours()).padStart(2, '0');
              const minutes = String(date.getMinutes()).padStart(2, '0');
              
              return `${year}${month}${day}_${hours}${minutes}`;
            }
            function refreshData() {
              console.log("Refreshing data...");
              window.location = 'skp:refresh_data';
            }
            function updateTotalSellableValue(value) {
              document.getElementById('totalSellableValue').textContent = value;
            }
          
            // Initialize when the page loads
            document.addEventListener('DOMContentLoaded', function() {
              // Open the Summary tab by default
              document.getElementById("defaultOpen").click();
              // Signal that the page is loaded
              window.location = 'skp:on_page_load';
            });
          </script>
        </body>
        </html>
      HTML

      dialog.set_html(html_content)

      dialog.add_action_callback("generate_csv") { generate_csv_report }
      
      dialog.add_action_callback("on_page_load") do
        update_output_data(dialog)
      end

      dialog.add_action_callback("refresh_data") do
        update_output_data(dialog)
      end

      dialog.show
    end
    def self.update_output_data(dialog)
      # Update total areas first
      total_area = calculate_total_construction_area
      total_sellable_area = calculate_total_sellable_construction_area
      dialog.execute_script("updateTotalArea('#{total_area.round}', '#{total_sellable_area.round}')")
      
      # Update total sellable value
      total_sellable_value = calculate_total_sellable_value
      dialog.execute_script("updateTotalSellableValue('#{total_sellable_value.round}')")
      
      # Update property line stats
      property_line_stats = generate_property_line_stats
      json_encoded_stats = property_line_stats.to_json
      update_script = "console.log('Updating property line stats...'); updatePropertyLineStats(#{json_encoded_stats}); console.log('Update complete');"
      dialog.execute_script(update_script)
      
      begin
        # Calculate cashflow data once and reuse
        puts "Starting cashflow calculations..."
        
        # Calculate everything once and store the results
        cashflow_data = CashFlowCalculator.calculate_sales_income
        full_cashflow = CashFlowCalculator.calculate_and_print_full_cashflow_table(cashflow_data)
        monthly_cashflow = CashFlowCalculator.calculate_monthly_cashflow(full_cashflow)
        
        # Generate HTML report using the calculated data
        cashflow_html = CashFlowCalculator.generate_html_report(full_cashflow)
        json_encoded_cashflow = cashflow_html.to_json
        dialog.execute_script("updateCashflowReport(#{json_encoded_cashflow});")
        
        # Format sales data for the chart using the already calculated data
        sales_data = {
          apartmentSales: {},
          priceChanges: {},
          metadata: {}
        }
        
     # Process income table to get sales data
      cashflow_data[:income_table].each do |apt_type, monthly_values|
        type_number = extract_number_from_type(apt_type)
        next unless type_number
        
        sales_data[:apartmentSales][apt_type] = Array.new(72, 0)
        sales_data[:priceChanges][apt_type] = []
        sales_data[:metadata][apt_type] = {
          number: type_number,
          originalName: apt_type
        }
        
        model = Sketchup.active_model
        apt_data = JSON.parse(model.get_attribute('apartment_type_data', apt_type) || '{}')
        sales_scenes = apt_data['sales_scenes'] || []
        
        # Log data for all apartment types
        puts "\n=== Apartment Data ==="
        puts "Apartment type: #{apt_type}"
        puts "Number of sales scenes: #{sales_scenes.length}"
        puts "Scene change month: #{apt_data['scene_change_month']}"
        puts "Sales scenes data: #{sales_scenes.inspect}"
        
        if sales_scenes.length > 1 && apt_data['scene_change_month']
          sales_data[:priceChanges][apt_type] << apt_data['scene_change_month']
          puts "Added price change at month: #{apt_data['scene_change_month']}"
          puts "Price changes array: #{sales_data[:priceChanges][apt_type].inspect}"
        end
        
        monthly_values.each_with_index do |income, month|
          scene_index = if apt_data['scene_change_month'] && month >= apt_data['scene_change_month']
                        1
                      else
                        0
                      end
          
          scene = sales_scenes[scene_index] if sales_scenes.any?
          
          if scene && scene['price'].to_f > 0 && apt_data['area'].to_f > 0
            sales_volume = income / (scene['price'].to_f * apt_data['area'].to_f)
            sales_data[:apartmentSales][apt_type][month] = sales_volume
          end
        end
      end

      # Log final sales data structure
      puts "\n=== Final Sales Data ==="
      puts "Price changes data: #{sales_data[:priceChanges].inspect}"
    
        # Prepare chart data using the already calculated full_cashflow
        cashflow_chart_data = {
          monthly: full_cashflow[:monthly_cashflow],
          accumulated: full_cashflow[:accumulated_cashflow]
        }
        
        # Update both charts in a single script execution
        script = <<-JS
          updateSalesChart(#{sales_data.to_json});
          updateCashflowChart(#{cashflow_chart_data.to_json});
        JS
        
        dialog.execute_script(script)
        puts "Cashflow calculations and updates completed."
        
      rescue => e
        puts "Error preparing chart data: #{e.message}"
        puts e.backtrace
      end
    end
    
    def self.calculate_total_construction_area
      model = Sketchup.active_model
      total_area = 0
      total_amenity_gfa = 0
      
      # Load project data to get the amenity GFA values
      project_data = JSON.parse(model.get_attribute('project_data', 'data', '{}'))
      amenity_gfa_data = project_data['propertyLines'] || []
      
      TraversalUtils.traverse_building_instances(model).each do |instance, transformation|
        area = instance.definition.get_attribute('building_data', 'total_area')
        total_area += area.to_f if area
      end
      
      # Add amenity GFA from input data
      total_amenity_gfa = amenity_gfa_data.sum { |pl| pl['amenity_GFA_in_FAR'].to_f }
      
      total_area + total_amenity_gfa
    end
    
    def self.calculate_total_sellable_construction_area
      model = Sketchup.active_model
      total_sellable_area = 0
      building_instances = Real_Estate_Optimizer::CashFlowCalculator.find_building_instances(model)
      
      building_instances.each do |instance, world_transformation|
        if instance.definition.attribute_dictionaries && instance.definition.attribute_dictionaries['building_data']
          area = instance.definition.get_attribute('building_data', 'total_area')
          total_sellable_area += area.to_f if area
        end
      end
      total_sellable_area
    end

    # def self.generate_csv_report
    #   begin
    #     puts "Attempting to access CashFlowCalculator..."
    #     if defined?(Real_Estate_Optimizer::CashFlowCalculator)
    #       # puts "CashFlowCalculator is defined."
    #       cashflow_data = Real_Estate_Optimizer::CashFlowCalculator.calculate_and_print_full_cashflow_table
    #       monthly_cashflow = Real_Estate_Optimizer::CashFlowCalculator.calculate_monthly_cashflow(cashflow_data)
    #       key_indicators = Real_Estate_Optimizer::CashFlowCalculator.calculate_key_indicators(monthly_cashflow)
    #       # puts "Received cashflow data, proceeding to generate CSV"
          
    #       # Default file name
    #       default_file_name = "real_estate_cashflow_report.csv"
          
    #       # Open file dialog for user to choose save location and file name
    #       file_path = UI.savepanel("Save Cashflow Report", "", default_file_name)
          
    #       if file_path
    #         puts "CSV will be saved to: #{file_path}"
            
    #         # Open file in binary write mode
    #         File.open(file_path, "wb") do |file|
    #           # Write UTF-8 BOM
    #           file.write("\xEF\xBB\xBF")
    
    #           # Create CSV object
    #           csv = CSV.new(file)

              
    #           # Write key indicators
    #           csv << ['项目关键指标 Key Project Indicators']
    #           csv << ['指标 Indicator', '值 Value']
    #           csv << ['内部收益率 IRR', "#{key_indicators[:irr] ? "#{key_indicators[:irr].round(2)}%" : 'N/A'}"]
    #           csv << ['销售毛利率 Gross Profit Margin', "#{key_indicators[:gross_profit_margin]}%"]
    #           csv << ['销售净利率 Net Profit Margin', "#{key_indicators[:net_profit_margin]}%"]
    #           csv << ['现金流回正（月） Cash Flow Positive Month', key_indicators[:cash_flow_positive_month]]
    #           csv << ['项目总销售额（含税） Total Sales (incl. tax)', key_indicators[:total_sales]]
    #           csv << ['项目总投资（含税） Total Investment (incl. tax)', key_indicators[:total_investment]]
    #           csv << ['项目资金峰值 Peak Negative Cash Flow', key_indicators[:peak_negative_cash_flow]]
    #           csv << ['项目净利润 Net Profit', key_indicators[:net_profit]]
    #           csv << ['企业所得税 Corporate Tax', key_indicators[:corporate_tax]]
    #           csv << ['税后净利润 Net Profit After Tax', key_indicators[:net_profit] - key_indicators[:corporate_tax]]
    #           csv << ['MOIC', key_indicators[:moic] || 'N/A']
              
    #           # Add a blank row for separation
    #           csv << []
              
    #           # Write headers
    #           csv << [
    #             '月份 Month',
    #             '计容产品销售收入 Apartment Sales',
    #             '预售资金监管要求 Supervision Fund Requirement',
    #             '资金监管存入 Fund Contribution',
    #             '资金监管解活 Fund Release',
    #             '车位销售收入 Parking Lot Sales',
    #             '总销售收入 Total Sales Income',
    #             '总现金流入小计 Total Cash Inflow',
    #             '土地规费 Land Fees',
    #             '配套建设费用 Amenity Construction Cost',
    #             '计容产品建安费用 Apartment Construction Payment',
    #             '税费 Fees and Taxes',
    #             '地下建安费用 Underground Construction Cost',
    #             '总现金流出小计 Total Cash Outflow',
    #             '月净现金流 Monthly Net Cashflow',
    #             '累计净现金流 Accumulated Net Cashflow',
    #             '增值税重新申报 VAT Re-declaration',
    #           ]
              
    #           # Write data
    #           monthly_cashflow.each do |month_data|
    #             csv << month_data.values
    #           end
    #         end
    #         puts "CSV generation completed successfully"
    #         UI.messagebox("CSV report generated and saved to: #{file_path}")
    #       else
    #         puts "CSV generation cancelled by user"
    #         UI.messagebox("CSV generation cancelled.")
    #       end
    #     else
    #       raise NameError, "CashFlowCalculator is not defined"
    #     end
    #   rescue StandardError => e
    #     error_message = "Error generating CSV: #{e.message}\n\n"
    #     error_message += "Error occurred at:\n#{e.backtrace.first}\n\n"
    #     error_message += "Full backtrace:\n#{e.backtrace.join("\n")}"
    #     puts error_message
    #     UI.messagebox(error_message)
    #   end
    # end

    def self.generate_property_line_stats
      model = Sketchup.active_model
      property_lines = CashFlowCalculator.find_property_line_components(model)
      building_instances = CashFlowCalculator.find_building_instances(model)
      
      # Load project data to get the amenity GFA values
      project_data = JSON.parse(model.get_attribute('project_data', 'data', '{}'))
      amenity_gfa_data = project_data['propertyLines'] || []
    
      all_apartment_types = Set.new
      property_line_data = {}
      
      property_lines.each do |property_line|
        keyword = property_line.definition.get_attribute('dynamic_attributes', 'keyword')
        area = property_line.definition.get_attribute('dynamic_attributes', 'property_area').to_f
        
        # Find the corresponding amenity GFA from input data
        amenity_gfa = amenity_gfa_data.find { |pl| pl['name'] == keyword }
        amenity_GFA = amenity_gfa ? amenity_gfa['amenity_GFA_in_FAR'].to_f : 0
        
        apartment_stocks = Hash.new(0)
        total_sellable_area = 0
        total_footprint_area = 0
        
        building_instances.each do |instance, world_transformation|
          begin
            if !world_transformation.identity?
              world_point = world_transformation.origin
              if CashFlowCalculator.point_in_polygon?(world_point, property_line)
                stocks = JSON.parse(instance.definition.get_attribute('building_data', 'apartment_stocks'))
                stocks.each { |apt_type, count| 
                  apartment_stocks[apt_type] += count
                  all_apartment_types.add(apt_type)
                }
                
                instance_area = instance.definition.get_attribute('building_data', 'total_area').to_f
                total_sellable_area += instance_area
                total_footprint_area += instance.definition.get_attribute('building_data', 'footprint_area').to_f
                
                instance.set_attribute('dynamic_attributes', 'property_line_keyword', keyword)
              elsif instance.get_attribute('dynamic_attributes', 'property_line_keyword') == keyword
                instance.delete_attribute('dynamic_attributes', 'property_line_keyword')
              end
            else
              puts "Warning: Identity transformation found for instance #{instance.entityID}"
            end
          rescue => e
            puts "Error processing building instance: #{e.message}"
            puts "Instance: #{instance.inspect}"
            puts "World transformation: #{world_transformation.inspect}"
          end
        end
        
        total_construction_area = total_sellable_area + amenity_GFA
        far = area > 0 ? total_construction_area / area : 0
        footprint_coverage_rate = area > 0 ? (total_footprint_area / area * 100).round(2) : 0
        total_apartments = apartment_stocks.values.inject(0, :+)
        
        property_line_data[keyword] = {
          apartment_stocks: apartment_stocks,
          total_apartments: total_apartments,
          total_area: total_construction_area,
          total_sellable_area: total_sellable_area,
          amenity_GFA: amenity_GFA,
          far: far,
          footprint_coverage_rate: footprint_coverage_rate,
          property_area: area
        }
      end
      
      stats = generate_property_line_table(property_line_data, all_apartment_types)
      stats += generate_apartment_type_table(property_line_data, all_apartment_types)
      
      stats
    end

    def self.property_line_sort_key(name)
      match = name.match(/(\d+)([A-Za-z]*)/)
      if match
        [match[1].to_i, match[2]]  # Sort by number first, then by letter
      else
        [Float::INFINITY, name]  # Put non-matching names at the end
      end
    end
    
    def self.generate_property_line_table(property_line_data, all_apartment_types)
      sorted_apartment_types = sort_apartment_types(all_apartment_types)
      sorted_property_lines = property_line_data.keys.sort_by { |name| property_line_sort_key(name) }
    
      table = "<h3>分地块统计 Property Line Statistics</h3>"
      table += "<table><tr><th>地块 Property Line</th>"
      sorted_apartment_types.each do |type|
        area = type.scan(/\d+/).first.to_f
        hue = ((area - 50) * 2) % 360
        table += "<th style='background-color: hsl(#{hue}, 100%, 50%); color: black; text-shadow: 0px 0px 4px white;'>#{type}</th>"
      end
    
      table += "<th>户数小计 Total Apartments</th>"
      table += "<th>用地面积 Parcel Ground Area (m²)</th>"
      table += "<th>总建面 Total Construction Area (m²)</th>"
      table += "<th>总可售建面 Total Sellable Construction Area (m²)</th>"
      table += "<th>计容配套面积 Amenity GFA in FAR (m²)</th>"
      table += "<th>可售净容积率 FAR</th>"
      table += "<th>建筑密度 Footprint Coverage Rate (%)</th></tr>"
    
      sorted_property_lines.each do |keyword|
        data = property_line_data[keyword]
        table += "<tr><td style='font-weight: bold; font-size: 120%;'>#{keyword}</td>"
        sorted_apartment_types.each do |type|
          count = data[:apartment_stocks][type] || 0
          percentage = (count.to_f / data[:total_apartments] * 100).round(2)
          table += "<td>#{count} (#{percentage}%)</td>"
        end
        table += "<td>#{data[:total_apartments]}</td>"
        table += "<td>#{data[:property_area].round}</td>"
        table += "<td>#{data[:total_area].round}</td>"
        table += "<td>#{data[:total_sellable_area].round}</td>"
        table += "<td>#{data[:amenity_GFA].round}</td>"
        table += "<td>#{data[:far].round(2)}</td>"
        table += "<td>#{data[:footprint_coverage_rate]}%</td></tr>"
      end
      
      table += "</table>"
    end
    
    def self.generate_apartment_type_table(property_line_data, all_apartment_types)
      total_apartments = Hash.new(0)
      apartment_data = {}
      
      property_line_data.each do |_, data|
        data[:apartment_stocks].each do |type, count|
          total_apartments[type] += count
          
          # Fetch apartment data if not already fetched
          unless apartment_data[type]
            apt_data = get_apartment_data(type)
            apartment_data[type] = {
              area: apt_data['area'].to_f,
              width: apt_data['width'].to_f,
              sales_scenes: apt_data['sales_scenes'] || []
            }
          end
        end
      end
      
      grand_total = total_apartments.values.inject(0, :+)
      sorted_apartment_types = sort_apartment_types(all_apartment_types)
      
      table = "<h3>户型统计 Apartment Type Statistics Across Parcels</h3>"
      table += "<table><tr><th>户型 Apartment Type</th><th>小计 Total Count</th><th>户数比 Percentage</th>"
      table += "<th>面宽 Width (m)</th>"  # New column
      table += "<th>单价1</th><th>总价1</th><th>月流速1</th>"
      table += "<th>单价2</th><th>总价2</th><th>月流速2</th>"
      table += "<th>单价3</th><th>总价3</th><th>月流速3</th></tr>"
      
      sorted_apartment_types.each do |type|
        count = total_apartments[type]
        percentage = (count.to_f / grand_total * 100).round(2)
        width = apartment_data[type][:width]
        # puts "Debug: Apartment type: #{type}, Width: #{width}"

        area = type.scan(/\d+/).first.to_f
        hue = ((area - 50) * 2) % 360

        table += "<tr><td style='background-color: hsl(#{hue}, 100%, 50%); color: black; text-shadow: 0px 0px 3px white;'>#{type}</td><td>#{count}</td><td>#{percentage}%</td>"
        table += "<td>#{width}</td>"
        
        apt_area = apartment_data[type][:area]
        sales_scenes = apartment_data[type][:sales_scenes]
        
        3.times do |i|
          if i < sales_scenes.length
            scene = sales_scenes[i]
            unit_price = scene['price'].to_f
            total_price = (unit_price * apt_area)/10000.round
            volume = scene['volumn'].to_i
            
            table += "<td>#{unit_price.round}</td><td>#{total_price.round}</td><td>#{volume}</td>"
          else
            table += "<td>-</td><td>-</td><td>-</td>"
          end
        end
        
        table += "</tr>"
      end
      
      table += "</table>"
    end

    def self.extract_number_from_type(apt_type)
      # Extract all numbers from the type string and take the first one
      matches = apt_type.scan(/\d+/)
      matches.first ? matches.first.to_i : nil
    end
    
    def self.get_apartment_data(apt_type)
      model = Sketchup.active_model
      JSON.parse(model.get_attribute('apartment_type_data', apt_type, '{}'))
    end

    def self.sort_apartment_types(apartment_types)
      apartment_types.sort_by { |type| type.scan(/\d+/).first.to_i }
    end

    def self.calculate_total_sellable_value
      model = Sketchup.active_model
      total_value = 0
    
      TraversalUtils.traverse_building_instances(model).each do |instance, transformation|
        apartment_stocks = JSON.parse(instance.definition.get_attribute('building_data', 'apartment_stocks') || '{}')
        apartment_stocks.each do |apt_type, count|
          apt_data = get_apartment_data(apt_type)
          area = apt_data['area'].to_f
          unit_price = apt_data['sales_scenes'].first['price'].to_f if apt_data['sales_scenes'] && apt_data['sales_scenes'].first
          total_value += count * unit_price * area if unit_price && area
        end
      end
    
      total_value / 10000 # Convert to 万元
    end
  end
end
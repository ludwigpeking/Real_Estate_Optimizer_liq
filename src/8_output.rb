require_relative '8_cashflow'  
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
          
          .tab {
            overflow: hidden;
            border: 1px solid #ccc;
            background-color: #f1f1f1;
            margin-bottom: 8px;
            display: flex;
            justify-content: space-between; /* This will push items to opposite ends */
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

          .tab-left {
            display: flex;
          }
          .tab button.tablinks {
            background-color: inherit;
            border: none;
            outline: none;
            cursor: pointer;
            padding: 8px 12px;
            transition: 0.3s;
            font-size: 12px;
            float: left; /* Keep this for compatibility */
          }
          .tab button:hover { background-color: #ddd; }
          .tab button.active { background-color: #ccc; }
          
          .tabcontent {
            display: none;
            padding: 6px 12px;
            border: 1px solid #ccc;
            border-top: none;
          }
          .tab button.refresh-button {
            background-color: #f00;
            color: white;
            border: none;
            cursor: pointer;
            font-size: 12px;
            padding: 8px 12px;
            margin-left: auto; /* Pushes it to the right */
          }

          .tab button.refresh-button:hover {
            background-color: #d00; /* Slightly darker red on hover */
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
            width: 800px;  /* Keep original width */
            height: 400px;
            margin: 20px auto;
            position: relative;
          }
          
          canvas#salesChart,
          canvas#cashflowChart {
            width: 800px;
            height: 400px;
            display: block;
          }
          
          #chartLegend, #cashflowLegend {
            position: absolute;
            top: 10px;
            left: 800px;
            margin-left: 10px;
            background: rgba(255, 255, 255, 0.8);
            padding: 5px;
            border-radius: 4px;
            width: 180px;
          }
          .download-button {
            padding: 8px 16px;
            background-color: #888;
            color: white;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            font-size: 12px;
            margin: 5px;
          }

          .download-button:hover {
            background-color: #bbb;
          }

          .number-input-container {
              display: flex;
              align-items: center;
              gap: 2px;
          }

          .arrow-btn {
              padding: 2px 6px;
              background: #f5f5f5;
              border: 1px solid #ddd;
              cursor: pointer;
              font-size: 10px;
          }

          .arrow-btn:hover {
              background: #e5e5e5;
          }

          .apartment-value {
              font-size: 12px;
              padding: 2px;
          }
          /* Add this to your existing CSS */
.scene-month-input {
  width: 40px;
  text-align: center;
  border: 1px solid #ddd;
  padding: 2px;
  font-size: 12px;
  -moz-appearance: textfield; /* Firefox */
}

/* Remove arrows from number input */
.scene-month-input::-webkit-outer-spin-button,
.scene-month-input::-webkit-inner-spin-button {
  -webkit-appearance: none;
  margin: 0;
}

/* Style KPI tables consistently */
.kpi-summary {
  margin: 10px 0;
  padding: 10px;
  background-color: #f5f5f5;
  border: 1px solid #ddd;
  border-radius: 4px;
}

.kpi-summary table {
  width: 100%;
  border-collapse: collapse;
}

.kpi-summary td {
  padding: 4px 8px;
  border: none;
}

.kpi-summary td:first-child {
  width: 60%;
  color: #333;
}

.kpi-summary td:last-child {
  text-align: right;
  font-weight: bold;
  color: #000;
}
        </style>
        </head>
        <body>
         <div class="tab">
            <div class="tab-left">
              <button class="tablinks" onclick="openTab('Summary')" id="defaultOpen">面积和户型统计 Summary</button>
              <button class="tablinks" onclick="openTab('CashflowReport')">现金流报表 Cashflow Report</button>
              <button class="tablinks" onclick="openTab('SalesChart')">产品销售表 Sales Chart</button>
            </div>
            <button class="tablinks refresh-button" onclick="refreshData()">刷新 Refresh</button>
          </div>

          <div id="Summary" class="tabcontent">
            <h3>模型经济技术指标汇总 Project Output</h3>
            <p>地上部分总建筑面积 Total Construction Area: <span id="totalArea" style="font-weight: bold;">Calculating...</span> m²</p>
            <p>地上可售部分总建筑面积 Total Sellable Construction Area: <span id="totalSellableArea" style="font-weight: bold;">Calculating...</span> m²</p>
            <p>地上可售部分总货值 Total Sellable Value: <span id="totalSellableValue" style="font-weight: bold;">Calculating...</span> 万元</p>
            
            <div id="propertyLineStats" class="property-line-stats"></div>
          </div>

          <div id="SalesChart" class="tabcontent">
            <div class="chart-container" style="height: 400px; position: relative;">
              <h3>产品销售表 Sales Chart</h3>
              <canvas id="salesChart" style="width: 800px; height: 100%;"></canvas>
              <div id="chartLegend" style="position: absolute; top: 10px; right: 50px;"></div>
            </div>
            <div style="text-align: center; margin: 10px;">
              <button onclick="downloadCanvas('salesChart', '销售曲线')" class="download-button">
                保存销售曲线图 Save Sales Chart
              </button>
            </div>
            <div class="chart-container" style="height: 400px; position: relative; margin-top: 20px;">
              <h3>现金流曲线 Cashflow Curves</h3>
              <canvas id="cashflowChart" style="width: 800px; height: 100%;"></canvas>
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
        

          function setLineDash(ctx, pattern) {
            switch(pattern) {
              case 'dot':
                ctx.setLineDash([2, 2]);
                break;
              case 'dash':
                ctx.setLineDash([6, 3]);
                break;
              case 'solid':
                ctx.setLineDash([]);
                break;
            }
          }
          function renderSalesChart(salesData) {
            console.log("Full sales data for debugging:", salesData.apartmentSales);
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
          
            // Sort apartment types by number then letter
            const sortedTypes = Object.keys(salesData.apartmentSales).sort(compareApartmentTypes);
            
            // Draw axes and grid
            drawAxesAndGrid(ctx, padding, canvas.width, canvas.height, maxSales);
            
            // Define line patterns
            const linePatterns = [
              { type: 'solid', dash: [] },
              { type: 'dash', dash: [6, 3] },
              { type: 'dot', dash: [2, 2] }
            ];
          
            let legendHTML = '<div style="background: rgba(255,255,255,0.8); padding: 5px;">';
            
            // Process apartment types in sorted order
            sortedTypes.forEach((type, index) => {
              if (!salesData.metadata[type] || !salesData.metadata[type].number) {
                console.log(`Skipping type ${type} - no valid number in metadata`);
                return;
              }
          
              const data = salesData.apartmentSales[type];
              const metadata = salesData.metadata[type];
              const color = getTypeColor(type, metadata);
              
              // Draw the sales line
              drawSalesLine(ctx, data, type, color, index, linePatterns, padding, graphWidth, graphHeight, maxSales);
              
              // Add legend entry
              legendHTML += createLegendEntry(type, color, metadata);
              
              // Add scene change indicators if they exist
              if (salesData.priceChanges[type] && Array.isArray(salesData.priceChanges[type])) {
                drawSceneChangeIndicators(ctx, type, salesData, padding, graphWidth, graphHeight, maxSales, color);
              }
            });
          
            legendHTML += '</div>';
            legendDiv.innerHTML = legendHTML;
            
            // Draw legend line patterns
            drawLegendLinePatterns(sortedTypes, salesData, linePatterns);
          }
          
          // Helper functions
          function drawAxesAndGrid(ctx, padding, width, height, maxSales) {
            ctx.beginPath();
            ctx.strokeStyle = '#000';
            ctx.moveTo(padding, padding);
            ctx.lineTo(padding, height - padding);
            ctx.lineTo(width - padding, height - padding);
            ctx.stroke();
            
            // Draw grid and labels
            ctx.fillStyle = '#000';
            ctx.textAlign = 'right';
            ctx.textBaseline = 'middle';
          
            // Y-axis grid and labels
            for (let i = 0; i <= 5; i++) {
              const y = padding + ((height - padding * 2) - (height - padding * 2) * (i / 5));
              const value = Math.round(maxSales * (i / 5));
              
              ctx.fillText(value.toLocaleString(), padding - 5, y);
              
              ctx.beginPath();
              ctx.strokeStyle = '#eee';
              ctx.moveTo(padding, y);
              ctx.lineTo(width - padding, y);
              ctx.stroke();
            }
            
            // X-axis labels
            ctx.textAlign = 'center';
            ctx.textBaseline = 'top';
            for (let month = 0; month <= 72; month += 6) {
              const x = padding + ((width - padding * 2) * (month / 72));
              ctx.fillText(month.toString(), x, height - padding + 5);
            }
          }
          
          function getTypeColor(type, metadata) {
            if (metadata.color) {
              const rgb = hexToRgb(metadata.color);
              if (rgb) {
                const hsv = rgbToHsv(rgb.r, rgb.g, rgb.b);
                return `hsl(${hsv.h}, 100%, 50%)`;
              }
            }
            
            if (type.includes('商铺') || type.includes('办公') || type.includes('公寓')) {
              return "hsl(0, 100%, 50%)";
            }
            
            const hue = ((metadata.number - 50) * 2.5) % 360;
            return `hsl(${hue}, 100%, 50%)`;
          }
          
          function drawSalesLine(ctx, data, type, color, index, linePatterns, padding, graphWidth, graphHeight, maxSales) {
            ctx.beginPath();
            ctx.strokeStyle = color;
            ctx.lineWidth = 2;
            
            const pattern = linePatterns[index % linePatterns.length];
            ctx.setLineDash(pattern.dash);
            
            let hasDrawnPoint = false;
            data.forEach((value, month) => {
              const x = padding + (graphWidth * (month / 72));
              const y = padding + graphHeight - (graphHeight * ((value || 0) / maxSales));
              
              if (!hasDrawnPoint) {
                ctx.moveTo(x, y);
                hasDrawnPoint = true;
              } else {
                ctx.lineTo(x, y);
              }
            });
            ctx.stroke();
          }
          
          function drawSceneChangeIndicators(ctx, type, salesData, padding, graphWidth, graphHeight, maxSales, color) {
            ctx.setLineDash([]); // Reset line dash for circles
            
            salesData.priceChanges[type].forEach(month => {
              const data = salesData.apartmentSales[type];
              const value = data[month] || 0;
              const x = padding + (graphWidth * (month / 72));
              const y = padding + graphHeight - (graphHeight * (value / maxSales));
              
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
          
          function createLegendEntry(type, color, metadata) {
            return `
              <div style="color: ${color}; margin: 8px 0; display: flex; align-items: center; gap: 10px;">
                <canvas width="30" height="10" style="margin-right: 5px;" id="legend_${type}"></canvas>
                <span style="flex: 1;">${metadata.originalName}</span>
                <div class="number-input-container">
                  <button class="arrow-btn" onclick="adjustSceneMonth('${type}', -1)">◀</button>
                  <input type="number" 
                    class="scene-month-input" 
                    id="scene_month_${type}" 
                    value="${metadata.scene_change_month || 72}"
                    min="0" 
                    max="72"
                    onchange="updateSceneMonth('${type}', this.value)">
                  <button class="arrow-btn" onclick="adjustSceneMonth('${type}', 1)">▶</button>
                </div>
              </div>`;
          }
          
          function drawLegendLinePatterns(sortedTypes, salesData, linePatterns) {
            sortedTypes.forEach((type, index) => {
              const legendCanvas = document.getElementById(`legend_${type}`);
              if (legendCanvas) {
                const ltx = legendCanvas.getContext('2d');
                ltx.fillStyle = 'white';
                ltx.fillRect(0, 0, legendCanvas.width, legendCanvas.height);
                
                const metadata = salesData.metadata[type];
                const color = getTypeColor(type, metadata);
                const pattern = linePatterns[index % linePatterns.length];
                
                ltx.strokeStyle = color;
                ltx.lineWidth = 2;
                ltx.setLineDash(pattern.dash);
                ltx.beginPath();
                ltx.moveTo(0, 5);
                ltx.lineTo(30, 5);
                ltx.stroke();
              }
            });
          }
          
          // Color conversion utilities
          function hexToRgb(hex) {
            const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
            return result ? {
              r: parseInt(result[1], 16),
              g: parseInt(result[2], 16),
              b: parseInt(result[3], 16)
            } : null;
          }
          
          function rgbToHsv(r, g, b) {
            r /= 255;
            g /= 255;
            b /= 255;
            
            const max = Math.max(r, g, b);
            const min = Math.min(r, g, b);
            let h;
            
            if (max === min) {
              h = 0;
            } else {
              const d = max - min;
              switch (max) {
                case r: h = ((g - b) / d + (g < b ? 6 : 0)) * 60; break;
                case g: h = ((b - r) / d + 2) * 60; break;
                case b: h = ((r - g) / d + 4) * 60; break;
              }
            }
            
            return { h, s: 100, v: 50 };
          }

function adjustSceneMonth(type, delta) {
    const input = document.getElementById(`scene_month_${type}`);
    const newValue = Math.min(72, Math.max(0, parseInt(input.value || 72) + delta));
    input.value = newValue;
    updateSceneMonth(type, newValue);
}

function updateSceneMonth(type, value) {
    // Ensure value is between 0 and 72
    value = Math.min(72, Math.max(0, parseInt(value) || 72));
    
    // Save back to SketchUp model
    window.location = `skp:update_scene_month@${type}@${value}`;
}

          function parseApartmentType(typeStr) {
            // Read digits from the start
            var digits = "";
            var i = 0;
            while (i < typeStr.length && typeStr[i] >= '0' && typeStr[i] <= '9') {
              digits += typeStr[i];
              i++;
            }
            
            // Remainder (letters or other chars)
            var letters = typeStr.substring(i);

            // Convert to integer, default to 0 if empty
            var number = digits ? parseInt(digits, 10) : 0;
            
            return {
              number: number,
              letters: letters
            };
          }

          // Compare function that sorts by numeric portion, then by letter portion
          function compareApartmentTypes(a, b) {
            var A = parseApartmentType(a);
            var B = parseApartmentType(b);

            // Compare the numeric parts
            if (A.number !== B.number) {
              return A.number - B.number;
            }
            // Compare the leftover letters
            if (A.letters < B.letters) return -1;
            if (A.letters > B.letters) return 1;
            return 0;
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


            function updateTotalArea(totalArea, totalSellableArea) {
              document.getElementById('totalArea').textContent = totalArea;
              document.getElementById('totalSellableArea').textContent = totalSellableArea;
            }
            function formatToWan(number) {
              return (number / 10000).toFixed();
            }
            
            function updateCashflowReport(html) {
              try {
                const div = document.createElement('div');
                div.innerHTML = html;
                
                // Find and update the specific values in the KPI table
                const rows = div.querySelectorAll('tr');
                rows.forEach(row => {
                  const cells = row.querySelectorAll('td');
                  if (cells.length >= 2) {
                    const label = cells[0].textContent.trim(); // Trim any extra spaces
                    
                    // Check if the row contains a relevant label
                    if (label.includes('项目总销售额') || 
                        label.includes('项目总投资') || 
                        label.includes('项目资金峰值') || 
                        label.includes('企业所得税') || 
                        label.includes('项目净利润')) {
                      
                      const value = parseFloat(cells[1].textContent.replace(/,/g, ''));
                      if (!isNaN(value)) {
                        cells[1].textContent = formatToWan(value) + ' 万元'; // Update with formatted value
                      }
                    }
                  }
                });
                
                // After updating, set the HTML in both the CashflowReport tab (Tag 2) and SalesChart tab (Tag 3)
                
                // Update the CashflowReport tab (Tag 2)
                const cashflowContainer = document.getElementById('CashflowReport');
                cashflowContainer.innerHTML = div.innerHTML;
                console.log("KPI table updated in CashflowReport tab");
            
                // Clone and insert into the SalesChart tab (Tag 3)
                const salesChartContainer = document.getElementById('SalesChart');
                const firstChart = salesChartContainer.querySelector('.chart-container');
            
                // Remove any existing KPI summary in SalesChart tab
                const existingKpi = salesChartContainer.querySelector('.kpi-summary');
                if (existingKpi) {
                  existingKpi.remove();
                }
            
                // Create a new container for the cloned KPI table
                const kpiSummaryContainer = document.createElement('div');
                kpiSummaryContainer.className = 'kpi-summary';
            
                // Add the header and cloned table
                const header = document.createElement('h3');
                header.textContent = '项目关键指标 Key Project Indicators';
                kpiSummaryContainer.appendChild(header);
                kpiSummaryContainer.appendChild(div.querySelector('table').cloneNode(true));
            
                // Insert the cloned KPI summary before the first chart in SalesChart tab
                if (firstChart) {
                  salesChartContainer.insertBefore(kpiSummaryContainer, firstChart);
                }
                console.log("KPI table updated in SalesChart tab");
            
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

      dialog.add_action_callback("update_scene_month") do |action_context, params|
        type, month = params.split('@', 2)
        model = Sketchup.active_model
        
        # Get current apartment data
        apartment_data = JSON.parse(model.get_attribute('apartment_type_data', type) || '{}')
        
        # Update the scene change month
        apartment_data['scene_change_month'] = month.to_i
        
        # Save back
        model.set_attribute('apartment_type_data', type, apartment_data.to_json)
        
        # Trigger a refresh of the output data
        update_output_data(dialog)
    end

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
      update_script = "updatePropertyLineStats(#{json_encoded_stats});"
      dialog.execute_script(update_script)
      
      begin
        # Get scene switches from apartment data
        model = Sketchup.active_model
        scene_switches = {}
        apartment_type_names = model.get_attribute('apartment_type_data', 'apartment_type_names', [])
        
        apartment_type_names.each do |apt_type|
          apt_data = JSON.parse(model.get_attribute('apartment_type_data', apt_type) || '{}')
          if apt_data['scene_change_month']
            scene_switches[apt_type] = apt_data['scene_change_month']
          end
        end
        
        # Calculate everything once with scene switches
        puts "Starting cashflow calculations with scene switches..."
        cashflow_data = CashFlowCalculator.calculate_sales_income(scene_switches)
        puts 'Sales income data:', cashflow_data[:income_table]
        full_cashflow = CashFlowCalculator.calculate_and_print_full_cashflow_table(cashflow_data)
        monthly_cashflow = CashFlowCalculator.calculate_monthly_cashflow(full_cashflow)
        
        # Generate HTML report using the calculated data
        cashflow_html = CashFlowCalculator.generate_html_report(full_cashflow)
        json_encoded_cashflow = cashflow_html.to_json
        dialog.execute_script("updateCashflowReport(#{json_encoded_cashflow});")
        
        # Format sales data for the chart using the actual sales volumes
        sales_data = {
          apartmentSales: {},
          priceChanges: {},
          metadata: {}
        }
        
        # Use sales_table instead of calculating backwards from income
        cashflow_data[:sales_table].each do |apt_type, monthly_values|
          type_number = extract_number_from_type(apt_type)
          next unless type_number
          
          sales_data[:apartmentSales][apt_type] = monthly_values
          sales_data[:priceChanges][apt_type] = []
          
          # Get the apartment data to access scene_change_month
          apt_data = JSON.parse(model.get_attribute('apartment_type_data', apt_type) || '{}')
          
          sales_data[:metadata][apt_type] = {
            number: type_number,
            originalName: apt_type,
            scene_change_month: apt_data['scene_change_month'] || 72,
            color: apt_data['color']  # Add this line to pass the custom color
          }
          
          # Add scene change points if they exist
          if scene_switches[apt_type]
            sales_data[:priceChanges][apt_type] << scene_switches[apt_type]
            puts "Added price change for #{apt_type} at month #{scene_switches[apt_type]}"
          end
        end
        
        # Prepare chart data
        cashflow_chart_data = {
          monthly: full_cashflow[:monthly_cashflow],
          accumulated: full_cashflow[:accumulated_cashflow]
        }
        
        # Update both charts
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
        # Get custom color from apartment data
        apt_data = get_apartment_data(type)
        custom_color = apt_data['color']
        
        # Use custom color if available, otherwise calculate based on type
        if custom_color
          table += "<th style='background-color: #{custom_color}; color: black; text-shadow: 0px 0px 4px white;'>#{type}</th>"
        elsif type.include?('商铺') || type.include?('办公') || type.include?('公寓')
          table += "<th style='background-color: hsl(0, 100%, 90%); color: black; text-shadow: 0px 0px 4px white;'>#{type}</th>"
        else
          area = type.scan(/\d+/).first.to_f
          hue = ((area - 50) * 2.5) % 360
          table += "<th style='background-color: hsl(#{hue}, 100%, 90%); color: black; text-shadow: 0px 0px 4px white;'>#{type}</th>"
        end
      end
    
      table += "<th>户数小计 Total Apartments</th>"
      table += "<th>用地面积 Parcel Ground Area (m²)</th>"
      table += "<th>总建面 Total Construction Area (m²)</th>"
      table += "<th>总可售建面 Total Sellable Construction Area (m²)</th>"
      table += "<th>计容配套面积 Amenity GFA in FAR (m²)</th>"
      table += "<th>可售净容积率 FAR</th>"
      table += "<th>建筑密度 Footprint Coverage Rate (%)</th></tr>"
    
      # Rest of the code remains the same
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
      table += "<th>面宽 Width (m)</th>"
      table += "<th>单价1</th><th>总价1</th><th>月流速1</th>"
      table += "<th>单价2</th><th>总价2</th><th>月流速2</th>"
      table += "<th>单价3</th><th>总价3</th><th>月流速3</th></tr>"
      
      sorted_apartment_types.each do |type|
        count = total_apartments[type]
        percentage = (count.to_f / grand_total * 100).round(2)
        width = apartment_data[type][:width]
        
        # Get custom color from apartment data
        apt_data = get_apartment_data(type)
        custom_color = apt_data['color']
        
        # Use custom color if available, otherwise calculate based on type
        bg_color = if custom_color
          custom_color
        elsif type.include?('商铺') || type.include?('办公') || type.include?('公寓')
          "hsl(0, 100%, 90%)"  # Red for commercial types
        else
          area = type.scan(/\d+/).first.to_f
          hue = ((area - 50) * 2.5) % 360
          "hsl(#{hue}, 100%, 90%)"
        end
    
        table += "<tr><td style='background-color: #{bg_color}; color: black; text-shadow: 0px 0px 3px white;'>#{type}</td><td>#{count}</td><td>#{percentage}%</td>"
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
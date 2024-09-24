require_relative '8_cashflow'  
require 'csv'
require 'json'

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
            body { font-family: Arial, sans-serif; padding: 20px; }
            .tab { overflow: hidden; border: 1px solid #ccc; background-color: #f1f1f1; }
            .tab button { background-color: inherit; float: left; border: none; outline: none; cursor: pointer; padding: 14px 16px; transition: 0.3s; }
            .tab button:hover { background-color: #ddd; }
            .tab button.active { background-color: #ccc; }
            .tabcontent { display: none; padding: 6px 12px; border: 1px solid #ccc; border-top: none; }
            table { border-collapse: collapse; width: 100%; font-size: 12px; }
            th, td { border: 1px solid black; padding: 3px; text-align: right; }
            th { background-color: #f2f2f2; }
            .property-line-stats { margin-top: 20px; }
            .refresh-button {
              position: absolute;
              top: 30px;
              right: 30px;
              padding: 5px 10px;
              background-color: #f00;
              color: white;
              border: none;
              cursor: pointer;
            }
          </style>
        </head>
        <body>
          <button class="refresh-button" onclick="refreshData()">刷新 Refresh</button>
          <div class="tab">
            <button class="tablinks" onclick="openTab('Summary')" id="defaultOpen">面积和户型统计 Summary</button>
            <button class="tablinks" onclick="openTab('CashflowReport')">现金流报表 Cashflow Report</button>
          </div>

          <div id="Summary" class="tabcontent">
            <h3>模型经济技术指标汇总 Project Output</h3>
            <p>地上部分总建筑面积 Total Construction Area: <span id="totalArea" style="font-weight: bold;">Calculating...</span> m²</p>
            <p>地上可售部分总建筑面积 Total Sellable Construction Area: <span id="totalSellableArea" style="font-weight: bold;">Calculating...</span> m²</p>
            <p>地上可售部分总货值 Total Sellable Value: <span id="totalSellableValue" style="font-weight: bold;">Calculating...</span> 万元</p>
            
            <div id="propertyLineStats" class="property-line-stats"></div>
            <button onclick="generateCSV()">Generate CSV Report</button>
          </div>

          
          <div id="CashflowReport" class="tabcontent">
            <p>Loading cashflow report...</p>
          </div>

          <script>
            function openTab(tabName) {
              var i, tabcontent, tablinks;
              tabcontent = document.getElementsByClassName("tabcontent");
              for (i = 0; i < tabcontent.length; i++) {
                tabcontent[i].style.display = "none";
              }
              tablinks = document.getElementsByClassName("tablinks");
              for (i = 0; i < tablinks.length; i++) {
                tablinks[i].className = tablinks[i].className.replace(" active", "");
              }
              document.getElementById(tabName).style.display = "block";
              event.currentTarget.className += " active";
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
            function refreshData() {
              console.log("Refreshing data...");
              window.location = 'skp:refresh_data';
            }
            function updateTotalSellableValue(value) {
              document.getElementById('totalSellableValue').textContent = value;
            }
            // Open the Summary tab by default
            document.getElementById("defaultOpen").click();
            // Signal that the page is loaded
            window.location = 'skp:on_page_load';
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
      total_area = calculate_total_construction_area
      total_sellable_area = calculate_total_sellable_construction_area
      dialog.execute_script("updateTotalArea('#{total_area.round}', '#{total_sellable_area.round}')")
    
      total_sellable_value = calculate_total_sellable_value
      dialog.execute_script("updateTotalSellableValue('#{total_sellable_value.round}')")
    

      
      property_line_stats = generate_property_line_stats
      puts "Generated property line stats (first 500 characters):"
      puts property_line_stats[0..499]
    
      # Use JSON encoding to properly escape the HTML string
      json_encoded_stats = property_line_stats.to_json
      puts "JSON encoded stats (first 500 characters):"
      puts json_encoded_stats[0..499]
    
      update_script = "console.log('Updating property line stats...'); updatePropertyLineStats(#{json_encoded_stats}); console.log('Update complete');"
      puts "Executing script:"
      puts update_script
    
      dialog.execute_script(update_script)
    
      begin
        cashflow_html = CashFlowCalculator.generate_html_report
        json_encoded_cashflow = cashflow_html.to_json
        dialog.execute_script("updateCashflowReport(#{json_encoded_cashflow});")
      rescue => e
        puts "Error generating cashflow report: #{e.message}"
        puts e.backtrace
        dialog.execute_script("document.getElementById('CashflowReport').innerHTML = 'Error generating cashflow report. Check Ruby Console for details.';")
      end
    end

    def self.calculate_total_construction_area
      model = Sketchup.active_model
      total_area = 0
      total_amenity_gfa = 0
      
      # Load project data to get the amenity GFA values
      project_data = JSON.parse(model.get_attribute('project_data', 'data', '{}'))
      amenity_gfa_data = project_data['propertyLines'] || []
      
      model.active_entities.grep(Sketchup::ComponentInstance).each do |instance|
        if instance.definition.attribute_dictionaries && instance.definition.attribute_dictionaries['building_data']
          area = instance.definition.get_attribute('building_data', 'total_area')
          total_area += area.to_f if area
        end
      end
      
      # Add amenity GFA from input data
      total_amenity_gfa = amenity_gfa_data.sum { |pl| pl['amenity_GFA_in_FAR'].to_f }
      
      total_area + total_amenity_gfa
    end
    
    def self.calculate_total_sellable_construction_area
      model = Sketchup.active_model
      total_sellable_area = 0
      model.active_entities.grep(Sketchup::ComponentInstance).each do |instance|
        if instance.definition.attribute_dictionaries && instance.definition.attribute_dictionaries['building_data']
          area = instance.definition.get_attribute('building_data', 'total_area')
          total_sellable_area += area.to_f if area
        end
      end
      total_sellable_area
    end

    def self.generate_csv_report
      begin
        puts "Attempting to access CashFlowCalculator..."
        if defined?(Real_Estate_Optimizer::CashFlowCalculator)
          puts "CashFlowCalculator is defined."
          cashflow_data = Real_Estate_Optimizer::CashFlowCalculator.calculate_and_print_full_cashflow_table
          monthly_cashflow = Real_Estate_Optimizer::CashFlowCalculator.calculate_monthly_cashflow(cashflow_data)
          key_indicators = Real_Estate_Optimizer::CashFlowCalculator.calculate_key_indicators(monthly_cashflow)
          puts "Received cashflow data, proceeding to generate CSV"
          
          # Default file name
          default_file_name = "real_estate_cashflow_report.csv"
          
          # Open file dialog for user to choose save location and file name
          file_path = UI.savepanel("Save Cashflow Report", "", default_file_name)
          
          if file_path
            puts "CSV will be saved to: #{file_path}"
            
            # Open file in binary write mode
            File.open(file_path, "wb") do |file|
              # Write UTF-8 BOM
              file.write("\xEF\xBB\xBF")
    
              # Create CSV object
              csv = CSV.new(file)

              
              # Write key indicators
              csv << ['项目关键指标 Key Project Indicators']
              csv << ['指标 Indicator', '值 Value']
              csv << ['内部收益率 IRR', "#{key_indicators[:irr] ? "#{key_indicators[:irr].round(2)}%" : 'N/A'}"]
              csv << ['销售毛利率 Gross Profit Margin', "#{key_indicators[:gross_profit_margin]}%"]
              csv << ['销售净利率 Net Profit Margin', "#{key_indicators[:net_profit_margin]}%"]
              csv << ['现金流回正（月） Cash Flow Positive Month', key_indicators[:cash_flow_positive_month]]
              csv << ['项目总销售额（含税） Total Sales (incl. tax)', key_indicators[:total_sales]]
              csv << ['项目总投资（含税） Total Investment (incl. tax)', key_indicators[:total_investment]]
              csv << ['项目资金峰值 Peak Negative Cash Flow', key_indicators[:peak_negative_cash_flow]]
              csv << ['项目净利润 Net Profit', key_indicators[:net_profit]]
              csv << ['企业所得税 Corporate Tax', key_indicators[:corporate_tax]]
              csv << ['税后净利润 Net Profit After Tax', key_indicators[:net_profit] - key_indicators[:corporate_tax]]
              csv << ['MOIC', key_indicators[:moic] || 'N/A']
              
              # Add a blank row for separation
              csv << []
              
              # Write headers
              csv << [
                '月份 Month',
                '计容产品销售收入 Apartment Sales',
                '预售资金监管要求 Supervision Fund Requirement',
                '资金监管存入 Fund Contribution',
                '资金监管解活 Fund Release',
                '车位销售收入 Parking Lot Sales',
                '总销售收入 Total Sales Income',
                '总现金流入小计 Total Cash Inflow',
                '土地规费 Land Fees',
                '配套建设费用 Amenity Construction Cost',
                '计容产品建安费用 Apartment Construction Payment',
                '税费 Fees and Taxes',
                '地下建安费用 Underground Construction Cost',
                '总现金流出小计 Total Cash Outflow',
                '月净现金流 Monthly Net Cashflow',
                '累计净现金流 Accumulated Net Cashflow',
                '增值税重新申报 VAT Re-declaration',
              ]
              
              # Write data
              monthly_cashflow.each do |month_data|
                csv << month_data.values
              end
            end
            puts "CSV generation completed successfully"
            UI.messagebox("CSV report generated and saved to: #{file_path}")
          else
            puts "CSV generation cancelled by user"
            UI.messagebox("CSV generation cancelled.")
          end
        else
          raise NameError, "CashFlowCalculator is not defined"
        end
      rescue StandardError => e
        error_message = "Error generating CSV: #{e.message}\n\n"
        error_message += "Error occurred at:\n#{e.backtrace.first}\n\n"
        error_message += "Full backtrace:\n#{e.backtrace.join("\n")}"
        puts error_message
        UI.messagebox(error_message)
      end
    end

    # Test methods (can be removed in production)
    def self.test_basic_file_write
      begin
        test_file_path = File.join(Sketchup.find_support_file("Documents"), "basic_test.csv")
        File.open(test_file_path, "w") do |file|
          file.puts "Header 1,Header 2"
          file.puts "Data 1,Data 2"
        end
        puts "Basic test file created successfully at #{test_file_path}"
        true
      rescue StandardError => e
        puts "Error in basic file write test: #{e.message}"
        puts e.backtrace
        false
      end
    end

    def self.test_csv_functionality
      begin
        test_file_path = File.join(Sketchup.find_support_file("Documents"), "csv_test.csv")
        puts "Attempting to open file at: #{test_file_path}"
        CSV.open(test_file_path, "wb") do |csv|
          puts "File opened successfully"
          puts "Writing header row..."
          csv << ["Header 1", "Header 2"]
          puts "Header row written"
          puts "Writing data row..."
          csv << ["Data 1", "Data 2"]
          puts "Data row written"
        end
        puts "CSV test file created successfully at #{test_file_path}"
        true
      rescue StandardError => e
        puts "Error in CSV test: #{e.message}"
        puts "Error backtrace:"
        puts e.backtrace
        false
      end
    end

    def self.run_tests
      puts "Testing basic file write..."
      if test_basic_file_write
        puts "Basic file write successful. Testing CSV functionality..."
        if test_csv_functionality
          puts "CSV functionality test passed. Generating full report..."
          generate_csv_report
        else
          UI.messagebox("CSV functionality test failed. Cannot proceed with report generation.")
        end
      else
        UI.messagebox("Basic file write test failed. Check file system permissions.")
      end
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
    
    def self.generate_property_line_table(property_line_data, all_apartment_types)
      sorted_apartment_types = sort_apartment_types(all_apartment_types)
      
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
    
      property_line_data.each do |keyword, data|
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
        puts "Debug: Apartment type: #{type}, Width: #{width}"

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
    
    def self.get_apartment_data(apt_type)
      model = Sketchup.active_model
      JSON.parse(model.get_attribute('aparment_type_data', apt_type, '{}'))
    end

    def self.sort_apartment_types(apartment_types)
      apartment_types.sort_by { |type| type.scan(/\d+/).first.to_i }
    end

    def self.calculate_total_sellable_value
      model = Sketchup.active_model
      total_value = 0
    
      model.active_entities.grep(Sketchup::ComponentInstance).each do |instance|
        if instance.definition.attribute_dictionaries && instance.definition.attribute_dictionaries['building_data']
          apartment_stocks = JSON.parse(instance.definition.get_attribute('building_data', 'apartment_stocks') || '{}')
          apartment_stocks.each do |apt_type, count|
            apt_data = get_apartment_data(apt_type)
            area = apt_data['area'].to_f
            unit_price = apt_data['sales_scenes'].first['price'].to_f if apt_data['sales_scenes'] && apt_data['sales_scenes'].first
            total_value += count * unit_price * area if unit_price && area
          end
        end
      end
    
      total_value / 10000 # Convert to 万元
    end
  end
end
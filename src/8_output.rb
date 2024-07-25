require_relative '8_cashflow'  
require 'csv'


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
          </style>
        </head>
        <body>
          <div class="tab">
            <button class="tablinks" onclick="openTab('Summary')" id="defaultOpen">Summary</button>
            <button class="tablinks" onclick="openTab('CashflowReport')">Cashflow Report</button>
          </div>

          <div id="Summary" class="tabcontent">
            <h2>模型经济技术指标汇总 Project Output</h2>
            <p>地上可售部分总建筑面积 Total Construction Area: <span id="totalArea">Calculating...</span> m²</p>
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

            function generateCSV() {
              window.location = 'skp:generate_csv';
            }
            function updateTotalArea(area) {
              document.getElementById('totalArea').textContent = area;
            }
            function updateCashflowReport(html) {
              try {
                document.getElementById('CashflowReport').innerHTML = html;
                console.log("Cashflow report updated successfully");
              } catch (error) {
                console.error("Error updating cashflow report:", error);
              }
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
        total_area = calculate_total_construction_area
        dialog.execute_script("updateTotalArea('#{total_area.round(2)}')")
        
        # Generate and insert the cashflow report
        begin
          cashflow_html = CashFlowCalculator.generate_html_report
          escaped_html = cashflow_html.gsub('"', '\"').gsub("\n", "\\n")
          dialog.execute_script("updateCashflowReport(\"#{escaped_html}\");")
        rescue => e
          puts "Error generating cashflow report: #{e.message}"
          puts e.backtrace
          dialog.execute_script("document.getElementById('CashflowReport').innerHTML = 'Error generating cashflow report. Check Ruby Console for details.';")
        end
      end

      dialog.show
    end

    def self.calculate_total_construction_area
      model = Sketchup.active_model
      total_area = 0
      model.active_entities.grep(Sketchup::ComponentInstance).each do |instance|
        if instance.definition.attribute_dictionaries && instance.definition.attribute_dictionaries['building_data']
          area = instance.definition.get_attribute('building_data', 'total_area')
          total_area += area.to_f if area
        end
      end
      puts "Calculated total construction area: #{total_area} m²"
      total_area
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
  end
end
require_relative 'cashflow'  
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
          :width => 300,
          :height => 200,
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
            button { margin-top: 20px; }
          </style>
        </head>
        <body>
          <h2>模型经济技术指标汇总 Project Output</h2>
          <p>地上可售部分总建筑面积 Total Construction Area: <span id="totalArea">Calculating...</span> m²</p>
          <button onclick="generateCSV()">Generate CSV Report</button>
          <script>
            function generateCSV() {
              window.location = 'skp:generate_csv';
            }
            function updateTotalArea(area) {
              document.getElementById('totalArea').textContent = area;
            }
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
            puts "Received cashflow data, proceeding to generate CSV"
            
            # Adjusted file path to save in the current directory
            file_path = File.join(File.dirname(__FILE__), "real_estate_cashflow_report.csv")
            puts "CSV will be saved to: #{file_path}"
            
            CSV.open(file_path, "wb") do |csv|
                csv << ['Month', 'Land Payment', 'Construction Payment', 'Sales Income', 'Basement Income', 'Basement Expenses', 'Parking Lot Stock', 'Monthly Cashflow', 'Accumulated Cashflow']
                
                48.times do |index|
                    row = [
                    index,
                    cashflow_data[:land_payments] ? cashflow_data[:land_payments][index] : 'N/A',
                    cashflow_data[:construction_payments] ? cashflow_data[:construction_payments][index] : 'N/A',
                    cashflow_data[:total_income] ? cashflow_data[:total_income][index] : 'N/A',
                    cashflow_data[:basement_income] ? cashflow_data[:basement_income][index] : 'N/A',
                    cashflow_data[:basement_expenses] ? cashflow_data[:basement_expenses][index] : 'N/A',
                    cashflow_data[:basement_parking_lot_stock] ? cashflow_data[:basement_parking_lot_stock][index] : 'N/A',
                    cashflow_data[:monthly_cashflow] ? cashflow_data[:monthly_cashflow][index] : 'N/A',
                    cashflow_data[:accumulated_cashflow] ? cashflow_data[:accumulated_cashflow][index] : 'N/A'
                    ]
                    csv << row.map { |item| item.nil? ? 'N/A' : item.to_s }
                end
                end
            puts "CSV generation completed successfully"
            # UI.messagebox("CSV report generated and saved to: #{file_path}")
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
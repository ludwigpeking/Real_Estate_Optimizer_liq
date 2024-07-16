module Real_Estate_Optimizer
  module BuildingAttributeEditor
    def self.show_dialog
      dialog = UI::HtmlDialog.new(
        {
          :dialog_title => "Building Attributes",
          :preferences_key => "com.example.building_attribute_editor",
          :scrollable => true,
          :resizable => true,
          :width => 300,
          :height => 200,
          :left => 100,
          :top => 100
        }
      )
      
      dialog.set_html(create_html)
      dialog.add_action_callback("update_attributes") { |action_context, value| 
        puts "update_attributes callback received with value: #{value}" # Debug log
        update_attributes(value) 
      }
      
      selection_observer = add_selection_observer(dialog)
      
      dialog.set_on_closed {
        Sketchup.active_model.selection.remove_observer(selection_observer)
      }
      
      # Add this new callback
      dialog.add_action_callback("initialize_dialog") { |action_context|
        update_dialog_with_selection(Sketchup.active_model.selection, dialog)
      }
      
      dialog.show
    end

    def self.create_html
      html = <<-HTML
        <!DOCTYPE html>
        <html>
        <meta charset="UTF-8">
        <head>
          <style>
            body { font-family: Arial, sans-serif; }
            .attribute { margin-bottom: 10px; }
            input { width: 100%; }
          </style>
        </head>
        <body>
          <div class="attribute">
            <label for="construction_init_time">第几月开工 Construction Init Time (months):</label>
            <input type="number" id="construction_init_time" onchange="updateAttributes()">
          </div>
          <div class="attribute">
            <label for="sales_permit_time">开工后第几月取预售证 Sales Permit Time (months):</label>
            <input type="number" id="sales_permit_time" onchange="updateAttributes()">
          </div>
        
          <script>
          function updateAttributes() {
              var constructionInitTime = document.getElementById('construction_init_time').value;
              var salesPermitTime = document.getElementById('sales_permit_time').value;
              console.log('Updating attributes:', {
                  construction_init_time: constructionInitTime,
                  sales_permit_time: salesPermitTime
              }); // Debug log
              sketchup.update_attributes(JSON.stringify({
                  construction_init_time: constructionInitTime,
                  sales_permit_time: salesPermitTime
              }));
          }
          
          function setAttributes(attributes) {
              console.log('Setting attributes:', attributes); // Debug log
              document.getElementById('construction_init_time').value = attributes.construction_init_time !== null ? attributes.construction_init_time : '';
              document.getElementById('sales_permit_time').value = attributes.sales_permit_time !== null ? attributes.sales_permit_time : '';
          }
          window.onload = function() {
              sketchup.initialize_dialog();
          }
          </script>
        </body>
        </html>
      
      HTML
    end

    def self.add_selection_observer(dialog)
      observer = MySelectionObserver.new(dialog)
      Sketchup.active_model.selection.add_observer(observer)
      observer
    end

    def self.update_dialog_with_selection(selection, dialog)
      puts "Updating dialog with selection: #{selection}" # Debug log
      attributes = get_common_attributes(selection)
      json_attributes = attributes.to_json
      puts "Retrieved attributes JSON: #{json_attributes}" # Debug log
      dialog.execute_script("setAttributes(#{json_attributes})")
    end
    
    def self.get_common_attributes(selection)
      common_attributes = {
        'construction_init_time' => nil,
        'sales_permit_time' => nil
      }
    
      selection.each do |entity|
        next unless entity.is_a?(Sketchup::ComponentInstance)
        
        construction_init_time = entity.get_attribute('dynamic_attributes', 'construction_init_time')
        sales_permit_time = entity.get_attribute('dynamic_attributes', 'sales_permit_time')
        
        puts "Entity: #{entity}, Construction Init Time: #{construction_init_time}, Sales Permit Time: #{sales_permit_time}" # Debug log
    
        if common_attributes['construction_init_time'].nil? || common_attributes['construction_init_time'] == construction_init_time
          common_attributes['construction_init_time'] = construction_init_time
        else
          common_attributes['construction_init_time'] = nil
        end
    
        if common_attributes['sales_permit_time'].nil? || common_attributes['sales_permit_time'] == sales_permit_time
          common_attributes['sales_permit_time'] = sales_permit_time
        else
          common_attributes['sales_permit_time'] = nil
        end
      end
    
      puts "Common attributes: #{common_attributes}" # Debug log
      common_attributes
    end

    def self.update_attributes(value)
      attributes = JSON.parse(value)
      puts "Updating attributes with: #{attributes}" # Debug log
      selection = Sketchup.active_model.selection
      
      if selection.empty?
        puts "No selection to update."
        return
      end

      model = Sketchup.active_model
      model.start_operation('Update Attributes', true)

      selection.each do |entity|
        next unless entity.is_a?(Sketchup::ComponentInstance)
        
        if attributes['construction_init_time'] != ''
          entity.set_attribute('dynamic_attributes', 'construction_init_time', attributes['construction_init_time'].to_i)
        end

        if attributes['sales_permit_time'] != ''
          entity.set_attribute('dynamic_attributes', 'sales_permit_time', attributes['sales_permit_time'].to_i)
        end
      end

      model.commit_operation
    end

    class MySelectionObserver < Sketchup::SelectionObserver
      def initialize(dialog)
        @dialog = dialog
      end

      def onSelectionAdded(selection, entity)
        puts "onSelectionAdded: #{entity}" # Debug log
        BuildingAttributeEditor.update_dialog_with_selection(selection, @dialog)
      end

      def onSelectionRemoved(selection, entity)
        puts "onSelectionRemoved: #{entity}" # Debug log
        BuildingAttributeEditor.update_dialog_with_selection(selection, @dialog)
      end

      def onSelectionCleared(selection)
        puts "onSelectionCleared: #{selection}" # Debug log
        BuildingAttributeEditor.update_dialog_with_selection(selection, @dialog)
      end

      def onSelectionBulkChange(selection)
        puts "onSelectionBulkChange: #{selection}" # Debug log
        BuildingAttributeEditor.update_dialog_with_selection(selection, @dialog)
      end
    end
  end
end


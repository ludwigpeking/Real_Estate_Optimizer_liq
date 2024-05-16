require 'sketchup.rb'
require 'extensions.rb'

module Urban_Banal
    module Real_Estate_Optimizer
        module Input
            @@dialog = nil
            def self.input
                @@dialog ||= UI::HtmlDialog.new(
                    {
                        :dialog_title => "输入经济指标",
                        :scrollable => true,
                        :resizable => true,
                        :width => 500,
                        :height => 700,
                        :left => 100,
                        :top => 100,
                        :style => UI::HtmlDialog::STYLE_DIALOG
                    }
                )
            
                file_path = File.join(__dir__, "input_form.html")
                @@dialog.set_file(file_path)
            
                @@dialog.add_action_callback("save_data") do |action_context, data|
                    data = JSON.parse(data)
                    save_data(data['tag'], data['data'])
                end
            
                @@dialog.add_action_callback("load_data") do |action_context, tag|
                    load_data(tag)
                end
            
                update_tag_options  # Ensure tags are updated whenever the dialog is opened
                @@dialog.show unless @@dialog.visible?
            end
            
            def self.update_tag_options
                model = Sketchup.active_model
                dictionary = model.attribute_dictionaries["EconomicIndicators"]
                tags = dictionary ? dictionary.keys.sort : []
                @@dialog.execute_script("updateTagOptions(#{tags.to_json})") if @@dialog && @@dialog.visible?
            end
            
            

            def self.save_data(tag, data)
                model = Sketchup.active_model
                begin
                    model.start_operation('Save Economic Data', true)
                    dictionary = model.attribute_dictionary("EconomicIndicators", true)
                    
                    # Serialize data to JSON before storing
                    dictionary[tag] = data.to_json
                    model.commit_operation
                    UI.messagebox("Data saved successfully under tag: #{tag}")
                    
                    update_tag_options  # Make sure to update the tags in the UI
                rescue => e
                    model.abort_operation
                    UI.messagebox("Error saving data: #{e.message}")
                end
            end
            
            
            def self.update_tag_options
                model = Sketchup.active_model
                dictionary = model.attribute_dictionaries["EconomicIndicators"]
                tags = dictionary ? dictionary.keys.sort : []  # Ensure tags are sorted or manage duplicates
                dialog = get_dialog
                if dialog && dialog.visible?
                    dialog.execute_script("updateTagOptions(#{tags.to_json})")
                end
            end
            

            def self.load_data(tag)
                model = Sketchup.active_model
                dictionary = model.attribute_dictionaries["EconomicIndicators"]
                
                if dictionary && dictionary[tag]
                    data = JSON.parse(dictionary[tag])
                    js_command = "updateInputs(#{data.to_json})"
                    get_dialog.execute_script(js_command)
            
                    update_tag_options  # Call after load too if it affects tag list
                else
                    UI.messagebox("No data found for tag: #{tag}.")
                end
            end
            

            def self.get_dialog
                # Ensure this returns your current dialog instance.
                # You may need to adjust this part to correctly fetch or store the dialog instance.
                @@dialog
            end

        end
    end
end

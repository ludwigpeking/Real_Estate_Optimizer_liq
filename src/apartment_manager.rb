require 'sketchup.rb'
require_relative 'apartment_type'


module Urban_Banal
    module Real_Estate_Optimizer
        module ApartmentManager
            def self.add_apartment_type
                prompts = ["Type", "Area", "Comment Tag", "Unit Cost", "Net Area Ratio", "Width", "Depth", "Level Height", "Scenarios (JSON)"]
                defaults = ["Type", "100", "Default Tag", "1000", "0.75", "10", "10", "3", "[{\"unit_price\": 1000, \"monthly_sales\": 10}]"]
                input = UI.inputbox(prompts, defaults, "Add Apartment Type")

                return unless input

                type, area, comment_tag, unit_cost, net_area_ratio, width, depth, level_height, scenarios_json = input
                scenarios = JSON.parse(scenarios_json)

                apartment = ApartmentType.new(type, area.to_f, comment_tag, unit_cost.to_f, net_area_ratio.to_f, width.to_f, depth.to_f, level_height.to_f, scenarios)
                save_apartment_type(apartment)
                UI.messagebox("Apartment Type Saved!")
            end

            def self.save_apartment_type(apartment)
                model = Sketchup.active_model
                dictionary = model.attribute_dictionaries["ApartmentTypes"] || model.attribute_dictionaries.add("ApartmentTypes")
                dictionary[apartment.name_tag] = apartment.to_hash
            end

            def self.load_apartment_type(name_tag)
                model = Sketchup.active_model
                dictionary = model.attribute_dictionaries["ApartmentTypes"]
                return unless dictionary

                apartment_data = dictionary[name_tag]
                return unless apartment_data

                ApartmentType.from_hash(apartment_data)
            end

            if !file_loaded?(__FILE__)
                UI.menu("Plugins").add_item("Add Apartment Type") {
                    self.add_apartment_type
                }
                file_loaded(__FILE__)
            end
        end
    end
end

require 'flight_plan.rb'

require_relative 'action.rb'
require_relative 'action/move_to.rb'
require_relative 'action/spray_on.rb'
require_relative 'action/spray_off.rb'
require_relative 'action/no_op.rb'
require_relative 'action/hover.rb'

require 'gml.rb'

class FlightPlan
	class Generator
		class GML
			def self.generate(gml_input)
				return nil if not gml_input.kind_of? Tag

				return nil if gml_input.strokes.empty?

				flight_plan = FlightPlan.new

				gml_input.strokes.to_enum.with_index(1).each do |stroke, i|
					next if stroke.points.empty?

					stroke.points.to_enum.with_index(1).each do |point, j|
						if j == 1
							# for the first point go to the begenning of the stroke and turn on the spray can
							flight_plan << FlightPlan::Action::MoveTo.new(point.x, point.y)
							flight_plan << FlightPlan::Action::Hover.new
							flight_plan << FlightPlan::Action::SprayOn.new
						end

						# go to each point in the stroke as you spray
						flight_plan << FlightPlan::Action::MoveTo.new(point.x, point.y)
					end

					# turn the spray off at the end of the stroke
					flight_plan << FlightPlan::Action::SprayOff.new
				end

				# return 'home'
				flight_plan << FlightPlan::Action::MoveTo.new(0.0, 0.0)
				flight_plan << FlightPlan::Action::Hover.new

				return flight_plan
			end
		end
	end
end
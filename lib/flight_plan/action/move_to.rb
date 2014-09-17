class FlightPlan
	class Action
		class MoveTo
			def initialize(init_x, init_y)
				@x = init_x
				@y = init_y
			end

			def x
				@x
			end

			def y
				@y
			end
		end
	end
end
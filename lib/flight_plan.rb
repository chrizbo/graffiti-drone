class FlightPlan 
	@actions = []
	@current_waypoint = nil

	def initialize(initial_actions=[])
		@actions = initial_actions
		@current_action = -1
	end

	def actions
		@actions
	end

	def actions=(new_actions)
		@actions = new_actions
		@current_actions = -1
	end

	def <<(action)
		@actions << action
	end

	def current_action
		@current_action
	end

	def current_action=(new_current_action)
		@current_action = new_current_action
	end

	def next_action
		@current_action = @current_action + 1 < @actions.size ? @current_action + 1 : nil
		
		unless @current_action.nil?
			@actions[@current_action]
		else
			nil
		end
	end
end
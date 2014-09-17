require "graffiti_drone/version"

require 'argus'
require 'httparty'
require 'eventmachine'
require 'aasm'
require 'rb-pid-controller'

class GraffitiDrone
	include AASM

	# ARGUS drone instance
	@drone
	@flight_plan

	@current_x
	@current_y
	@current_yaw

	# Arduino configuration and current state variables
	DRONE_ARDUINO_IP = '192.168.1.10'
	SPRAYING_ENABLED = false

	@currently_spraying
	@left_sonar_distance # in cm
	@right_sonar_distance # in cm
	@last_arduino_update

	DRONE_WIDTH = 25.5 # in cm for Parrot AR drone with sonar sensors on each front prop
	IDEAL_SPRAY_DISTANCE = 30.5 # in cm, approx 1 foot for the regular Montana Micro cap

	# AR Drone configuration and current state variables
	DRONE_IP = '192.168.1.1'

	# Number of ticks per second for processing and adjustment
	DRONE_THRUST = 0.25
	DRONE_TICK_RATE = 1.0

	# only yaw and X are PI(not-D) controls, Y and Z are controlled by the flight path
	YAW_ADJUSTMENT_RATE = 0.1
	@yaw_pid

	X_ADJUSTMENT_RATE = 0.1
	@wall_distance_pid

	@timer = nil

	aasm do
		state :disconnected, :initial => true
		state :off
		state :started
		state :taking_off
		state :searching_for_wall
		state :tagging
		state :landing
		state :landed

		event :connect do
			transitions :from => :disconnected, :to => :off
		end

		event :start do
			transitions :from => :off, :to => :started
		end

		event :take_off do
			transitions :from => :started, :to => :taking_off
		end

		event :search_for_wall do
			transitions :from => :taking_off, :to => :searching_for_wall
		end

		event :wall_found do
			transitions :from => :searching_for_wall, :to => :tagging
		end

		event :land do
			transitions :from => [:tagging, :searching_for_wall, :wall_found], :to => :landed
		end

		event :stop do
			transitions :from => :landed, :to => :off
		end

		# event :emergency_land do
		# 	transitions :from => [:taking_off, :searching_for_wall, :tagging, :landing], :to =>
		# end
	end

	def initialize
		@current_x = 0.0
		@current_y = 0.0

		@currently_spraying = false
		@left_sonar_distance = 0 
		@right_sonar_distance = 0
		@last_arduino_update = Time.now

		@flight_plan = nil

		@drone = Argus::Drone.new

		@wall_distance_pid = PIDController::PI.new(10, 1)
		@yaw_pid = PIDController::PI.new(10, 1)

		connect if @drone
	end

	def drone
		@drone
	end
	
	def flight_plan=(new_flight_plan)
		@flight_plan = new_flight_plan
	end

	def tag
		puts "Taking off"
		drone_take_off

		puts "Searching for wall"
		search_for_wall

		# TODO: put in method to adjust x and yaw for wall to defaults

		puts "Wall found"
		wall_found

		EventMachine.run do
			@timer = EventMachine::PeriodicTimer.new(DRONE_TICK_RATE) do
				unless tick
					@timer.cancel 

					puts "Landing"
					drone_land

					EventMachine.stop
				end
			end
		end
	end

	private

	def calculate_yaw
		@current_yaw = atan((@left_sonar_distance - @right_sonar_distance) / DRONE_WIDTH)
	end

	# do this on some loop to get current state
	def get_current_arduino_state 
		begin
			response = HTTParty.get("http://" + DRONE_ARDUINO_IP + "/", :timeout => 1)	
			parse_arduino_state(response)
		rescue Timeout::Error
			puts "Timeout when connecting to Arduino"
		rescue
			puts "Other error when connecting with Arduino"
		end
	end

	def parse_arduino_state(response)
		values = JSON.parse(response)

		@left_sonar_distance = values['leftDistance']
		@right_sonar_distance = values['rightDistance']
		calculate_yaw

		@currently_spraying = values['spraying']
		@last_arduino_update = Time.now
	end

	def start_spraying
		begin
			response = HTTParty.get("http://" + DRONE_ARDUINO_IP + "/spray/on", :timeout => 1)	
			parse_arduino_state(response)
		rescue Timeout::Error
			puts "Timeout when connecting to Arduino"
		rescue
			puts "Other error when connecting with Arduino"
		end
	end

	def end_spraying
		begin
			response = HTTParty.get("http://" + DRONE_ARDUINO_IP + "/spray/off", :timeout => 1)	
			parse_arduino_state(response)
		rescue Timeout::Error
			puts "Timeout when connecting to Arduino"
		rescue
			puts "Other error when connecting with Arduino"
		end
	end

	def spraying?
		currently_spraying
	end

	# TODO: put a real PID controller here to get yaw to 0 setpoint
	def yaw_adjustment
		if 0 < @current_yaw
			@drone.turn_right(DRONE_THRUST)
		elsif @current_yaw < 0
			@drone.turn_left(DRONE_THRUST)
		else
			# do nothing if == 0
		end
	end

	# TODO: put a real PID controller here to get x to IDEAL_SPRAY_DISTANCE
	def x_adjustment
		average_x_distance = (@left_sonar_distance + @right_sonar_distance) / 2 

		if average_x_distance > IDEAL_SPRAY_DISTANCE
			@drone.forward(DRONE_THRUST)
		elsif average_x_distance < IDEAL_SPRAY_DISTANCE
			@drone.backward(DRONE_THRUST)
		else
			# do nothing if at the IDEAL_SPRAY_DISTANCE
		end
	end

	# TODO: how do we even out the thrust if we need to go the oppocite direction from where we are currently going?
	def drone_move(horizontal_dist, vertical_dist)
		return if horizontal_dist == 0 && vertical_dist == 0

		if horizontal_dist < 0
			puts "Drone left"
			@drone.left(DRONE_THRUST)  
		elsif horizontal_dist > 0
			puts "Drone right"
			@drone.right(DRONE_THRUST)  
		end

		if vertical_dist < 0
			puts "Drone down"
			@drone.down(DRONE_THRUST)  
		elsif vertical_dist > 0
			puts "Drone up"
			@drone.up(DRONE_THRUST)  
		end
	end

	def drone_take_off
		start
		@drone.start
		sleep 2

		take_off
		@drone.take_off
		sleep 2

		@drone.hover
	end

	def drone_land
		@drone.hover
		sleep 2

		land
		@drone.land
		sleep 2
		
		stop
		@drone.stop
	end

	def tick
		puts "============================================="
		puts "Tick: " + Time.now.to_s

		# TODO: enable x and yaw adjustment
		# x_adjustment
		# yaw_adjustment

		next_action = @flight_plan.next_action

		if next_action
			case next_action
				when FlightPlan::Action::MoveTo
					puts "Current position: #{@current_x}, #{@current_y}"
					puts "Next position: #{next_action.x}, #{next_action.y}"
					x_diff = next_action.x - @current_x
					y_diff = next_action.y - @current_y

					puts "Move: #{x_diff}, #{y_diff}"

					drone_move(x_diff, y_diff)

					# update the current location to use for next tick
					@current_x = next_action.x
					@current_y = next_action.y
				when FlightPlan::Action::Hover
					puts "Hover"
					@drone.hover
				when FlightPlan::Action::SprayOn
					puts "Spray on"
					start_spraying
				when FlightPlan::Action::SprayOff
					puts "Spray off"
					end_spraying
			end

			# keep ticking
			return true
		else
			puts "No more actions, timer canceled"

			# stop ticking
			return false
		end
	end
end

require 'flight_plan'

describe FlightPlan do
	describe '#initialize' do
		it 'creates a new FlightPlan with actions' do
			flight_plan = FlightPlan.new([[1.0, 0.0], [0.0, 0.0]])
			expect(flight_plan.actions).to match_array([[1.0, 0.0], [0.0, 0.0]])
		end
	end

	describe '#next_action' do
		describe 'next action available' do
			it 'should return the next action' do
				flight_plan = FlightPlan.new([[1.0, 0.0], [0.0, 0.0]])
				expect(flight_plan.next_action).to match_array([1.0, 0.0])
			end

			it 'should incriment the current location' do
				flight_plan = FlightPlan.new([[1.0, 0.0], [0.0, 0.0]])
				__action = flight_plan.next_action
				__action = flight_plan.next_action
				expect(flight_plan.current_action).to be(1)
			end
		end

		describe 'no more actions' do
			it 'should return nil' do
				flight_plan = FlightPlan.new([[1.0, 0.0], [0.0, 0.0]])
				__action = flight_plan.next_action
				__action = flight_plan.next_action
				__action = flight_plan.next_action
				expect(flight_plan.current_action).to be_nil			
			end
		end
	end
end


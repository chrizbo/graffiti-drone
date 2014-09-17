class Tag
	@name = nil
	@strokes = []

	def name
		@name
	end

	def name=(new_name)
		@name = new_name
	end

	def describe
		puts "Tag name: #{name}"

		# print out the strokes and points
		strokes.to_enum.with_index(1).each do |stroke, i|
			puts "Stroke #{i}: #{stroke.points.count} points"
			
			last_point = Tag::Stroke::Point.new(0.0, 0.0)
			stroke.points.to_enum.with_index(1).each do |point, j|
				puts "\tPoint #{j}: #{point.x.to_s}, #{point.y.to_s}, diff: #{point.x - last_point.x}, #{point.y - last_point.y}"
				last_point = point
			end
		end

	end

	def strokes
		@strokes
	end

	def strokes=(new_strokes)
		@strokes = new_strokes
	end

	class Stroke
		@points = nil

		def points
			@points
		end

		def points=(new_points)
			@points = new_points
		end

		class Point
			@x = nil
			@y = nil

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

			def x=(new_x)
				@x = new_x
			end

			def y=(new_y)
				@y = new_y
			end

			def diff(other_tag)
				return [self.x - other_tag.x, self.y - other_tag.y]
			end
		end
	end
end
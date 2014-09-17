require 'ox'

require_relative 'tag.rb'

module GML
	def self.read(gml_location)
		file_content = IO.read(gml_location)
		doc = Ox.parse(file_content)

		tag = Tag.new

		tag.name = doc.locate('tag/header/client/name/^Text').first

		tag_strokes = []

		doc.locate('tag/drawing/stroke').each do |stroke|
			current_stroke = Tag::Stroke.new
			strokes_points = []

			stroke.locate('pt').each do |point|
				strokes_points << Tag::Stroke::Point.new(point.x.text.to_f, point.y.text.to_f)
			end

			current_stroke.points = strokes_points

			tag_strokes << current_stroke
		end    
		
		tag.strokes = tag_strokes

		tag
	end
end
require 'tag'

describe Tag, '#name' do
	it 'sets the name' do
		tag = Tag.new
		tag.name = 'New name'
		expect(tag.name).to eq('New name')
	end
end

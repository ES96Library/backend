class Value < ActiveRecord::Base
	belongs_to :property, :touch => true
	belongs_to :item, :dependent => :destroy, :touch => true

	searchable do
		text :name
		integer :item_id
		integer :property_id, :multiple => true
	
		string :sort_name do
			name.downcase.gsub(/^(an?|the)/, '')
		end
	end
end
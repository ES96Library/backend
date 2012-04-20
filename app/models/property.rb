class Property < ActiveRecord::Base
	has_many :values
	has_many :items, :through => :values
	
	attr_accessible :name
end

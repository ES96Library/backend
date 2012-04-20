class Property < ActiveRecord::Base
	has_many :values, :dependent => :destroy
	has_many :items, :through => :values
	
	attr_accessible :name
	
	after_save { |property| property.destroy if property.name.blank? }
end

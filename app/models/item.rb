class Item < ActiveRecord::Base
	has_many :values
	has_many :properties, :through => :values, :uniq => true
	accepts_nested_attributes_for :properties, :allow_destroy => :false
end

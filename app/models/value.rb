class Value < ActiveRecord::Base
	belongs_to :property, :touch => true
	belongs_to :item, :dependent => :destroy, :touch => true
	accepts_nested_attributes_for :property, :allow_destroy => false
	
	attr_accessible :property_attributes, :name
end
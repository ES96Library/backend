class Value < ActiveRecord::Base
	belongs_to :property, :touch => true
	belongs_to :item, :dependent => :destroy, :touch => true
end
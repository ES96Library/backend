class Value < ActiveRecord::Base
	belongs_to :property, :touch => true
	belongs_to :item, :touch => true
	
	accepts_nested_attributes_for :property, :allow_destroy => true, :reject_if => proc { |attrs| attrs.all? { |k, v| v.blank? } }
	
	attr_accessible :property_attributes, :name
	
	after_save { |value| value.destroy if value.name.blank? }
	
	def self.search(query)
		words = query.to_s.downcase.strip.split.uniq
		words.inject(scoped) do |combined_scope, word|
		  combined_scope.where("name LIKE ?", "%#{word}%")
		end
	end
end
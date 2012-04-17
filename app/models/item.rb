class Item < ActiveRecord::Base
    attr_accessible :image, :image_file_name 
	
	has_many :values
	has_many :properties, :through => :values, :uniq => true
	accepts_nested_attributes_for :properties, :allow_destroy => :false
	
	has_attached_file :image, 
					  :styles => {:large => "850x1310>", :preview => "640x985>", :thumb => "260x400>" },
					  :storage => :s3,
					  :s3_credentials => "/var/www/backend-lib/config/aws_access.yml",
					  :s3_storage_class => :reduced_redundancy,
					  :path => ":attachment/:id/:hash.:extension",
					  :hash_secret => "prototypingissuchabitch",
					  :bucket => "es96library", 
					  :default_url => 'http://i.imgur.com/E9EFl.jpg'					  
end

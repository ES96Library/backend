class Item < ActiveRecord::Base
    attr_accessible :image, :image_file_name, :values_attributes
	
	has_many :values, :dependent => :destroy
	has_many :properties, :through => :values, :uniq => true, :select => "DISTINCT properties.*"
	
	accepts_nested_attributes_for :values, :allow_destroy => true, :reject_if => proc { |attrs| attrs[:name].blank? }
	
	has_attached_file :image, 
					  :styles => {:large => "850x1310>", :preview => "640x985>", :thumb => "260x400>" },
					  :storage => :s3,
					  :s3_credentials => "/var/www/backend-lib/config/aws_access.yml",
					  :s3_storage_class => :reduced_redundancy,
					  :path => ":attachment/:id/:hash.:extension",
					  :hash_secret => "your_hash_secret",
					  :bucket => "your_S3_bucket", 
					  :default_url => 'http://i.imgur.com/E9EFl.jpg'					  
end

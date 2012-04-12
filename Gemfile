source 'http://rubygems.org'

gem 'rails', '3.1.0'

# Bundle edge Rails instead:
# gem 'rails',     :git => 'git://github.com/rails/rails.git'

gem 'chronic' # converts plaintext into datetime (i.e. now => 04/06/12 6:00 PM)
gem 'sqlite3' # default database in rails
gem 'mysql2', '> 0.3' #adds mysql support
gem "paperclip", "~> 2.4" # image uploading
gem 'aws-sdk', '~> 1.3.4' # image storage
# gem "koala" #facebook authentication
gem 'validates_timeliness', '~> 3.0.2' # datetime validation

gem 'will_paginate', '~> 3.0' # paginates everything

# search related stuff
gem 'sunspot_rails' # search plugin
gem 'sunspot_solr' # optional pre-packaged Solr distribution for use in development

# layout-related stuff
# gem 'twitter-bootstrap-rails'
# gem "compass", ">= 0.11.5"
# gem 'compass-960-plugin', :require => 'ninesixty'
# gem 'haml', '3.0.10'
gem 'jquery-rails' # adds jquery support for rendering/serving JS

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails', "  ~> 3.1.0"
  gem 'coffee-rails', "~> 3.1.0"
  gem 'uglifier'
end

# Use unicorn as the web server
# gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'

# To use debugger
# gem 'ruby-debug19', :require => 'ruby-debug'

group :test do
  # Pretty printed test output
  gem 'turn', :require => false
end

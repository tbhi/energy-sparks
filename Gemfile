source 'https://rubygems.org'

ruby '2.5.3'

# Rails/Core
gem 'rails', '~> 6.0.0.rc1' # Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'jbuilder', '~> 2.5' # Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'bootsnap'
gem 'rack-canonical-host' # Redirect www to root
gem 'webpacker', '~> 4.0'
gem "image_processing", "~> 1.2"

# Freeze until ElasticBeanstalk rebuild
gem 'puma', '3.12.0' # Use Puma as the app server
gem 'rack', '2.0.6'
gem 'rack-attack'

# Database/Data
gem 'pg', '1.0.0' # Use postgresql as the database for Active Record
gem 'after_party' # load data after deploy
gem 'upsert', '~> 2.2.1'
gem 'auto_strip_attributes', '~> 2.5'
gem 'closed_struct'

# Dashboard analytics
gem 'energy-sparks_analytics', git: 'https://github.com/PhilipTB/energy-sparks_analytics.git', tag: '0.47.1'
#gem 'energy-sparks_analytics', path: '../analytics-for-energy-sparks'

# Using master due to it having a patch which doesn't override Enumerable#sum if it's already defined
# Last proper release does that, causing all kinds of weird behaviour (+ not defined etc)
gem 'statsample', git: 'https://github.com/SciRuby/statsample', branch: 'master'

# Assets
gem 'jquery-rails' # Use jquery as the JavaScript library
gem 'sass-rails'# Use SCSS for stylesheets
gem 'uglifier' # Use Uglifier as compressor for JavaScript assets
gem 'bootstrap4-datetime-picker-rails' # For tempus dominus date picker
gem 'momentjs-rails'


gem 'aws-sdk-s3'

# Assets for Emails
gem 'bootstrap-email'

# Frontend
gem 'bootstrap', '~> 4.3.0' # Use bootstrap for responsive layout
gem 'chartkick' # Use chartkick for usage graphs
gem 'redcarpet' # Use redcarpet to convert markdown
gem 'font-awesome-sass', '~> 5.6.1' # For icons
gem 'simple_form'
# Highcharts now included directly

# For bulk record import in CSV etc
gem 'activerecord-import'

# JS Templating
gem 'handlebars_assets'
# Template variables
gem "mustache", "~> 1.0"

# User input
gem 'trix-rails', require: 'trix'

# Auth & Users
gem 'devise' # Use devise for authentication
gem 'cancancan', '~> 3.0.1' # Use cancancan for authorization

# Utils
gem 'groupdate', '4.0.1' # Use groupdate to group usage stats
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby] # Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'dotenv-rails' # Shim to load environment variables from .env into ENV in development.
# Run against master until full Rails6 release is complete
gem 'friendly_id', git: 'https://github.com/norman/friendly_id.git', branch: 'master' # Pretties up URLs
gem 'merit', git: 'https://github.com/merit-gem/merit.git', branch: 'master'
gem 'ruby-sun-times'

# For SMS notifications
gem 'twilio-ruby'

# Reduce log noise in dev and test
gem 'lograge'

# Exception handling
gem 'rollbar'
gem 'oj'

# Email service
gem 'mailgun_rails'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platform: :mri
  gem "bullet", require: false # use bullet to optimise queries
  gem 'rspec-rails', '~> 4.0.0.beta2'
  gem 'rails-controller-testing'
  gem "fakefs", require: "fakefs/safe"
  gem 'factory_bot_rails'
  gem 'climate_control'
  gem 'webmock'
  gem 'foreman'
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'web-console'
  gem 'listen', '~> 3.0.5'
  gem 'better_errors'
  gem "binding_of_caller"
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'spring-commands-rspec'
  gem 'annotate'
  gem 'pry'
  gem 'govuk-lint'
  gem 'overcommit'
  gem 'fasterer'
  gem 'bundler-audit'
end

group :test do
  gem 'test-prof'
  gem 'capybara'
  gem 'selenium-webdriver'
  gem 'database_cleaner'
  gem 'webdrivers'
  gem 'simplecov', :require => false, :group => :test
end

#Capistrano gems
group :development do
  gem 'capistrano',         require: false
  gem 'capistrano-rvm',     require: false
  gem 'capistrano-rails',   require: false
  gem 'capistrano-bundler', require: false
  gem 'capistrano3-puma',   require: false
end

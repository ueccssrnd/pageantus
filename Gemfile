source "https://rubygems.org"
ruby "2.0.0"

gem "activesupport", "~> 4.0.1"
gem "bourbon", "~> 3.1.8"
gem "coffee-script"
gem "data_mapper", "~> 1.2.0"
gem "font-awesome-rails", "~> 4.0.3.0"
gem "haml", "~> 4.0.4"
gem "json", "~> 1.8.0"
gem "prawn", "~> 0.12.0"
gem "sass", "~> 3.2.12"
gem "sinatra", "~> 1.4.4"
gem "sinatra-assetpack"
gem "sinatra-contrib", "~> 1.4.1"
gem "uglifier"
gem "yui-compressor", :require => "yui/compressor"

group :production do
  gem "dm-postgres-adapter"
end

group :development, :test do
  gem "dm-sqlite-adapter", "~> 1.2.0"
end

group :development do
  gem "pry"
end

group :test do
  gem "rspec"
end
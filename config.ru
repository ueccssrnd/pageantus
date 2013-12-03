require 'rubygems'
require './app'
require 'sass/plugin/rack'

Sass::Plugin.options[:style] = :compressed
use Sass::Plugin::Rack

map '/' do
  run Pageantus
end
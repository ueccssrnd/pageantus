pageantus
=========

##Pageant Management System

PHP Iteration Used: Mr. and Ms. UE 2012, Mr. and Ms. CCSS 2013

Ruby Iteration Used: Mr. and Ms. UE 2013

#### Usage

    $ git clone --depth 1 https://github.com/ueccssrnd/pageantus.git mypageant
    $ bundle install
    $ rake db:reseed
    $ rackup
    $ rerun 'rackup' for live reload

#### Stack

Back-end: Sinatra + DataMapper + PostgreSQL + Heroku

Utility: Prawn + RSpec

Front-end: Sinatra Asset Pack + CoffeeScript + Bourbon + Neat + Haml
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
    $ shotgun config.ru for live reload when testing.

#### Stack

Back-end: Sinatra + DataMapper + PostgreSQL + Heroku

Utility: Prawn + RSpec

Front-end: Sinatra Asset Pack + CoffeeScript + Bourbon + Neat + Haml

@todo
* http://martinfowler.com/articles/rake.html
* haml load each own stylesheet based on name
* remove all js in javascripts folder, just coffee
* minify indiv cs/js
* partials in haml
* Pageant setup tab
* background for login
* logo fix
* reports fixing and customization
* add testing
* check out methods with equal signs at the end
* modify front-end to deal with the change in API.
* generate pdf file no longer need to save!
* excel generation
* separate report.rb
* test_app.rb
* reports: Categories, Pageant Information, Memorandum of Agreement, Candidates, Rounds
* Scores

Workaround

* sinatra-assetpack + bourbon not playing nice with fonts. I separated the font file first.
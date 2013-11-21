pageantus
=========

##Pageant Management System

PHP Iteration Used: Mr. and Ms. UE 2012, Mr. and Ms. CCSS 2013

Ruby Iteration Used: Mr. and Ms. UE 2013

#### Usage


`git clone https://github.com/ueccssrnd/pageantus.git`

`cd` into the directory

`rackup` launches at port 9292

Shotgun: `shotgun config.ru` for live reload.


CCSS Testing: IP Address must be 172.16.2.101, Subnet Mask = 255.255.255.254, Router = 172.16.2.1

#### Toolzorz

Back-end: Sinatra+DataMapper+PostgreSQL+Heroku

Utility: Prawn+RSpec

Front-end: Sprockets+CoffeeScript+Bourbon+Neat+Haml

@todo
* http://martinfowler.com/articles/rake.html
* pry
* Pageant setup tab
* background for login
* sprocket asset pipeline
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
* connect to fb:?
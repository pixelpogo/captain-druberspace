# Captain-Druberspace

This Gem provides a bunch of [Capistrano Tasks](https://github.com/capistrano/capistrano/wiki/Capistrano-Tasks) to deploy [Drupal](http://www.drupal.org) projects to the German hosting service [Uberspace](http://www.uberspace.de).

## Installation

Add this line to your application's Gemfile:

    gem 'captain-druberspace', :git => 'git@github.com:pixelpogo/captain-druberspace.git'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install captain-druberspace

## Preparation

### Capify

Run the following commands in the command line from the Drupal project’s root directory

    capify .
    rm -Rf config/deploy.rb; mkdir -p config/deploy
    touch config/deploy/staging.rb config/deploy/production.rb


### Capfile

This an example how your Capfile could (or should) look like

    load 'deploy'

    # ! IMPORTANT !
    # :application has to be defined before
    # requiring 'captain-druberspace/deploy'
    set :application, "ilfuturo"

    require 'rubygems'
    require 'captain-druberspace/deploy'

    server "norma.uberspace.de", :web, :db

    set :user, "ubernaut"

    set :domain, "example.com"
    set(:deploy_to) { "/var/www/virtual/#{user}/#{domain}-sourcecode" }
    set(:drush) { "/home/#{user}/drush/drush" }

    set :alias_domains, ["example.norma.uberspace.de"]

    set :repository, "git@github.com:youraccount/yourdrupalproject.git"
    set :scm       , :git
    set :branch    , "master"

    set :deploy_via, :remote_cache
    set :use_sudo  , false

    # only keep n backups (default is 10)
    set :keep_backups, 6

### Drush

Captain-Druberspace relies on the Drupal Shell (Drush), see <http://www.drush.ws>.

So please ensure, that you have drush installed on your Uberspace account.

Check this gist for installation instructions: <https://gist.github.com/pixelpogo/5229541>


## Usage

### Sites and settings

Create a sites directory for your production/staging environment.

    mkdir sites/production

Place and configure a settings.php file into your `sites/production directory`.

Uberspace provides MySQL database credentials for your accoubt in `~/.my.cnf`. Captain-Druberspace will read these and inject them into your `settings.php` if you follow the convention, which means, that you have to use certain placeholders:

    $databases = array (
      'default' =>
      array (
        'default' =>
        array (
          'database' => 'UBERSPACE_DATABASE',
          'username' => 'UBERSPACE_USERNAME',
          'password' => 'UBERSPACE_PASSWORD',
          'host' => 'localhost',
          'port' => '',
          'driver' => 'mysql',
          'prefix' => '',
        ),
      ),
    );

The most important benefit is, of course, that you don't have to put your credentials under version control...

### Recommend .gitignore settings

    # Ignore configuration files that may contain sensitive information.
    sites/*/settings*.php
    !sites/production/settings.php
    !sites/staging/settings.php

    # Ignore paths that contain user-generated content.
    sites/*/files
    sites/*/private



### Deployment

Inside your Drupal project's root directory

    cap production deploy:setup

### Convenience Tasks

Clear all drupal caches

    cap production drupal:clear_cache

Turn maintenance mode on/off

    cap production drupal:maintenance:on
    cap production drupal:maintenance:off


## Alternatives and inspiration

Libraries similar to this in some form or another include:

* <https://github.com/leehambley/railsless-deploy/>
* <https://github.com/augustash/capistrano-ash>
* <https://github.com/previousnext/capistrano-drupal>
* <https://gist.github.com/noxoc/1443355>



## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

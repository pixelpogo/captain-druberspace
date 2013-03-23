# Capistrano2 differentiator
load 'deploy' if respond_to?(:namespace)
# Dir['vendor/plugins/*/recipes/*.rb'].each { |plugin| load(plugin) }

# Required gems/libraries
require 'rubygems'
require 'capistrano/ext/multistage'
require 'railsless-deploy'

configuration = Capistrano::Configuration.respond_to?(:instance) ?
  Capistrano::Configuration.instance(:must_exist) :
  Capistrano.configuration(:must_exist)

configuration.load do

  before 'deploy:cleanup',        'drupal:prepare_cleanup'

  after 'deploy:setup',           'drupal:setup'
  after 'deploy:finalize_update', 'drupal:settings',
                                  'drupal:clear_cache',
                                  'druberspace:cleanup',
                                  'drupal:symlink',
                                  'deploy:cleanup'


  set :drush, "drush"

  namespace :drupal do
    # create shared files-directory
    desc "Setup Drupal's files directory and remove useless Capistrano default directories"
    task :setup do
       run "mkdir -p #{shared_path}/files"

       # remove Capistrano specific directories
       run "rm -Rf #{shared_path}/log"
       run "rm -Rf #{shared_path}/pids"
       run "rm -Rf #{shared_path}/system"

    end

    desc ""
    task :settings do

      # rename generic environment/stage directory to #{domain} name
      run "mv #{latest_release}/sites/#{stage} #{latest_release}/sites/#{domain}"

      # Add Uberspace-MySQL credentials
      run "sed -ie 's/UBERSPACE_USERNAME/#{user}/' #{latest_release}/sites/#{domain}/settings.php"
      run "sed -ie 's/UBERSPACE_DATABASE/#{user}/' #{latest_release}/sites/#{domain}/settings.php"
      run "export mysqlpw=$(grep password ~/.my.cnf | sed 's/.*password=\\(\\S*\\).*/\\1/g'); sed -ie \"s/UBERSPACE_PASSWORD/$mysqlpw/\" #{latest_release}/sites/#{domain}/settings.php"

      # write protect settings.php
      run "chmod 644 #{latest_release}/sites/#{domain}/settings.php"
    end

    # symlink shared directories
    desc "Symlink shared directories (sites/example.com/files"
    task :symlink do

      # Symlink Drupal's files directory
      run "ln -s #{shared_path}/files #{latest_release}/sites/#{domain}/files"
      run "cd #{latest_release} && #{drush} -l #{domain} -r #{latest_release} vset --yes file_directory_path sites/#{domain}/files"
      run "cd #{latest_release} && #{drush} -l #{domain} -r #{latest_release} vset --yes file_public_path sites/#{domain}/files"
      run "cd #{latest_release} && #{drush} -l #{domain} -r #{latest_release} vset --yes file_private_path sites/#{domain}/files/private"

      # Symlink current to #{domain} to fullfil Uberspace/Apache DocumentRoot requirements
      run "rm -f /var/www/virtual/#{user}/#{domain}"
      run "ln -s #{File.join(deploy_to, "current")} /var/www/virtual/#{user}/#{domain}"

    end

    desc "Clear all drupal caches"
    task :clear_cache do
      run "cd #{latest_release} && #{drush} -l #{domain} -r #{latest_release} cc all"
    end


    namespace :maintenance do
      desc "Turn on maintenance mode - show a message screen"
      task :on, :roles => :web do
        run "#{drush} -l #{domain} -r #{latest_release} vset --yes site_offline 1"
      end

      desc "Turn off maintenance mode - remove message screen"
      task :off, :roles => :web do
        run "#{drush} -l #{domain} -r #{latest_release}  vdel --yes site_offline"
      end
    end


    desc <<-DESC
      Clean up old releases. By default, the last 5 releases are kept on each \
      server (though you can change this with the keep_releases variable). All \
      other deployed revisions are removed from the servers. By default, this \
      will use sudo to clean up the old releases, but if sudo is not available \
      for your environment, set the :use_sudo variable to false instead.
    DESC
    task :prepare_cleanup, :except => { :no_release => true } do
      count = fetch(:keep_releases, 5).to_i
      local_releases = capture("ls -xt #{releases_path}").split.reverse
      if count >= local_releases.length
        logger.important "no old releases to prepare for clean up"
      else
        logger.info "keeping #{count} of #{local_releases.length} deployed releases unchanged"
        (local_releases - local_releases.last(count)).each do |release|
          sites_path = File.join(releases_path, release, 'sites', domain)

          # change file permissions of the sites path, which is the parent directory
          # of the #{domain}-directory to make the contained settings.php deletable
          run "chmod -R 770 #{sites_path}"

          # remove 'files' symlink
          run "rm -f #{File.join(sites_path,'files')}"
        end

      end
    end

  end

  namespace :druberspace do

    desc "Remove all obsolete capistrano related files from DocumentRoot"
    task :cleanup do
      run  "rm -f #{latest_release}/Capfile"
      run  "rm -rf #{latest_release}/config"

      all_sites = capture("cd #{latest_release}/sites/ && ls -dx */").split
      obsolete_sites = all_sites.delete_if{ |site| ["all", domain].include?(site.gsub("/","")) }
      run "rm -fr #{obsolete_sites.map!{ |site| File.join(latest_release, "sites", site)}.join(" ")}"
      run "ln -s #{File.join(latest_release, 'sites', domain)} #{File.join(latest_release, 'sites', 'default')}"
    end

    desc "create directories for domains that should redirect to main domain"

    task :redirect_alias_domains do
      alias_domains.each do |alias_domain|
        doc_root = "/var/www/virtual/#{user}/#{alias_domain}"
        run "mkdir -p #{doc_root}"
        php = <<-PHP
        <?php
          header ('HTTP/1.1 301 Moved Permanently');
          header ('Location: http://#{domain}/');
          exit();
        ?>
        PHP
        run "echo \"#{php}\" | cat > #{doc_root}/index.php"
      end
    end

  end

end
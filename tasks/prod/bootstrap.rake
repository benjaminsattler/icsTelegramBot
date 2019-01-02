# frozen_string_literal: true

namespace :prod do
  desc 'Bootstrap a new production environment'
  task :bootstrap do
    config_destination = "#{PWD}/k8s/configs/production.env"
    secrets_destination = "#{PWD}/k8s/secrets/prod.secrets"
    token_destination = "#{PWD}/k8s/secrets/prod.token"
    puts 'Generating production configuration file...'
    FileUtils.copy_file(
      "#{PWD}/k8s/configs/production.env.example",
      config_destination
    )
    puts 'Generating production secrets file...'
    FileUtils.copy_file(
      "#{PWD}/k8s/secrets/prod.secrets.example",
      secrets_destination
    )
    puts 'Generating production token file...'
    FileUtils.copy_file(
      "#{PWD}/k8s/secrets/prod.token.example",
      token_destination
    )
    puts "Please adapt #{config_destination} to your environment. "
    puts "Please also update #{secrets_destination} with the database "
    puts 'credentials for production. Lastly, please insert the telegram '
    puts "bot token in #{token_destination}."
    puts
    puts 'See the comments in the file for more information. '
    puts 'Afterwards, setup your production environment on your '
    puts 'production kubernetes cluster with these commands: '
    puts
    puts 'To upload your bot configuration: '
    puts 'rake prod:update_bot_config'
    puts
    puts 'To upload your bot token: '
    puts 'rake prod:update_bot_token'
    puts
    puts 'To upload your bot secrets file: '
    puts 'rake prod:update_bot_secrets'
    puts
    puts 'To generate the kubernetes volumes on production: '
    puts 'rake prod:create_volumes'
    puts
    puts 'Finally, to start your production cluster: '
    puts 'rake prod:start'
  end
end

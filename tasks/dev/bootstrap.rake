# frozen_string_literal: true

namespace :dev do
  desc 'Bootstrap a new development environment'
  task bootstrap: %w[git:install_hooks k8s:generate_deployment] do
    config_destination = "#{PWD}/k8s/configs/development.env"
    puts 'Generating development configuration file...'
    FileUtils.copy_file(
      "#{PWD}/k8s/configs/development.env.example",
      config_destination
    )
    puts "Please adapt #{config_destination} to your environment. "
    puts 'Most values should be fine, but some require changing. '
    puts 'See the comments in the file for more information. '
    puts 'Afterwards, deploy your dev environment on your local '
    puts 'kubernetes cluster with these commands: '
    puts
    puts 'rake dev:update_bot_config && rake dev:start'
  end
end

# frozen_string_literal: true

namespace :dev do
  desc 'Bootstrap a new development environment'
  task bootstrap: %w[
    git:install_hooks
    container:build_dev
    container:build_testing
    container:build_linting
  ] do
    config_destination = "#{PWD}/docker/configs/development.env"
    puts 'Generating development configuration file...'
    FileUtils.copy_file(
      "#{PWD}/docker/configs/development.env.example",
      config_destination
    )
    puts "Please adapt #{config_destination} to your environment. "
    puts 'Most values should be fine, but some require changing. '
    puts 'See the comments in the file for more information. '
    puts 'Afterwards, deploy your dev environment with this command: '
    puts
    puts 'rake dev:start'
  end
end

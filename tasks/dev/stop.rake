# frozen_string_literal: true

namespace :dev do
  desc 'Stop development environment'
  task :stop do
    sh(
      'docker-compose '\
      "-f #{PWD}/docker-compose.yml "\
      'down '
    )
  end
end

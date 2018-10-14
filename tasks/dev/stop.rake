# frozen_string_literal: true

namespace :dev do
  desc 'Stop development environment'
  task :stop do
    sh(
      'docker-compose '\
      "-f #{PWD}/docker-compose.dev.yml "\
      'down'
    )
  end
end

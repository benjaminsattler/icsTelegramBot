# frozen_string_literal: true

namespace :dev do
  desc 'Start development environment'
  task :start do
    sh(
      'docker-compose '\
      "-f #{PWD}/docker-compose.yml "\
      'up '\
      '-d '
    )
  end
end

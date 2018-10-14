# frozen_string_literal: true

namespace :prod do
  desc 'Stop production environment'
  task :stop do
    sh(
      'docker-compose '\
      "-f #{PWD}/docker-compose.prod.yml "\
      'down'
    )
  end
end

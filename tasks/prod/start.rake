# frozen_string_literal: true

namespace :prod do
  desc 'Start production environment'
  task :start do
    sh(
      'docker-compose '\
      "-f #{PWD}/docker-compose.prod.yml "\
      'up --build '\
      '-d'
    )
  end
end

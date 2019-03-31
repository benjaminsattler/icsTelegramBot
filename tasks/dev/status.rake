# frozen_string_literal: true

namespace :dev do
  desc 'Status of development environment'
  task :status do
    sh(
      'docker-compose '\
      'ps'
    )
  end
end

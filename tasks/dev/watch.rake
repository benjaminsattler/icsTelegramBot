# frozen_string_literal: true

namespace :dev do
  desc 'Watch development logs'
  task :watch do
    sh(
      'docker-compose '\
      'logs -f '
    )
  end
end

# frozen_string_literal: true

namespace :hyper do
  desc 'Create and start docker containers on production system'
  task :up do
    sh(
      'hyper compose up '\
      "--project-name=#{HYPER_SH_PROJECTNAME} "\
      "-f #{HYPER_SH_DOCKERFILE} "\
      '-d'
    )
  end
end

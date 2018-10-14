# frozen_string_literal: true

namespace :hyper do
  desc 'Create docker containers on production system'
  task :create do
    sh(
      'hyper compose create '\
      '--force-recreate '\
      "--project-name=#{HYPER_SH_PROJECTNAME} "\
      "-f #{HYPER_SH_DOCKERFILE}"
    )
  end
end

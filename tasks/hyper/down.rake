# frozen_string_literal: true

namespace :hyper do
  desc 'Stop and remove docker containers, '\
  'volumes and images on production system'
  task :down do
    sh(
      'hyper compose down '\
      '--rmi=all '\
      "--project-name=#{HYPER_SH_PROJECTNAME}"
    )
  end
end
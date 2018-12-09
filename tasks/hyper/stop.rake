# frozen_string_literal: true

namespace :hyper do
  desc 'Stop docker containers on prodution system'
  task :stop do
    sh(
      'hyper '\
      "--region=#{HYPER_SH_REGION} "\
      ' compose stop '\
      "--project-name=#{HYPER_SH_PROJECTNAME}"
    )
  end
end

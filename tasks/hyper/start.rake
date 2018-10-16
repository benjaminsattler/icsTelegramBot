# frozen_string_literal: true

namespace :hyper do
  desc 'Start docker containers on prodution system'
  task :start do
    sh(
      'hyper compose start '\
      "--project-name=#{HYPER_SH_PROJECTNAME}"
    )
  end
end
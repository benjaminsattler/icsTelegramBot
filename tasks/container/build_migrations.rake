# frozen_string_literal: true

namespace :container do
  desc 'Build docker migrations image'
  task :build_migrations do
    sh(
      'docker build '\
      '-t muell_dbmate '\
      '--rm '\
      '-f docker/Dockerfile '\
      '--target base '\
      "#{PWD}"
    )
  end
end

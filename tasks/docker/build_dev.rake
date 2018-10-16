# frozen_string_literal: true

namespace :docker do
  desc 'Build docker development image'
  task :build_dev do
    sh(
      'docker build '\
      '-t muell_dev '\
      '--rm '\
      '-f docker/Dockerfile '\
      '--target development '\
      "#{PWD}"
    )
  end
end

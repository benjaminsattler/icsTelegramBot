# frozen_string_literal: true

namespace :docker do
  desc 'Build docker tests image'
  task :build_testing do
    sh(
      'docker build '\
      '-t muell_rspec '\
      '--rm '\
      '-f docker/Dockerfile '\
      '--target testing '\
      "#{PWD}"
    )
  end
end

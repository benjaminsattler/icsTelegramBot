# frozen_string_literal: true

namespace :docker do
  desc 'Build docker linter image'
  task :build_linting do
    sh(
      'docker build '\
      '-t muell_rubocop '\
      '--rm '\
      '-f docker/Dockerfile '\
      '--target linting '\
      "#{PWD}"
    )
  end
end

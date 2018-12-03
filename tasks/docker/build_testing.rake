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
      "--build-arg GIT_TAG=\"#{GIT_TAG}\" "\
      "--build-arg GIT_REPO=\"#{GIT_REPO}\" "\
      "--build-arg BUILD_USER=\"#{BUILD_USER_INFO}\" "\
      "--build-arg BUILD_TIME=\"#{CURRENT_TIME}\" "\
      "#{PWD}"
    )
  end
end

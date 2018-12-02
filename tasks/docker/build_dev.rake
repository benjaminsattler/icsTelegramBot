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
      "--build-arg GIT_TAG=\"#{GIT_TAG}\" "\
      "--build-arg GIT_REPO=\"#{GIT_REPO}\" "\
      "--build-arg BUILD_USER=\"#{BUILD_USER_INFO}\" "\
      "--build-arg BUILD_TIME=\"#{CURRENT_TIME}\" "\
      "#{PWD}"
    )
  end
end

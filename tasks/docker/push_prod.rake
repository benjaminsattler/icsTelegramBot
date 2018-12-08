# frozen_string_literal: true

namespace :docker do
  desc 'Push a new docker production image'
  task :push_prod do
    sh(
      "docker tag muell #{DOCKER_IMAGE_TAG}:#{GIT_TAG} && "\
      "docker push #{DOCKER_IMAGE_TAG}:#{GIT_TAG} && "\
      "docker tag muell #{DOCKER_IMAGE_TAG}:latest && "\
      "docker push #{DOCKER_IMAGE_TAG}:latest"
    )
  end
end

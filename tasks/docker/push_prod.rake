# frozen_string_literal: true

namespace :docker do
  desc 'Push a new production image to the docker registry'
  task :push_prod do
    sh(
      'docker login && '\
      "docker tag muell #{DOCKER_IMAGE_TAG}:#{GIT_TAG} && "\
      "docker push #{DOCKER_IMAGE_TAG}:#{GIT_TAG} && "\
      "docker tag muell #{DOCKER_IMAGE_TAG}:latest && "\
      "docker push #{DOCKER_IMAGE_TAG}:latest"
    )
  end
end

# frozen_string_literal: true

namespace :docker do
  desc 'Push a new docker production image'
  task :push_prod do
    sh(
      'docker login && '\
      "docker tag muell #{DOCKER_IMAGE_TAG} && "\
      "docker push #{DOCKER_IMAGE_TAG}"
    )
  end
end

# frozen_string_literal: true

namespace :gce do
  desc 'Push a new production image to the google cloud registry'
  task :push_prod do
    sh(
      'docker login && '\
      "docker tag muell #{GCE_REPOSITORY_HOST}/#{GCE_IMAGE_TAG}:#{GIT_TAG} && "\
      "docker push #{GCE_REPOSITORY_HOST}/#{GCE_IMAGE_TAG}:#{GIT_TAG} && "\
      "docker tag muell #{GCE_REPOSITORY_HOST}/#{GCE_IMAGE_TAG}:latest && "\
      "docker push #{GCE_REPOSITORY_HOST}/#{GCE_IMAGE_TAG}:latest"
    )
  end
end

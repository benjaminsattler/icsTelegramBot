# frozen_string_literal: true

namespace :gce do
  desc 'Push a new production image to the google cloud registry'
  task :push_prod do
    # rubocop:disable Metrics/LineLength
    sh(
      "docker login -u _json_key --password-stdin https://eu.gcr.io < #{GCE_DOCKER_LOGIN} && "\
      "docker tag muell #{GCE_REGISTRY_HOST}/#{GCE_IMAGE_TAG}:#{GIT_TAG} && "\
      "docker push #{GCE_REGISTRY_HOST}/#{GCE_IMAGE_TAG}:#{GIT_TAG} && "\
      "docker tag muell #{GCE_REGISTRY_HOST}/#{GCE_IMAGE_TAG}:latest && "\
      "docker push #{GCE_REGISTRY_HOST}/#{GCE_IMAGE_TAG}:latest"
    )
    # rubocop:enable Metrics/LineLength
  end
end

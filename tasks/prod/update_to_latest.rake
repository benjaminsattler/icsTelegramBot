# frozen_string_literal: true

namespace :prod do
  desc 'Update bot deployment to latest version'
  task :update_to_latest do
    image_url = format(
      '%s/%s:latest',
      GCE_REGISTRY_HOST,
      GCE_IMAGE_TAG
    )
    sh(
      'kubectl '\
      "--context=#{K8S_PROD_CONTEXT_NAME} "\
      "set image deployment/#{K8S_PROD_DEPLOYMENT_NAME} "\
      "#{K8S_PROD_DEPLOYMENT_CONTAINER_NAME}=#{image_url}"
    )
    sh(
      'kubectl '\
      "--context=#{K8S_PROD_CONTEXT_NAME} "\
      'rollout status '\
      "deployments/#{K8S_PROD_DEPLOYMENT_NAME}"
    )
  end
end

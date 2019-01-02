# frozen_string_literal: true

namespace :prod do
  desc 'Status of production environment'
  task :status do
    sh(
      'kubectl '\
      "--context=#{K8S_PROD_CONTEXT_NAME} "\
      'get all'
    )
  end
end

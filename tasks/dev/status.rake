# frozen_string_literal: true

namespace :dev do
  desc 'Status of development environment'
  task :status do
    sh(
      'kubectl '\
      "--context=#{K8S_DEV_CONTEXT_NAME} "\
      'get all'
    )
  end
end

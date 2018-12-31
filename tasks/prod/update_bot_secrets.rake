# frozen_string_literal: true

namespace :prod do
  desc 'Update database access credentials'
  task :update_bot_credentials do
    input_file = ENV['SECRETS_FILE']
    if input_file.nil?
      puts 'USAGE: SECRETS_FILE=<path to secrets file> '\
            'rake prod:update_bot_credentials'
      puts
      puts 'Unless a SECRETS_FILE is provided, the default '\
            'k8s/secrets/prod.secrets is used.'
      puts
      input_file = 'k8s/secrets/prod.secrets'
    end
    puts "Using #{input_file}"
    sh(
      'kubectl '\
      "--context=#{K8S_PROD_CONTEXT_NAME} "\
      'create secret generic databasecredentials '\
      "--from-env-file=#{input_file} "\
      '--dry-run '\
      '-o yaml ' \
      '| '\
      'kubectl '\
      "--context=#{K8S_PROD_CONTEXT_NAME} "\
      'apply '\
      '-f -'
    )
  end
end

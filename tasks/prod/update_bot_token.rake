# frozen_string_literal: true

namespace :prod do
  desc 'Update telegram bot token'
  task :update_bot_token do
    input_file = ENV['TOKEN_FILE']
    if input_file.nil?
      puts 'USAGE: TOKEN_FILE=<path to token file> '\
            'rake prod:update_bot_token'
      puts
      puts 'Unless a TOKEN_FILE is provided, the default '\
            'k8s/secrets/prod.token is used.'
      puts
      input_file = 'k8s/secrets/prod.token'
    end
    puts "Using #{input_file}"
    sh(
      'kubectl '\
      "--context=#{K8S_PROD_CONTEXT_NAME} "\
      'create secret generic bottoken '\
      "--from-file=prod.token=#{input_file} "\
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

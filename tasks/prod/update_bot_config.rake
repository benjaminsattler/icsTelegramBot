# frozen_string_literal: true

namespace :prod do
  desc 'Update bot configuration'
  task :update_bot_config do
    input_file = ENV['CONFIG_FILE']
    if input_file.nil?
      puts 'USAGE: CONFIG_FILE=<path to config file> '\
            'rake prod:update_bot_config'
      puts
      puts 'Unless a CONFIG_FILE is provided, the default '\
            'k8s/configs/production.env is used.'
      puts
      input_file = 'k8s/configs/production.env'
    end
    puts "Using #{input_file}"
    sh(
      'kubectl '\
      "--context=#{K8S_PROD_CONTEXT_NAME} "\
      'create configmap production-config '\
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

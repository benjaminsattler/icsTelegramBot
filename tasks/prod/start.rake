# frozen_string_literal: true

namespace :prod do
  desc 'Start production environment'
  task :start do
    input_file = ENV['YAML_FILE']
    if input_file.nil?
      puts 'USAGE: YAML_FILE=<path to yaml file> '\
            'rake prod:start'
      puts
      puts 'Unless a YAML_FILE is provided, the default '\
            'k8s/production.yaml is used.'
      puts
      input_file = 'k8s/production.yaml'
    end
    puts "Using #{input_file}"
    sh(
      'kubectl '\
      "--context=#{K8S_PROD_CONTEXT_NAME} "\
      'apply '\
      "-f #{input_file}"
    )
  end
end

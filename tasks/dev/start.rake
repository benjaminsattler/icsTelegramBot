# frozen_string_literal: true

namespace :dev do
  desc 'Start development environment'
  task :start do
    input_file = ENV['YAML_FILE']
    if input_file.nil?
      puts 'USAGE: YAML_FILE=<path to yaml file> '\
            'rake dev:start'
      puts
      puts 'Unless a YAML_FILE is provided, the default '\
            'k8s/development.yaml is used.'
      input_file = 'k8s/development.yaml'
    end
    puts "Using YAML_FILE=#{input_file}"
    sh(
      'kubectl '\
      "--context=#{K8S_DEV_CONTEXT_NAME} "\
      'apply '\
      "-f #{input_file} "
    )
  end
end

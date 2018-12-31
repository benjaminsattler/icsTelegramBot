# frozen_string_literal: true

namespace :dev do
  desc 'Stop development environment'
  task :stop do
    input_file = ENV['YAML_FILE']
    if input_file.nil?
      puts 'USAGE: YAML_FILE=<path to yaml file> '\
            'rake dev:stop'
      puts
      puts 'Unless a YAML_FILE is provided, the default '\
            'k8s/development.yaml is used.'
      puts
      input_file = 'k8s/development.yaml'
    end
    puts "Using #{input_file}"
    sh(
      'kubectl '\
      "--context=#{K8S_DEV_CONTEXT_NAME} "\
      'delete '\
      "-f #{input_file}"
    )
  end
end

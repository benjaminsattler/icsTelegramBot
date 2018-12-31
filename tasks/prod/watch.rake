# frozen_string_literal: true

namespace :prod do
  desc 'Watch production logs'
  task :watch do
    podname = `kubectl \
      --context=#{K8S_PROD_CONTEXT_NAME} \
      get pods \
      -o go-template \
      --template "{{range .items}}{{.metadata.name}}
{{end}}"`
    if podname.nil?
      puts 'No running pod found. Exiting...'
      exit
    end
    puts "Found pod #{podname}"
    sh(
      'kubectl '\
      "--context=#{K8S_PROD_CONTEXT_NAME} "\
      'logs -f '\
      "#{podname}"
    )
  end
end

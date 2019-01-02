# frozen_string_literal: true

namespace :dev do
  desc 'Watch development logs'
  task :watch do
    podname = `kubectl \
      --context=#{K8S_DEV_CONTEXT_NAME} \
      get pods \
      -o go-template \
      --template "{{range .items}}{{.metadata.name}}
{{end}}" | grep -e "^devel" --color=never`.chomp
    if podname.empty?
      puts 'No running pod found. Exiting...'
      exit
    end
    puts "Found pod #{podname}"
    sh(
      'kubectl '\
      "--context=#{K8S_DEV_CONTEXT_NAME} "\
      'logs -f '\
      "#{podname}"
    )
  end
end

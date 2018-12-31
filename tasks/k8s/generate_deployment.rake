# frozen_string_literal: true

namespace :k8s do
  desc 'Preprocesses the development deployment'
  task :generate_deployment do
    puts 'Generating kubernetes development configuration...'
    infile = "#{PWD}/k8s/development.tpl.yaml"
    outfile = "#{PWD}/k8s/development.yaml"
    template = File.read(infile)
    template.gsub!('{{ PROJECT_BASEPATH }}', PWD)
    File.write(outfile, template)
  end
end

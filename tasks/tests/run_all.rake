# frozen_string_literal: true

namespace :tests do
  desc 'Run all tests'
  task :run_all do
    sh("docker run --rm -v #{PWD}:/app muell_rspec #{ENV['SPEC']}")
  end
end

# frozen_string_literal: true

namespace :checks do
  desc 'Run all analyses and checks'
  task :run_all do
    sh("docker run --rm --volume #{PWD}:/app muell_rubocop")
  end
end

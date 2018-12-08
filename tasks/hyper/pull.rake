# frozen_string_literal: true

namespace :hyper do
  desc 'Pull new docker images from the repository'
  task :pull do
    sh(
      'hyper '\
      "--region=#{HYPER_SH_REGION} "\
      'compose pull '\
      "-f #{HYPER_SH_DOCKERFILE}"
    )
  end
end

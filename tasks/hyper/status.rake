# frozen_string_literal: true

namespace :hyper do
  desc 'Display some information about hyper'
  task :status do
    sh(
      'hyper '\
      "--region=#{HYPER_SH_REGION} "\
      'ps'
    )
    sh(
      'hyper '\
      "--region=#{HYPER_SH_REGION} "\
      'volume ls '
    )
    sh(
      'hyper '\
      "--region=#{HYPER_SH_REGION} "\
      'fip ls'
    )
    sh(
      'hyper '\
      "--region=#{HYPER_SH_REGION} "\
      'info'
    )
  end
end

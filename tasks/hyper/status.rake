# frozen_string_literal: true

namespace :hyper do
  desc 'Display some information about hyper'
  task :status do
    sh(
      'hyper ps && hyper volume ls && hyper fip ls && hyper info'
    )
  end
end

# frozen_string_literal: true

namespace :hyper do
  desc 'Pull new docker images and restart containers'
  task update: %i[
    pull
    up
  ]
end

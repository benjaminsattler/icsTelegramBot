# frozen_string_literal: true

namespace :docker do
  desc 'Build and push a new docker production image'
  task build_push_prod: %i[build_prod push_prod]
end

# frozen_string_literal: true

namespace :dev do
  desc 'Restart development environment'
  task restart: %i[stop start]
end

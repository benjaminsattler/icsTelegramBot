# frozen_string_literal: true

namespace :prod do
  desc 'Restart production environment'
  task restart: %i[stop start]
end

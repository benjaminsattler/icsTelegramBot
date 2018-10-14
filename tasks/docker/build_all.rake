# frozen_string_literal: true

namespace :docker do
  desc 'Build all docker images'
  task build_all: %i[
    build_prod
    build_dev
    build_tests
    build_lint
    build_migrations
  ]
end

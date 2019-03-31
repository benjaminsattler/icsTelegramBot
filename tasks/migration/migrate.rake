# frozen_string_literal: true

namespace :migration do
  desc 'Migrate to latest version'
  task :migrate do
    sh(
      'docker run --rm '\
      "-v #{PWD}/db/:/db "\
      '--network=muell_backend '\
      "--env-file #{MIGRATION_ENV_FILE} "\
      'muell_dbmate '\
      '--no-dump-schema '\
      "--migrations-dir #{DOCKER_MIGRATIONS_PATH} "\
      'migrate'
    )
  end
end

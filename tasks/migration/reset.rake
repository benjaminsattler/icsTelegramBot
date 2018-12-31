# frozen_string_literal: true

namespace :migration do
  desc 'Reset database and migrate to latest version'
  task :reset do
    sh(
      'docker run --rm '\
      "-v #{PWD}/db/:/db "\
      '--network=host '\
      "--env-file #{MIGRATION_ENV_FILE} "\
      'muell_dbmate '\
      '--no-dump-schema '\
      "--migrations-dir #{DOCKER_MIGRATIONS_PATH} "\
      'drop'
    )
    sh(
      'docker run --rm '\
      "-v #{PWD}/db/:/db "\
      '--network=muell_backend '\
      "--env-file #{MIGRATION_ENV_FILE} "\
      'muell_dbmate '\
      '--no-dump-schema '\
      "--migrations-dir #{DOCKER_MIGRATIONS_PATH} "\
      'up'
    )
  end
end

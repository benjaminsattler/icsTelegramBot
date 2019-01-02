# frozen_string_literal: true

namespace :migration do
  desc 'Rollback the to latest migration'
  task :rollback do
    sh(
      'docker run --rm '\
      "-v #{PWD}/db/:/db "\
      '--network=host '\
      "--env-file #{MIGRATION_ENV_FILE} "\
      'muell_dbmate '\
      '--no-dump-schema '\
      "--migrations-dir #{DOCKER_MIGRATIONS_PATH} "\
      'rollback'
    )
  end
end

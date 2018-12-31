# frozen_string_literal: true

namespace :migration do
  desc 'Generate a new migration'
  task :new do
    name = ENV['NAME']
    if name.nil?
      puts 'Usage: NAME=<migration name> rake migration:new'
      exit
    end
    sh(
      'docker run --rm '\
      "-v #{PWD}/db/:/db "\
      '--network=host '\
      "--env-file #{MIGRATION_ENV_FILE} "\
      'muell_dbmate '\
      "--migrations-dir #{DOCKER_MIGRATIONS_PATH} "\
      '--no-dump-schema '\
      "new #{name}"\
    )
  end
end

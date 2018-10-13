# frozen_string_literal: true

require 'rake'

# directory of this Rakefile
PWD = File.dirname(__FILE__).freeze

# target directory for the git hooks
# that are installed by the task `rake git:install_hooks`
GITHOOKS_TGTDIR = "#{PWD}/.git/hooks/"

# below path needs to be relative to GITHOOKS_TRGTDIR
# because git is going to resolve relative filenames
# while it is cd'ed in the .git/hooks dir!
GITHOOKS_SRCDIR = '../../scripts/githooks'

# name of the currently checkout out git branch
# will be used in a docker image label when building
# a new docker image
GIT_ACTIVE_BRANCH = `git rev-parse --abbrev-ref HEAD`.chomp.freeze

# git tag of the current git branch HEAD
# will be used in a docker image label when building
# a new docker image
GIT_TAG = `git describe --tags`.chomp.freeze

# URL of the remote for this repository
# will be used in a docker image label when building
# a new docker image
GIT_REPO = `git remote get-url origin`.chomp.freeze

# current git user name for this repository
# will be used in a docker image label when building
# a new docker image
GIT_USER_NAME = `git config user.name `.chomp.freeze

# current user email for this repository
# will be used in a docker image label when building
# a new docker image
GIT_USER_EMAIL = `git config user.email`.chomp.freeze

# username of the local user
# will be used in a docker image label when building
# a new docker image
LOCAL_USER_NAME = `whoami`.chomp.freeze

# hostname of this machine
# will be used in a docker image label when building
# a new docker image
LOCAL_HOST_NAME = `hostname`.chomp.freeze

# information about the current user (YOU!)
# will be used in a docker image label when building
# a new docker image
BUILD_USER_INFO = \
  "#{GIT_USER_NAME} <#{GIT_USER_EMAIL}> "\
  "(#{LOCAL_USER_NAME}@#{LOCAL_HOST_NAME})"

# current system time. Will be used in a docker image
# label when building a new docker image
CURRENT_TIME = `date +"%d%m%Y-%H%M%S"`.chomp.freeze

# Path to the hyper.sh docker compose file.
# This file is similar to a conventional docker compose
# file, but has a few caveats and extras. For more information
# visit https://hyper.sh/
HYPER_SH_DOCKERFILE = "#{PWD}/docker-compose.hyper.yml"

# Full docker tag that shall be used to tag docker images
# when pushing the production docker image to the repository
# with the task `docker:push_prod`
DOCKER_IMAGE_TAG = 'benjaminsattler/icstelegrambot'

# Environemnt variables file that shall be used for docker run
# when developing database migrations locally. Usually you want
# this to be your development environment to be able to test,
# migrate and rollback your migrations during development
MIGRATION_ENV_FILE = './docker/development.env'

# Location of the database migration files from inside the
# dbmate docker container. Usually you'll want this to equal
# the environment variable "MIGRATIONS_DIR" in the environment
# file specified by MIGRATION_ENV_FILE above
DOCKER_MIGRATIONS_PATH = '/db/migrations/mysql/'

# What to name the project inside hyper.sh.
# For more information regarding projects please
# refer to https://hyper.sh
HYPER_SH_PROJECTNAME = 'icstelegrambot'

namespace :docker do
  desc 'Push a new docker production image'
  task :push_prod do
    sh(
      'docker login && '\
      "docker tag muell #{DOCKER_IMAGE_TAG} && "\
      "docker push #{DOCKER_IMAGE_TAG}"
    )
  end

  desc 'Build docker production image'
  task :build_prod do
    tmpfs = "tmpfs_#{Time.now.to_i}.tar.bz2"
    Dir.chdir(PWD) do
      sh(
        "tar cvvfj #{tmpfs} "\
        './bin ' \
        './lang ' \
        './scripts ' \
        './src ' \
        './db/migrations '
      )
    end
    sh(
      'docker build '\
      '-t muell '\
      '--rm '\
      '-f docker/Dockerfile '\
      '--target production ' \
      "--build-arg GIT_TAG=\"#{GIT_TAG}\" "\
      "--build-arg GIT_REPO=\"#{GIT_REPO}\" "\
      "--build-arg BUILD_USER=\"#{BUILD_USER_INFO}\" "\
      "--build-arg BUILD_TIME=\"#{CURRENT_TIME}\" "\
      "--build-arg TMPFS=\"#{tmpfs}\" "\
      "#{PWD}"
    )
    FileUtils.rm(tmpfs)
  end

  desc 'Build and push a new docker production image'
  task build_push_prod: %i[build_prod push_prod]

  desc 'Build docker development image'
  task :build_dev do
    sh(
      'docker build '\
      '-t muell_dev '\
      '--rm '\
      '-f docker/Dockerfile '\
      '--target development '\
      "#{PWD}"
    )
  end

  desc 'Build docker tests image'
  task :build_testing do
    sh(
      'docker build '\
      '-t muell_rspec '\
      '--rm '\
      '-f docker/Dockerfile '\
      '--target testing '\
      "#{PWD}"
    )
  end

  desc 'Build docker linter image'
  task :build_linting do
    sh(
      'docker build '\
      '-t muell_rubocop '\
      '--rm '\
      '-f docker/Dockerfile '\
      '--target linting '\
      "#{PWD}"
    )
  end

  desc 'Build docker migrations image'
  task :build_migrations do
    sh(
      'docker build '\
      '-t muell_dbmate '\
      '--rm '\
      '-f docker/Dockerfile '\
      '--target base '\
      "#{PWD}"
    )
  end

  desc 'Build all docker images'
  task build_all: %i[
    build_prod
    build_dev
    build_tests
    build_lint
    build_migrations
  ]
end

namespace :hyper do
  desc 'Create docker containers on production system'
  task :create do
    sh(
      'hyper compose create '\
      '--force-recreate '\
      "--project-name=#{HYPER_SH_PROJECTNAME} "\
      "-f #{HYPER_SH_DOCKERFILE}"
    )
  end

  desc 'Create and start docker containers on production system'
  task :up do
    sh(
      'hyper compose up '\
      "--project-name=#{HYPER_SH_PROJECTNAME} "\
      "-f #{HYPER_SH_DOCKERFILE} "\
      '-d'
    )
  end

  desc 'Stop and remove docker containers, '\
    'volumes and images on production system'
  task :down do
    sh(
      'hyper compose down '\
      '--rmi=all '\
      "--project-name=#{HYPER_SH_PROJECTNAME}"
    )
  end

  desc 'Start docker containers on prodution system'
  task :start do
    sh(
      'hyper compose start '\
      "--project-name=#{HYPER_SH_PROJECTNAME}"
    )
  end

  desc 'Stop docker containers on prodution system'
  task :stop do
    sh(
      'hyper compose stop '\
      "--project-name=#{HYPER_SH_PROJECTNAME}"
    )
  end

  desc 'Pull new docker images from the repository'
  task :pull do
    sh(
      'hyper compose pull '\
      "-f #{HYPER_SH_DOCKERFILE}"
    )
  end

  desc 'Pull new docker images and restart containers'
  task update: %i[
    pull
    up
  ]

  desc 'Display some information about hyper'
  task :status do
    sh(
      'hyper ps && hyper volume ls && hyper fip ls && hyper info'
    )
  end
end

namespace :git do
  desc 'Install git hooks'
  task :install_hooks do
    Dir.chdir(GITHOOKS_TGTDIR) do
      hooks = Rake::FileList["#{GITHOOKS_SRCDIR}/**/*"]
      hooks.each do |fullfile|
        file = File.basename(fullfile)
        if File.symlink?(file)
          puts "#{file} exists. Overwrite? (Y/n): "
          next if STDIN.gets.chomp.casecmp('n')

          File.delete(file)
        end
        puts "Installing #{file}"
        File.symlink(fullfile, file)
      end
    end
  end

  latest_tag = ''
  next_tag = ''
  task :prepare_tag, [:type] do |_, args|
    type = args[:type]
    sh('git fetch --tags')
    latest_tag = `git tag -l --sort=v:refname | tail -n 1`
    ver_info = latest_tag.split('.').map(&:to_i)
    if type == :major
      ver_info[0] = ver_info[0] + 1
      ver_info[1] = 0
      ver_info[2] = 0
    end
    if type == :minor
      ver_info[1] = ver_info[1] + 1
      ver_info[2] = 0
    end
    ver_info[2] = ver_info[2] + 1 if type == :patch
    next_tag = ver_info.join('.')
  end

  desc 'Create a new release'
  task :release do
    type = ENV['TYPE']
    if type.nil?
      puts 'Usage: TYPE=<major|minor|patch> rake git:release'
      exit
    end
    Rake::Task['git:prepare_tag'].invoke(type.downcase.to_sym)
    exit if next_tag.eql?(latest_tag)
    Dir.chdir(PWD) do
      puts "Latest tag is #{latest_tag}"
      puts "Next Version Tag is #{next_tag}"

      sh(
        'git stash -u --keep-index && '\
        'git checkout master && '\
        'git merge -S --no-ff origin/development && '\
        "git tag -a -s -m \"Release Version #{next_tag}\" #{next_tag} && "\
        'git push --tags origin master && '\
        'git clean -df; '\
        "git checkout \"#{GIT_ACTIVE_BRANCH}\" && "\
        'git stash pop -q'
      )
    end
  end
end

namespace :dev do
  desc 'Start development environment'
  task :start do
    sh(
      'docker-compose '\
      "-f #{PWD}/docker-compose.dev.yml "\
      'up --build'
    )
  end

  desc 'Stop development environment'
  task :stop do
    sh(
      'docker-compose '\
      "-f #{PWD}/docker-compose.dev.yml "\
      'down'
    )
  end

  desc 'Restart development environment'
  task restart: %i[stop start]
end

desc 'Print status information about the bot'
task :status do
  sh('docker ps')
end

namespace :prod do
  desc 'Start production environment'
  task :start do
    sh(
      'docker-compose '\
      "-f #{PWD}/docker-compose.prod.yml "\
      'up --build '\
      '-d'
    )
  end

  desc 'Stop production environment'
  task :stop do
    sh(
      'docker-compose '\
      "-f #{PWD}/docker-compose.prod.yml "\
      'down'
    )
  end

  desc 'Restart production environment'
  task restart: %i[stop start]
end

namespace :tests do
  desc 'Run all tests'
  task :run_all do
    sh("docker run --rm -v #{PWD}:/app muell_rspec")
  end
end

namespace :checks do
  desc 'Run all analyses and checks'
  task :run_all do
    sh("docker run --rm --volume #{PWD}:/app muell_rubocop")
  end
end

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
      '--network=muell_backend '\
      "--env-file #{MIGRATION_ENV_FILE} "\
      'muell_dbmate '\
      "--migrations-dir #{DOCKER_MIGRATIONS_PATH} "\
      '--no-dump-schema '\
      "new #{name}"\
    )
  end

  desc 'Reset database and migrate to latest version'
  task :reset do
    sh(
      'docker run --rm '\
      "-v #{PWD}/db/:/db "\
      '--network=muell_backend '\
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

  desc 'Rollback the to latest migration'
  task :rollback do
    sh(
      'docker run --rm '\
      "-v #{PWD}/db/:/db "\
      '--network=muell_backend '\
      "--env-file #{MIGRATION_ENV_FILE} "\
      'muell_dbmate '\
      '--no-dump-schema '\
      "--migrations-dir #{DOCKER_MIGRATIONS_PATH} "\
      'rollback'
    )
  end
end

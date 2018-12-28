# frozen_string_literal: true

require 'rake'

# What to name the project inside hyper.sh.
# For more information regarding projects please
# refer to https://hyper.sh
HYPER_SH_PROJECTNAME = 'icstelegrambot'

# Region to use for spawing the container.
# For more information regarding available regions
# please refer to https://hyper.sh
HYPER_SH_REGION = 'eu-central-1'

# Full docker tag that shall be used to tag docker images
# when pushing the production docker image to the repository
# with the task `docker:push_prod`
DOCKER_IMAGE_TAG = 'benjaminsattler/icstelegrambot'

# Full gce tag that shall be used to tag docker images
# when pushing the production docker image to the repository
# with the task `gce:push_prod`
GCE_IMAGE_TAG = 'booming-octane-226319/icstelegrambot'

# GCE hostname that shall be used to push docker images to
# with the task `gce:push_prod`
GCE_REPOSITORY_HOST = 'eu.gcr.io'

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
GIT_USER_NAME = `git config user.name`.chomp.freeze

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
HYPER_SH_DOCKERFILE = 'docker-compose.hyper.yml'

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

# enable collection of task comments
Rake::TaskManager.record_task_metadata = true

Dir.glob("#{PWD}/**/*.rake").each { |r| import r }

desc 'Show task information'
task :default do
  puts
  puts "I found a total of #{Rake.application.tasks.length} tasks:"
  puts
  max_name_length = 0
  Rake.application.tasks.each do |task|
    next if task.comment.nil?

    max_name_length = [max_name_length, task.to_s.length].max
  end

  Rake.application.tasks.each do |task|
    next if task.comment.nil?

    line = task.to_s
    spaces_count = (max_name_length + 1) - task.to_s.length
    line = "#{line}#{' ' * spaces_count}# #{task.comment}"
    puts line
  end
end

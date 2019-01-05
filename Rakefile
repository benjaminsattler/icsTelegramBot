# frozen_string_literal: true

require 'rake'

# Name of the kubernetes context for the development cluster.
# This will be used as value for the --context parameter in
# kubectl calls
K8S_DEV_CONTEXT_NAME = 'docker-for-desktop'

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

# regex that will be used to parse the output of git ls-remote
# for the current tag
# rubocop:disable Metrics/LineLength
GIT_TAG_REGEX = '%[[:alnum:]]+[[:space:]]+refs/tags/([[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+)%\1%g'
# rubocop:enable Metrics/LineLength

# git tag of the current git branch HEAD
# will be used in a docker image label when building
# a new docker image
GIT_TAG = `git ls-remote --tags --refs -q | \
           tail -n 1 | \
           sed -E -n 's#{GIT_TAG_REGEX}p'`.chomp.freeze

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

# Environemnt variables file that shall be used for docker run
# when developing database migrations locally. Usually you want
# this to be your development environment to be able to test,
# migrate and rollback your migrations during development
MIGRATION_ENV_FILE = './k8s/configs/development.env'

# Location of the database migration files from inside the
# dbmate docker container. Usually you'll want this to equal
# the environment variable "MIGRATIONS_DIR" in the environment
# file specified by MIGRATION_ENV_FILE above
DOCKER_MIGRATIONS_PATH = '/db/migrations/mysql/'

# enable collection of task comments
Rake::TaskManager.record_task_metadata = true

# Notice:
# This will also take care of including the
# deployment configuration file in the project root
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

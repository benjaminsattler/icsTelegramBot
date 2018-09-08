# frozen_string_literal: true

require 'rake'
require 'optparse'

PWD = File.dirname(__FILE__).freeze

GITHOOKS_TGTDIR = "#{PWD}/.git/hooks/"

# below path needs to be relative to GITHOOKS_TRGTDIR
# because git is going to resolve relative filenames
# while it is cd'ed in the .git/hooks dir!
GITHOOKS_SRCDIR = '../../scripts/githooks'

GIT_ACTIVE_BRANCH = `git rev-parse --abbrev-ref HEAD | tr -d '\n'`.freeze

PROD_CONTAINER_NAME = 'muell_prod'

GIT_TAG = `git describe --tags | tr -d  '\n'`.freeze

GIT_REPO = `git remote get-url origin | tr -d '\n'`.freeze

GIT_USER_NAME = `git config user.name | tr -d '\n'`.freeze

GIT_USER_EMAIL = `git config user.email | tr -d '\n'`.freeze

LOCAL_USER_NAME = `whoami | tr -d '\n'`.freeze

LOCAL_HOST_NAME = `hostname | tr -d '\n'`.freeze

BUILD_USER_INFO = \
  "#{GIT_USER_NAME} <#{GIT_USER_EMAIL}> "\
  "(#{LOCAL_USER_NAME}@#{LOCAL_HOST_NAME})"

BUILD_TIME = `date +"%d%m%Y-%H%M%S" | tr -d '\n'`.freeze

namespace :docker do
  desc 'Build docker production image'
  task :build_prod do
    sh(
      'docker build '\
      '-t muell '\
      '--rm '\
      '-f docker/app-production/Dockerfile '\
      "--build-arg GIT_TAG=\"#{GIT_TAG}\" "\
      "--build-arg GIT_REPO=\"#{GIT_REPO}\" "\
      "--build-arg BUILD_USER=\"#{BUILD_USER_INFO}\" "\
      "--build-arg BUILD_TIME=\"#{BUILD_TIME}\" "\
      "#{PWD}"
    )
  end

  desc 'Build docker development image'
  task build_dev: [:build_prod] do
    sh(
      'docker build '\
      '-t muell_dev '\
      '--rm '\
      '-f docker/app-devel/Dockerfile '\
      "#{PWD}"
    )
  end

  desc 'Build docker tests image'
  task build_tests: [:build_prod] do
    sh(
      'docker build '\
      '-t muell_rspec '\
      '--rm '\
      '-f docker/rspec/Dockerfile '\
      "#{PWD}"
    )
  end

  desc 'Build docker linter image'
  task build_lint: [:build_prod] do
    sh(
      'docker build '\
      '-t muell_rubocop '\
      '--rm '\
      '-f docker/rubocop/Dockerfile '\
      "#{PWD}"
    )
  end

  desc 'Build docker migrations image'
  task :build_migrations do
    sh(
      'docker build '\
      '-t muell_dbmate '\
      '--rm '\
      '-f docker/migrations/Dockerfile '\
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
        end
        puts "Installing #{file}"
        File.delete(file)
        File.symlink(fullfile, file)
      end
    end
  end
end

namespace :dev do
  desc 'Start development environment'
  task :start do
    sh('docker-compose up --build -d')
  end

  desc 'Stop development environment'
  task :stop do
    sh('docker-compose down')
  end

  desc 'Restart development environment'
  task restart: %i[stop start]
end

namespace :prod do
  desc 'Start production environment'
  task :start do
    sh(
      'docker run '\
      "-v #{PWD}/:/app "\
      "-v #{PWD}/assets/:/assets "\
      "-v #{PWD}/db/:/db "\
      "-v #{PWD}/log/:/log "\
      "-v #{PWD}/config/:/config "\
      '--network=muell_frontend '\
      "--name #{PROD_CONTAINER_NAME} "\
      '-e ICSBOT_ENV=production '\
      '--rm '\
      '-d '\
      'muell '
    )
  end

  desc 'Stop production environment'
  task :stop do
    sh("docker stop #{PROD_CONTAINER_NAME}")
  end

  desc 'Restart production environment'
  task restart: %i[stop start]
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
  type = nil
  optparser = OptionParser.new do |opts|
    opts.banner = 'Usage: rake release -- <options>'
    opts.on('--patch') { type = :patch }
    opts.on('--minor') { type = :minor }
    opts.on('--major') { type = :major }
  end
  args = optparser.order!(ARGV) {}
  optparser.parse!(args)
  if type.nil?
    puts optparser.help
    exit
  end

  Rake::Task[:prepare_tag].invoke(type)
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
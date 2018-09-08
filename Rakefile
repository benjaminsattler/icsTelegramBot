# frozen_string_literal: true

require 'rake'

PWD = File.dirname(__FILE__)

GITHOOKS_TGTDIR = "#{PWD}/.git/hooks/"
# below path needs to be relative to GITHOOKS_TRGTDIR
# because git is going to resolve relative filenames
# while it is cd'ed in the .git/hooks dir!
GITHOOKS_SRCDIR = '../../scripts/githooks'

PROD_CONTAINER_NAME = 'muell_prod'

namespace :docker do
  desc 'Build docker production image'
  task :build_prod do
    sh(
      'docker build '\
      '-t muell '\
      '--rm '\
      '-f docker/app-production/Dockerfile '\
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
      '--network=muell_frontend '\
      "--name #{PROD_CONTAINER_NAME} "\
      '-e ICSBOT_ENV=production '\
      '--rm '\
      '-d '\
      'muell '\
      '/app/bin/server '\
      '--main=MainThread '\
      '--log=/log/bot_production.log'
    )
  end

  desc 'Stop production environment'
  task :stop do
    sh("docker stop #{PROD_CONTAINER_NAME}")
  end

  desc 'Restart production environment'
  task restart: %i[stop start]
end

desc 'Create a new release'
task :release do
  ARGV.each { |a| task(a.to_sym) { ; } }
  if ARGV.empty? || !%i[major minor patch].include?(ARGV[1].to_sym)
    puts 'Invocation: rake release major|minor|patch'
  end
  type = ARGV[1].to_sym
  Dir.chdir(PWD) do
    sh('git fetch --tags')
    latest_tag = `git tag -l --sort=v:refname | tail -n 1`
    ver_info = latest_tag.split('.').map(&:to_i)
    ver_info[0] = ver_info[0] + 1 if type == :major
    ver_info[1] = ver_info[1] + 1 if type == :minor
    ver_info[2] = ver_info[2] + 1 if type == :patch
    next_tag = ver_info.join('.')
    puts "Latest tag is #{latest_tag}"
    puts "Next Version Tag is #{next_tag}"

    active_branch = `git rev-parse --abbrev-ref HEAD`
    `git stash -u --keep-index; \
    git checkout master; \
    git merge -S --no-ff origin/development; \
    git tag -a -s -m "Release Version #{next_tag}" #{next_tag}; \
    git push --tags origin master; \
    git clean -df; \
    git checkout #{active_branch}; \
    git stash pop -q`
  end
end

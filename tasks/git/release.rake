# frozen_string_literal: true

namespace :git do
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

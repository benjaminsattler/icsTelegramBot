# frozen_string_literal: true

namespace :docker do
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
end

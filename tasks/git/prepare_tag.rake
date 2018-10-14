# frozen_string_literal: true

namespace :git do
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
end

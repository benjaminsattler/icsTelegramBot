# frozen_string_literal: true

##
# SemVer can bump semever strings
class SemVer
  def next(latest_tag, type)
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
    ver_info.join('.')
  end
end

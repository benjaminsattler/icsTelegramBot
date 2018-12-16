# frozen_string_literal: true

##
# This class writes a file to disk
class FileWriter
  def write(contents, path, _opts = {})
    File.write(path, contents)
  end
end

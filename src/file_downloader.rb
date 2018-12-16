# frozen_string_literal: true

##
# This interface represents a file downloader
class FileDownloader
  def get(_path, _opts)
    raise NotImplementedError
  end
end

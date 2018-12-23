# frozen_string_literal: true

##
# This class reads a file
class FileUploader
  def upload(path, opts = {})
    Faraday::UploadIO.new(path, opts[:mime_type])
  end
end

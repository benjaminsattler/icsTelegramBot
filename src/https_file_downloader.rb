# frozen_string_literal: true

require 'file_downloader'

##
# This class downloads files over HTTPS
class HttpsFileDownloader < FileDownloader
  def get(path, _opts = {})
    uri = URI(path)
    res = Net::HTTP.get_response(uri)

    return nil if res.code.to_i != 200

    res.body
  end
end


# frozen_string_literal: true

##
# This module serves as a collection of
# methods used frequently and everywhere.
module Util
  def self.pad(str, length, pad = '0', dir = 'l')
    out = str.to_s
    while out.size < length
      out = if dir == 'l'
              pad + out
            else
              out + pad
            end
    end
    out
  end
end

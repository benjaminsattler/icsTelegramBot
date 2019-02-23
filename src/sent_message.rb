# frozen_string_literal: true

##
# This class represents a delivered message to a telegram user
class SentMessage
  attr_reader :id_recv, :datetime, :id, :i18nkey, :i18nparams

  def initialize(opts)
    @id_recv = opts[:id_recv]
    @datetime = opts[:datetime]
    @id = opts[:id]
    @i18nkey = opts[:i18nkey]
    @i18nparams = opts[:i18nparams]
  end
end

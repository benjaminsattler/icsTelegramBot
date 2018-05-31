class Command
  def initialize(messageSender)
    @messageSender = messageSender
  end

  def process(_msg, _userid, _chatid, _silent)
    raise NotImplementedError
  end
end

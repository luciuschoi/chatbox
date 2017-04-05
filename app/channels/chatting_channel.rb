class ChattingChannel < ApplicationCable::Channel
  def subscribed
    stream_from "chatting_channel"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end

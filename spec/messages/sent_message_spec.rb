# frozen_string_literal: true

require 'messages/sent_message'

RSpec.describe SentMessage do
  let(:sent_message) do
    described_class.new(
      id_revc: 42,
      datetime: Time.new.to_i,
      id: Random.rand(2**31),
      i18nkey: 'i18nkey',
      i18nparams: {
        param1: 'foo',
        param2: 43
      }
    )
  end

  it 'forbids reassignment' do
    expect { sent_message.id_recv = 2 }.to raise_error(NoMethodError)
    expect { sent_message.datetime = 1 }.to raise_error(NoMethodError)
    expect { sent_message.id = 2 }.to raise_error(NoMethodError)
    expect { sent_message.i18nkey = 'foo' }.to raise_error(NoMethodError)
    expect { sent_message.i18nparams = {} }.to raise_error(NoMethodError)
  end
end

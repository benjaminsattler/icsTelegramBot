# frozen_string_literal: true

require 'log'

RSpec.describe Logger do
  describe 'log' do
    it 'prints the given message' do
      expect do
        described_class.log('foo')
      end.to output(/foo/).to_stdout
    end
  end
end

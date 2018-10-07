# frozen_string_literal: true

require 'configuration/configuration.rb'

RSpec.describe Configuration do
  describe 'get' do
    it 'raises NotImplementedError' do
      c = described_class.new
      expect { c.get('foo') } .to raise_error NotImplementedError
    end
  end
end

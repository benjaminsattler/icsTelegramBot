# frozen_string_literal: true

require 'configuration/environment_configuration.rb'
require 'yaml'

RSpec.describe EnvironmentConfiguration do
  describe 'get' do
    it 'reads corresponding environment variables' do
      values = {
        TEST: 'test1',
        DOT_VAR: 'test2',
        DOTS_VARIABLE: 'test3'
      }
      values.each do |key, value|
        allow(ENV).to receive(:[]).with(key.to_s).and_return(value)
      end
      c = described_class.new
      expect(c.get('TEST')).to be_equal(values[:TEST])
      expect(c.get('DOT_VAR')).to be_equal(values[:DOT_VAR])
      expect(c.get('DOTS_VARIABLE')).to be_equal(values[:DOTS_VARIABLE])
    end

    it 'replaces dots with underscores in environment variables' do
      values = { DOT_VAR: 'test2', DOTS_VARIABLE: 'test3' }
      values.each do |key, value|
        allow(ENV).to receive(:[]).with(key.to_s).and_return(value)
      end
      c = described_class.new
      expect(c.get('DOT.VAR')).to be_equal(values[:DOT_VAR])
      expect(c.get('DOTS.VARIABLE')).to be_equal(values[:DOTS_VARIABLE])
    end

    it 'handles unknown environment variables' do
      values = { DOT_VAR: 'test2', DOTS_VARIABLE: 'test3' }
      values.each do |key, value|
        allow(ENV).to receive(:[]).with(key.to_s).and_return(value)
      end
      allow(ENV).to receive(:[]).and_return(nil)
      c = described_class.new
      expect(c.get('UNKNOWN.DOTTED.VAR')).to be_equal(nil)
      expect(c.get('UNKNOWNVARIABLE')).to be_equal(nil)
    end
  end
end

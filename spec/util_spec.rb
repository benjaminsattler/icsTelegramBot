# frozen_string_literal: true

require 'util'

RSpec.describe Util do
  describe 'pad' do
    it 'pads short strings to the left' do
      expect(described_class.pad('aa', 5, 'b', 'l')).to eq('bbbaa')
      expect(described_class.pad('aa', 3, 'b', 'l')).to eq('baa')
    end

    it 'pads short strings to the right' do
      expect(described_class.pad('aa', 5, 'b', 'r')).to eq('aabbb')
      expect(described_class.pad('aa', 3, 'b', 'r')).to eq('aab')
    end

    it 'does not pad long strings to the left' do
      expect(described_class.pad('aa', 2, 'b', 'l')).to eq('aa')
      expect(described_class.pad('aa', 1, 'b', 'l')).to eq('aa')
    end

    it 'does not pad long strings to the right' do
      expect(described_class.pad('aa', 2, 'b', 'r')).to eq('aa')
      expect(described_class.pad('aa', 1, 'b', 'r')).to eq('aa')
    end

    it 'applies correct default values' do
      expect(described_class.pad('aa', 4)).to eq('00aa')
    end
  end
end

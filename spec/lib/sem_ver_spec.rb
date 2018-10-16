# frozen_string_literal: true

require 'sem_ver'

RSpec.describe SemVer do
  describe 'next' do
    it 'increases patch level when called with type :patch' do
      sv = described_class.new
      expect(sv.next('1.0.0', :patch)).to eq('1.0.1')
      expect(sv.next('2.0.1', :patch)).to eq('2.0.2')
      expect(sv.next('3.1.2', :patch)).to eq('3.1.3')
    end

    it 'increases minor level when called with type :minor' do
      sv = described_class.new
      expect(sv.next('1.0.0', :minor)).to eq('1.1.0')
      expect(sv.next('2.4.1', :minor)).to eq('2.5.0')
    end

    it 'increases major level when called with type :major' do
      sv = described_class.new
      expect(sv.next('1.0.0', :major)).to eq('2.0.0')
      expect(sv.next('2.4.1', :major)).to eq('3.0.0')
    end
  end
end

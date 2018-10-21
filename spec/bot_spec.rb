# frozen_string_literal: true

require 'bot'

RSpec.describe Bot do
  describe 'is_admin_user' do
    it 'returns false for users that are not in the list of admin users' do
      bot = described_class.new('foo', [123])
      expect(bot.admin_user?(122)).to eq(false)
    end

    it 'returns true for users that are in the list of admin users' do
      bot = described_class.new('foo', [123])
      expect(bot.admin_user?(123)).to eq(true)
    end
  end
end

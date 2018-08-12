# frozen_string_literal: true

require 'persistence/factory'

RSpec.describe Factory do
  let(:config_map) do
    { 'sqlite' => {
      'db_path' => './db/sqlite/factory_tests.db'
    } }
  end
  let(:factory) { described_class.new(config_map) }

  after(:all) { File.delete('./db/sqlite/factory_tests.db') }

  describe 'get' do
    it 'returns a Sqlite instance' do
      expect { factory.get('sqlite') }.to raise_error(SQLite3::SQLException)
    end

    it 'throws for unknown persistences' do
      expect { factory.get('bla') }.to raise_error(NotImplementedError)
    end
  end

  describe 'get_sqlite' do
    it 'returns a new Sqlite instance' do
      expect do
        factory.get_sqlite(config_map['sqlite'])
      end.to raise_error(SQLite3::SQLException)
    end
  end
end

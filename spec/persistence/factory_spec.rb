# frozen_string_literal: true

require 'persistence/factory'

RSpec.describe Factory do
  let(:db_path) { './db/sqlite/factory_tests.db' }

  after(:all) { File.delete('./db/sqlite/factory_tests.db') }

  describe 'get' do
    it 'returns a Sqlite instance' do
      config_map = instance_double('config_map')
      allow(config_map).to receive(:get).with('sqlite.db_path').and_return(
        db_path
      )
      factory = described_class.new(config_map)
      expect { factory.get('sqlite') }.to raise_error(SQLite3::SQLException)
    end

    it 'throws for unknown persistences' do
      config_map = instance_double('config_map')
      allow(config_map).to receive(:get).with('sqlite.db_path').and_return(
        db_path
      )
      factory = described_class.new(config_map)
      expect { factory.get('bla') }.to raise_error(NotImplementedError)
    end
  end

  describe 'sqlite' do
    it 'returns a new Sqlite instance' do
      config_map = instance_double('config_map')
      allow(config_map).to receive(:get).with('sqlite.db_path').and_return(
        db_path
      )
      factory = described_class.new(config_map)
      expect do
        factory.sqlite
      end.to raise_error(SQLite3::SQLException)
    end
  end
end

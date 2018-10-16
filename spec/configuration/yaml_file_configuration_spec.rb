# frozen_string_literal: true

require 'configuration/yaml_file_configuration.rb'
require 'yaml'

RSpec.describe YamlFileConfiguration do
  it 'stores given filename in constructor' do
    filename = 'foobar.yaml'
    c = described_class.new(filename)
    expect(c.config_filename).to be_equal(filename)
  end

  describe 'load_config_from_file' do
    it 'reads the given file' do
      filename = 'foobar.yaml'
      config = "foo: 'bar'"
      described_class.new('bla.yaml')
      allow(YAML).to receive(:load_file).with(filename, 'r').and_return(
        YAML.safe_load(config)
      )
    end
  end

  describe 'get' do
    it 'reads the file only on first read' do
      filename = 'foobar.yaml'
      config = "foo: 'bar'"
      allow(YAML).to receive(:load_file).once.and_return(YAML.safe_load(config))
      c = described_class.new(filename)
      c.get('foo')
      c.get('foo')
    end

    it 'returns the correct index' do
      filename = 'foobar.yaml'
      config = <<~YAMLDOC
        foo: 'bar'
        baz: 'bla'
        hu:
          ha: 'yes'
      YAMLDOC
      allow(YAML).to receive(:load_file).once.and_return(YAML.safe_load(config))
      c = described_class.new(filename)
      expect(c.get('foo')).to eq('bar')
      expect(c.get('baz')).to eq('bla')
      expect(c.get('hu.ha')).to eq('yes')
    end

    it 'handles unknown indices' do
      filename = 'foobar.yaml'
      config = <<~YAMLDOC
        foo: 'bar'
        baz: 'bla'
        hu:
          ha: 'yes'
      YAMLDOC
      allow(YAML).to receive(:load_file).once.and_return(YAML.safe_load(config))
      c = described_class.new(filename)
      expect(c.get('blub')).to be_nil
      expect(c.get('hu.ho')).to be_nil
      expect(c.get('hu.missing.item')).to be_nil
    end
  end
end

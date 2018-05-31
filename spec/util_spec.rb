require 'util'

RSpec.describe 'pad' do
  it 'should pad short strings to the left' do
    expect(pad('aa', 5, 'b', 'l')).to eq('bbbaa')
    expect(pad('aa', 3, 'b', 'l')).to eq('baa')
  end

  it 'should pad short strings to the right' do
    expect(pad('aa', 5, 'b', 'r')).to eq('aabbb')
    expect(pad('aa', 3, 'b', 'r')).to eq('aab')
  end

  it 'should not pad long strings to the left' do
    expect(pad('aa', 2, 'b', 'l')).to eq('aa')
    expect(pad('aa', 1, 'b', 'l')).to eq('aa')
  end

  it 'should not pad long strings to the right' do
    expect(pad('aa', 2, 'b', 'r')).to eq('aa')
    expect(pad('aa', 1, 'b', 'r')).to eq('aa')
  end

  it 'should apply correct default values' do
    expect(pad('aa', 4)).to eq('00aa')
  end
end

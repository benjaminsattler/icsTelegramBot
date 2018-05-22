require 'log'

RSpec.describe 'Logger' do
    describe 'log' do
        it 'should print the given message' do
            expect {
                Logger::log('foo')
            }.to output(/foo/).to_stdout
        end
    end
end

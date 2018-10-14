# frozen_string_literal: true

desc 'Print status information about the bot'
task :status do
  sh('docker ps')
end

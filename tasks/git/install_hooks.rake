# frozen_string_literal: true

namespace :git do
  desc 'Install git hooks'
  task :install_hooks do
    Dir.chdir(GITHOOKS_TGTDIR) do
      hooks = Rake::FileList["#{GITHOOKS_SRCDIR}/**/*"]
      hooks.each do |fullfile|
        file = File.basename(fullfile)
        if File.symlink?(file)
          puts "#{file} exists. Overwrite? (Y/n): "
          next if STDIN.gets.chomp.casecmp('n')

          File.delete(file)
        end
        puts "Installing #{file}"
        File.symlink(fullfile, file)
      end
    end
  end
end

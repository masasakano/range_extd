require 'rake/testtask'

desc "Run tests (Usage: rake test all_required=true/false)"
task :test do
  Rake::TestTask.new do |t|
    t.libs << 'test'
    case ENV['all_required']
    when 'true', 'yes', 'y', 't', 'T'
      t.test_files = FileList['test/*_test.rb']  # where many additional require are executed.
    else
      # testing default "test/test*.rb"
    end
  end
end


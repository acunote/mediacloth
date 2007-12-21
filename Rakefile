require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

task :default => [:parser]


desc 'Regenerate the parser with racc'
racc_flags=""
#racc_flags="-g -v"
file "lib/mediacloth/mediawikiparser.rb" => ["lib/mediacloth/mediawikiparser.y"] do |t|
    sh "cd lib/mediacloth && racc #{racc_flags} mediawikiparser.y -o mediawikiparser.rb && cd .. && cd .."
end
task :parser => "lib/mediacloth/mediawikiparser.rb"


desc 'Test'
Rake::TestTask.new(:test => [:parser]) do |t|
    t.libs << 'lib'
    t.libs << 'test'
    t.pattern = 'test/*.rb'
    t.verbose = true
end


desc 'Generate documentation.'
Rake::RDocTask.new(:rdoc) do |rdoc|
    rdoc.rdoc_dir = 'rdoc'
    rdoc.title    = 'Mediacloth'
    rdoc.options << '--line-numbers' << '--inline-source'
    rdoc.rdoc_files.include('README')
    rdoc.rdoc_files.include('lib/**/*.rb')
end

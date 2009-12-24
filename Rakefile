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

namespace :test do

desc '(Re)generate test data'
task :regenerate do
    Dir["test/data/input*"].each do |file|
        if file =~ /input([0-9]+)$/
            `ruby -I lib/ test/dataproducers/lex.rb #{$1}`
            `ruby -I lib/ test/dataproducers/html.rb #{$1}`
            `ruby -I test/ -I lib/ test/dataproducers/ast.rb #{$1}`
        end
    end
end

end


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

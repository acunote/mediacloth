
racc_flags=""
#racc_flags="-g -v"

task :default => [:parser]

file "src/mediawikiparser.rb" => ["src/mediawikiparser.y"] do |t|
    sh "cd src && racc #{racc_flags} mediawikiparser.y -o mediawikiparser.rb && cd .."
end

task :parser => "src/mediawikiparser.rb"

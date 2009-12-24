require 'mediacloth/mediawikilexer'
require 'mediacloth/mediawikiparser'
require 'debugwalker'

def produce(index)
    file = File.new("#{File.dirname(__FILE__)}/../data/ast#{index}", "w")
    inputFile = File.new("#{File.dirname(__FILE__)}/../data/input#{index}", "r")
    input = inputFile.read

    parser = MediaWikiParser.new
    parser.lexer = MediaWikiLexer.new
    ast = parser.parse(input)
    walker = DebugWalker.new
    walker.parse(ast)
    
    file.write(walker.tree)
    file.close
end

if ARGV.empty?
    (1..21).each { |i| produce(i) }
else
    produce ARGV[0].to_i
end

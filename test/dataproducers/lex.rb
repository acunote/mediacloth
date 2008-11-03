require 'mediacloth/mediawikilexer'

puts 

def produce(index)
    file = File.new("#{File.dirname(__FILE__)}/../data/lex#{index}", "w")
    inputFile = File.new("#{File.dirname(__FILE__)}/../data/input#{index}", "r")
    input = inputFile.read

    lexer = MediaWikiLexer.new
    tokens = lexer.tokenize(input)
    file.write(tokens.to_s)
    file.close
end

if ARGV.empty?
    (1..13).each { |i| produce(i) }
else
    produce ARGV[0].to_i
end

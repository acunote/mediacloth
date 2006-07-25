require 'mediacloth/mediawikilexer'

def produce(index)
    file = File.new("../data/lex#{index}", "w")
    inputFile = File.new("../data/input#{index}", "r")
    input = inputFile.read

    lexer = MediaWikiLexer.new
    tokens = lexer.tokenize(input)
    file.write(tokens.to_s)
    file.close
end

#1..5.each { |i| produce(1) }
produce(8)

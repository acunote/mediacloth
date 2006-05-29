require 'mediawikilexer'
require 'mediawikiparser'
require 'mediawikiparams'
require 'mediawikihtmlgenerator'

def produce(index)
    file = File.new("../data/html#{index}", "w")
    inputFile = File.new("../data/input#{index}", "r")
    input = inputFile.read

    parser = MediaWikiParser.new
    parser.lexer = MediaWikiLexer.new
    ast = parser.parse(input)
    MediaWikiParams.instance.time = Time.mktime(2000, 1, 1, 1, 1, 1, 1)
    generator = MediaWikiHTMLGenerator.new
    generator.parse(ast)

    file.write(generator.html)
    file.close
end

# (3..5).each { |i| produce(i) }
produce(3)

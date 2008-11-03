require 'mediacloth'

def produce(index)
    file = File.new("#{File.dirname(__FILE__)}/../data/html#{index}", "w")
    inputFile = File.new("#{File.dirname(__FILE__)}/../data/input#{index}", "r")
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

if ARGV.empty?
    (1..13).each { |i| produce(i) }
else
    produce ARGV[0].to_i
end

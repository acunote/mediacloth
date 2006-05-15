require 'mediawikilexer'
require 'mediawikiparser'
require 'mediawikihtmlgenerator'

require 'test/unit'
require 'testhelper'

class Parser_Test < Test::Unit::TestCase

    include TestHelper

    def test_input
        testFiles("html") { |input,result|
            parser = MediaWikiParser.new
            parser.lexer = MediaWikiLexer.new
            ast = parser.parse(input)
            generator = MediaWikiHTMLGenerator.new
            generator.parse(ast)
            puts generator.html
        }
    end

end

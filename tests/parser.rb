require 'wikimedialexer'
require 'wikimediaparser'
require 'test/unit'
require 'testhelper'

class Parser_Test < Test::Unit::TestCase

    include TestHelper

    def test_input
        testFiles("result") { |input,result|
            parser = WikiMediaParser.new
            parser.lexer = WikiMediaLexer.new
            parser.parse(input)
        }
    end

end

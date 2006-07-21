require 'mediacloth/mediawikilexer'
require 'test/unit'
require 'testhelper'

class Lexer_Test < Test::Unit::TestCase

    include TestHelper

    def test_input
        test_files("lex") { |input,result|
            lexer = MediaWikiLexer.new
            tokens = lexer.tokenize(input)
            assert_equal(tokens.to_s, result)
        }
    end

    def test_empty
        assert_equal(lex(""), [[false,false]])
    end

    def test_preformatted
        #assure preformatted text works as expected at the start of the text
        assert_equal(lex(" Foo\n"), [[:PRE, "Foo\n"], [false, false]])
        assert_equal(lex(" Foo"), [[:PRE, "Foo"], [false, false]])
    end

    def test_hline
        #assure that at the start of the text hline still works
        assert_equal(lex("----"), [[:HLINE, "----"], [false, false]])
        assert_equal(lex("\n----"), [[:HLINE, "----"], [false, false]])
    end

    def test_ending_text_token
        #check for a problem when the last token is TEXT and it's not included
        assert_equal(lex("\n----\nfoo\n"), [[:HLINE, "----"], [:TEXT, "\nfoo\n"], [false, false]])
        assert_equal(lex("\n----\nfoo\n Hehe"),
            [[:HLINE, "----"], [:TEXT, "\nfoo\n"], [:PRE, "Hehe"], [false, false]])
    end

    def test_bullets
        assert_equal(lex("* Foo"),
            [[:UL_START, ""], [:LI_START, ""], [:TEXT, "Foo"], [:LI_END, ""], [:UL_END, ""], [false, false]])
    end

    def test_nested_bullets
        assert_equal(lex("**Foo"), [[:UL_START, ""], [:LI_START, ""],
            [:UL_START, ""], [:LI_START, ""], [:TEXT, "Foo"], [:LI_END, ""],
            [:UL_END, ""], [:LI_END, ""], [:UL_END, ""], [false, false]])
    end

private
    def lex(string)
        lexer = MediaWikiLexer.new
        lexer.tokenize(string)
    end

end

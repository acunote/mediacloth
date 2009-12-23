require 'mediacloth/mediawikilexer'
require 'mediacloth/mediawikiparser'

require 'test/unit'
require 'testhelper'
require 'debugwalker'

class Parser_Test < Test::Unit::TestCase

    include TestHelper

    def test_input
        test_files("result") { |input,result|
            assert_generates(result, input, "Mismatch in result file")
        }
    end

    def test_ast_structure_paragraphs
        assert_generates "WikiAST[0, 4]\nParagraphAST[0, 4]\nParagraphAST[0, 4]\nTextAST[0, 4]: None \n",
                         "text"
        assert_generates "WikiAST[0, 14]\nParagraphAST[0, 5]\nParagraphAST[0, 5]\nTextAST[0, 5]: None \nSectionAST[5, 9]\n",
                         "text\n=heading="
        assert_generates "WikiAST[0, 15]\nParagraphAST[0, 6]\nParagraphAST[0, 6]\nTextAST[0, 6]: None \nSectionAST[6, 9]\n",
                         "text\n\n=heading="
        assert_generates "WikiAST[0, 17]\nParagraphAST[0, 8]\nParagraphAST[0, 8]\nTextAST[0, 8]: None \nSectionAST[8, 9]\n",
                         "text\r\n\r\n=heading="
    end

    def test_ast_structure_formatting
        assert_generates "WikiAST[0, 10]\nParagraphAST[0, 10]\nParagraphAST[0, 10]\nFormattedAST[0, 10]\nTextAST[2, 6]: None \n",
                         "''italic''"
        assert_generates "WikiAST[0, 10]\nParagraphAST[0, 10]\nParagraphAST[0, 10]\nFormattedAST[0, 10]\nTextAST[3, 4]: None \n",
                         "'''bold'''"
        assert_generates "WikiAST[0, 26]\nParagraphAST[0, 26]\nParagraphAST[0, 26]\nFormattedAST[0, 26]\nTextAST[2, 6]: None \nFormattedAST[8, 10]\nTextAST[11, 4]: None \nTextAST[18, 6]: None \n",
                         "''italic'''bold'''italic''"
        assert_generates "WikiAST[0, 10]\nParagraphAST[0, 10]\nParagraphAST[0, 10]\nFormattedAST[0, 10]\nTextAST[2, 8]: None \n",
                         "''italic\n\n"
    end

    def test_ast_structure_headings
        assert_generates "WikiAST[0, 9]\nSectionAST[0, 9]\n",
                         "=heading="
        assert_generates "WikiAST[0, 11]\nSectionAST[0, 11]\n",
                         "==heading=="
        assert_generates "WikiAST[0, 13]\nSectionAST[0, 8]\nParagraphAST[8, 5]\nParagraphAST[8, 5]\nTextAST[9, 4]: None \n",
                         "=heading=text"
        assert_generates "WikiAST[0, 14]\nSectionAST[0, 9]\nParagraphAST[9, 5]\nParagraphAST[9, 5]\nTextAST[9, 5]: None \n",
                         "==heading\ntext"
    end

    def test_ast_structure_inline_links
        assert_generates "WikiAST[0, 18]\nParagraphAST[0, 18]\nParagraphAST[0, 18]\nLinkAST[0, 18]\n",
                         "http://example.com"
        assert_generates "WikiAST[0, 28]\nParagraphAST[0, 28]\nParagraphAST[0, 28]\nLinkAST[0, 18]\nFormattedAST[18, 10]\nTextAST[20, 6]: None \n",
                         "http://example.com''italic''"
        assert_generates "WikiAST[0, 22]\nSectionAST[0, 22]\n",
                         "= http://example.com ="
        assert_generates "WikiAST[0, 49]\nParagraphAST[0, 49]\nParagraphAST[0, 49]\nLinkAST[0, 49]\n",
                         "http://example.com/SpecialCharacters%C3%A7%C3%A3o"
    end

    def test_ast_structure_links
        assert_generates "WikiAST[0, 2]\nParagraphAST[0, 2]\nParagraphAST[0, 2]\nTextAST[0, 2]: None \n",
                         "[]"
        assert_generates "WikiAST[0, 3]\nParagraphAST[0, 3]\nParagraphAST[0, 3]\nTextAST[0, 3]: None \n",
                         "[ ]"
        assert_generates "WikiAST[0, 20]\nParagraphAST[0, 20]\nParagraphAST[0, 20]\nLinkAST[0, 20]\n",
                         "[http://example.com]"
        assert_generates "WikiAST[0, 31]\nParagraphAST[0, 31]\nParagraphAST[0, 31]\nLinkAST[0, 31]\nFormattedAST[20, 10]\nTextAST[22, 6]: None \n",
                         "[http://example.com ''italic'']"
    end

    def test_ast_structure_table
        assert_generates "WikiAST[0, 5]\nTableAST[0, 5]\n",
                         "{|\n|}"
        assert_generates "WikiAST[0, 11]\nTableAST[0, 11]\nTableRowAST[0, 11]\nTableCellAST[3, 6]\nTextAST[4, 1]: None \nTableCellAST[3, 6]\nTextAST[7, 2]: None \n",
                         "{|\n|a||b\n|}"
        assert_generates "WikiAST[0, 14]\nTableAST[0, 14]\nTableRowAST[0, 14]\nTableCellAST[3, 3]\nTextAST[4, 2]: None \nTableRowAST[0, 14]\nTableCellAST[6, 6]\nTextAST[10, 2]: None \n",
                         "{|\n|a\n|-\n|b\n|}"
        assert_generates "WikiAST[0, 27]\nTableAST[0, 27]\nTableRowAST[0, 27]\nTableCellAST[3, 3]\nTextAST[4, 2]: None \nTableRowAST[0, 27]\nTableCellAST[6, 19]\nTextAST[23, 2]: None \n",
                         "{|\n|a\n|- align='left'\n|b\n|}"
    end

    def test_ast_structure_preformatted
        assert_generates "WikiAST[0, 3]\nParagraphAST[0, 3]\nParagraphAST[0, 3]\nTextAST[0, 3]: None \n",
                         "  \n"
        assert_generates "WikiAST[0, 11]\nParagraphAST[0, 5]\nParagraphAST[0, 5]\nTextAST[0, 5]: None \nPreformattedAST[5, 6]\n",
                         "text\n text\n"
        assert_generates "WikiAST[0, 11]\nParagraphAST[0, 5]\nParagraphAST[0, 5]\nTextAST[0, 5]: None \nPreformattedAST[5, 6]\n",
                         "text\n text\n"
        assert_generates "WikiAST[0, 12]\nPreformattedAST[0, 12]\n",
                         " ''italic''\n"
    end

    def test_ast_structure_hline
        assert_generates "WikiAST[0, 9]\nParagraphAST[0, 5]\nParagraphAST[0, 5]\nTextAST[0, 5]: None \nTextAST[5, 4]: HLine \n",
                         "text\n----"
        assert_generates "WikiAST[0, 10]\nParagraphAST[0, 6]\nParagraphAST[0, 6]\nTextAST[0, 6]: None \nTextAST[6, 4]: HLine \n",
                         "text\r\n----"
        assert_generates "WikiAST[0, 9]\nTextAST[0, 4]: HLine \nParagraphAST[4, 5]\nParagraphAST[4, 5]\nTextAST[4, 5]: None \n",
                         "----\ntext"
        assert_generates "WikiAST[0, 10]\nTextAST[0, 4]: HLine \nParagraphAST[4, 2]\nParagraphAST[4, 2]\nTextAST[4, 2]: None \nParagraphAST[6, 4]\nParagraphAST[6, 4]\nTextAST[6, 4]: None \n",
                         "----\n\ntext"
    end

    def test_ast_structure_nowiki
        assert_generates "WikiAST[0, 18]\nParagraphAST[0, 27]\nParagraphAST[0, 27]\nTextAST[8, 10]: None \n",
                         "<nowiki>''italic''</nowiki>"
        assert_generates "WikiAST[0, 18]\nParagraphAST[0, 35]\nParagraphAST[0, 35]\nTextAST[0, 18]: None \n",
                         "text<nowiki>''italic''</nowiki>text"
        assert_generates "WikiAST[0, 18]\nParagraphAST[0, 27]\nParagraphAST[0, 27]\nTextAST[8, 10]: None \n",
                         "<nowiki><u>uuu</u></nowiki>"
        assert_generates "WikiAST[0, 8]\nParagraphAST[0, 17]\nParagraphAST[0, 17]\nTextAST[0, 8]: None \n",
                         "text<nowiki/>text"
    end

    def test_ast_structure_hline
        assert_generates "WikiAST[0, 9]\nParagraphAST[0, 5]\nParagraphAST[0, 5]\nTextAST[0, 5]: None \nTextAST[5, 4]: HLine \n",
                         "text\n----"
        assert_generates "WikiAST[0, 10]\nParagraphAST[0, 6]\nParagraphAST[0, 6]\nTextAST[0, 6]: None \nTextAST[6, 4]: HLine \n",
                         "text\r\n----"
        assert_generates "WikiAST[0, 9]\nTextAST[0, 4]: HLine \nParagraphAST[4, 5]\nParagraphAST[4, 5]\nTextAST[4, 5]: None \n",
                         "----\ntext"
        assert_generates "WikiAST[0, 10]\nTextAST[0, 4]: HLine \nParagraphAST[4, 2]\nParagraphAST[4, 2]\nTextAST[4, 2]: None \nParagraphAST[6, 4]\nParagraphAST[6, 4]\nTextAST[6, 4]: None \n",
                         "----\n\ntext"
    end

    def test_ast_structure_xhtml_markup
        assert_generates "WikiAST[0, 13]\nParagraphAST[0, 13]\nParagraphAST[0, 13]\nElementAST[0, 13]\nTextAST[4, 4]: None \n",
                         "<tt>text</tt>"
        assert_generates "WikiAST[0, 5]\nParagraphAST[0, 5]\nParagraphAST[0, 5]\nElementAST[0, 5]\n",
                         "<tt/>"
        assert_generates "WikiAST[0, 24]\nParagraphAST[0, 24]\nParagraphAST[0, 24]\nElementAST[0, 24]\nTextAST[15, 4]: None \n",
                         "<tt class='tt'>text</tt>"
        assert_generates "WikiAST[0, 16]\nParagraphAST[0, 16]\nParagraphAST[0, 16]\nElementAST[0, 16]\nTextAST[4, 7]: None \n",
                         "<tt>\n\ntext\n</tt>"
        assert_generates "WikiAST[0, 29]\nParagraphAST[0, 29]\nParagraphAST[0, 29]\nElementAST[0, 29]\nPasteAST[4, 20]\nTextAST[11, 5]: None \n",
                         "<tt><paste>paste</paste></tt>"
        assert_generates "WikiAST[0, 34]\nParagraphAST[0, 34]\nParagraphAST[0, 34]\nLinkAST[0, 34]\nElementAST[20, 13]\nTextAST[24, 4]: None \n",
                         "[http://example.com <tt>text</tt>]"
    end

    def test_ast_structure_lists
        assert_generates "WikiAST[0, 2]\nListAST[0, 2]: ListAST \nListItemAST[0, 2]\nListItemAST[0, 2]\nTextAST[1, 1]: None \n",
                         "*a"
        assert_generates "WikiAST[0, 3]\nListAST[0, 3]: ListAST \nListItemAST[0, 3]\nListItemAST[0, 3]\nTextAST[1, 2]: None \n",
                         "*a\n"
        assert_generates "WikiAST[0, 10]\nListAST[0, 10]: ListAST \nListItemAST[0, 7]\nListItemAST[0, 7]\nTextAST[1, 2]: None \nListAST[3, 4]: ListAST \nListItemAST[3, 4]\nListItemAST[3, 4]\nTextAST[5, 2]: None \nListItemAST[7, 3]\nListItemAST[7, 3]\nTextAST[8, 2]: None \n",
                         "*a\n**i\n*b\n"
        assert_generates "WikiAST[0, 7]\nListAST[0, 7]: ListAST \nListItemAST[0, 4]\nListItemAST[0, 4]\nListAST[1, 3]: ListAST \nListItemAST[1, 3]\nListItemAST[1, 3]\nTextAST[2, 2]: None \nListItemAST[4, 3]\nListItemAST[4, 3]\nTextAST[5, 2]: None \n",
                         "**i\n*b\n"
        assert_generates "WikiAST[0, 2]\nListAST[0, 2]: ListAST \nListItemAST[0, 2]\nListItemAST[0, 2]\nTextAST[1, 1]: None \n",
                         "#a"
        assert_generates "WikiAST[0, 3]\nListAST[0, 3]: ListAST \nListItemAST[0, 3]\nListItemAST[0, 3]\nTextAST[1, 2]: None \n",
                         "#a\n"
        assert_generates "WikiAST[0, 10]\nListAST[0, 10]: ListAST \nListItemAST[0, 7]\nListItemAST[0, 7]\nTextAST[1, 2]: None \nListAST[3, 4]: ListAST \nListItemAST[3, 4]\nListItemAST[3, 4]\nTextAST[5, 2]: None \nListItemAST[7, 3]\nListItemAST[7, 3]\nTextAST[8, 2]: None \n",
                         "#a\n##i\n#b\n"
        assert_generates "WikiAST[0, 7]\nListAST[0, 7]: ListAST \nListItemAST[0, 4]\nListItemAST[0, 4]\nListAST[1, 3]: ListAST \nListItemAST[1, 3]\nListItemAST[1, 3]\nTextAST[2, 2]: None \nListItemAST[4, 3]\nListItemAST[4, 3]\nTextAST[5, 2]: None \n",
                         "##i\n#b\n"
        assert_generates "WikiAST[0, 6]\nListAST[0, 3]: ListAST \nListItemAST[0, 3]\nListItemAST[0, 3]\nTextAST[1, 2]: None \nListAST[3, 3]: ListAST \nListItemAST[3, 3]\nListItemAST[3, 3]\nTextAST[4, 2]: None \n",
                         "*a\n#b\n"
        assert_generates "WikiAST[0, 10]\nListAST[0, 10]: ListAST \nListItemAST[0, 7]\nListItemAST[0, 7]\nTextAST[1, 2]: None \nListAST[3, 4]: ListAST \nListItemAST[3, 4]\nListItemAST[3, 4]\nTextAST[5, 2]: None \nListItemAST[7, 3]\nListItemAST[7, 3]\nTextAST[8, 2]: None \n",
                         "*a\n*#i\n*b\n"
        assert_generates "WikiAST[0, 2]\nListAST[0, 2]: ListAST \nListTermAST[0, 2]\nTextAST[1, 1]: None \n",
                         ";a"
        assert_generates "WikiAST[0, 2]\nListAST[0, 2]: ListAST \nListDefinitionAST[0, 2]\nTextAST[1, 1]: None \n",
                         ":b"
        assert_generates "WikiAST[0, 6]\nListAST[0, 3]: ListAST \nListTermAST[0, 3]\nTextAST[1, 2]: None \nListAST[3, 3]: ListAST \nListTermAST[3, 3]\nTextAST[4, 2]: None \n",
                         ";a\n;a\n"
        assert_generates "WikiAST[0, 7]\nListAST[0, 3]: ListAST \nListTermAST[0, 3]\nTextAST[1, 2]: None \nParagraphAST[3, 4]\nParagraphAST[3, 4]\nTextAST[3, 4]: None \n",
                         ";a\ntext"
    end

private

   def assert_generates(result, input, message=nil)
       assert_equal(result, generate(input), message)
   end

   def generate(input)
       parser = MediaWikiParser.new
       parser.lexer = MediaWikiLexer.new
       ast = parser.parse(input)
       walker = DebugWalker.new
       walker.parse(ast)
       walker.tree
   end

end

require 'mediacloth/mediawikilexer'
require 'mediacloth/mediawikiparser'

require 'test/unit'
require 'testhelper'
require 'debugwalker'

class Parser_Test < Test::Unit::TestCase

    class << self
      include TestHelper
    end

    test_files("ast") do |input,result,resultname|
      resultname =~ /([0-9]+)$/
      define_method("test_ast_structure_input_#{$1}") do
        assert_generates(result, input, "Mismatch in #{resultname}")
      end
    end

    def test_ast_structure_paragraphs
        assert_generates "WikiAST[0, 4]\n    ParagraphAST[0, 4]\n        TextAST[0, 4]: None \n",
                         "text"
        assert_generates "WikiAST[0, 14]\n    ParagraphAST[0, 5]\n        TextAST[0, 5]: None \n    SectionAST[5, 9]\n        TextAST[6, 7]: None \n",
                         "text\n=heading="
        assert_generates "WikiAST[0, 15]\n    ParagraphAST[0, 6]\n        TextAST[0, 6]: None \n    SectionAST[6, 9]\n        TextAST[7, 7]: None \n",
                         "text\n\n=heading="
        assert_generates "WikiAST[0, 17]\n    ParagraphAST[0, 8]\n        TextAST[0, 8]: None \n    SectionAST[8, 9]\n        TextAST[9, 7]: None \n",
                         "text\r\n\r\n=heading="
    end

    def test_ast_structure_formatting
        assert_generates "WikiAST[0, 10]\n    ParagraphAST[0, 10]\n        FormattedAST[0, 10]\n            TextAST[2, 6]: None \n",
                         "''italic''"
        assert_generates "WikiAST[0, 10]\n    ParagraphAST[0, 10]\n        FormattedAST[0, 10]\n            TextAST[3, 4]: None \n",
                         "'''bold'''"
        assert_generates "WikiAST[0, 26]\n    ParagraphAST[0, 26]\n        FormattedAST[0, 26]\n            TextAST[2, 6]: None \n            FormattedAST[8, 10]\n                TextAST[11, 4]: None \n            TextAST[18, 6]: None \n",
                         "''italic'''bold'''italic''"
        assert_generates "WikiAST[0, 10]\n    ParagraphAST[0, 10]\n        FormattedAST[0, 10]\n            TextAST[2, 8]: None \n",
                         "''italic\n\n"
    end

    def test_ast_structure_headings
        assert_generates "WikiAST[0, 9]\n    SectionAST[0, 9]\n        TextAST[1, 7]: None \n",
                         "=heading="
        assert_generates "WikiAST[0, 11]\n    SectionAST[0, 11]\n        TextAST[2, 7]: None \n",
                         "==heading=="
        assert_generates "WikiAST[0, 13]\n    SectionAST[0, 8]\n        TextAST[1, 7]: None \n    ParagraphAST[8, 5]\n        TextAST[9, 4]: None \n",
                         "=heading=text"
        assert_generates "WikiAST[0, 14]\n    SectionAST[0, 9]\n        TextAST[2, 7]: None \n    ParagraphAST[9, 5]\n        TextAST[9, 5]: None \n",
                         "==heading\ntext"
    end

    def test_ast_structure_inline_links
        assert_generates "WikiAST[0, 18]\n    ParagraphAST[0, 18]\n        LinkAST[0, 18]\n",
                         "http://example.com"
        assert_generates "WikiAST[0, 28]\n    ParagraphAST[0, 28]\n        LinkAST[0, 18]\n        FormattedAST[18, 10]\n            TextAST[20, 6]: None \n",
                         "http://example.com''italic''"
        assert_generates "WikiAST[0, 22]\n    SectionAST[0, 22]\n        TextAST[1, 1]: None \n        LinkAST[2, 18]\n        TextAST[20, 1]: None \n",
                         "= http://example.com ="
        assert_generates "WikiAST[0, 49]\n    ParagraphAST[0, 49]\n        LinkAST[0, 49]\n",
                         "http://example.com/SpecialCharacters%C3%A7%C3%A3o"
    end

    def test_ast_structure_links
        assert_generates "WikiAST[0, 2]\n    ParagraphAST[0, 2]\n        TextAST[0, 2]: None \n",
                         "[]"
        assert_generates "WikiAST[0, 3]\n    ParagraphAST[0, 3]\n        TextAST[0, 3]: None \n",
                         "[ ]"
        assert_generates "WikiAST[0, 20]\n    ParagraphAST[0, 20]\n        LinkAST[0, 20]\n",
                         "[http://example.com]"
        assert_generates "WikiAST[0, 31]\n    ParagraphAST[0, 31]\n        LinkAST[0, 31]\n            FormattedAST[20, 10]\n                TextAST[22, 6]: None \n",
                         "[http://example.com ''italic'']"
        assert_generates "WikiAST[0, 18]\n    ParagraphAST[0, 18]\n        InternalLinkAST[0, 18]\n            TextAST[10, 6]\n",
                         "[[example|option]]"
        assert_generates "WikiAST[0, 27]\n    ParagraphAST[0, 27]\n        InternalLinkAST[0, 27]\n            TextAST[10, 15]\n",
                         "[[example|option1|option2]]"
        assert_generates "WikiAST[0, 36]\n    ParagraphAST[0, 36]\n        ResourceLinkAST[0, 36]\n            InternalLinkItemAST[0, 36]\n                TextAST[19, 7]: None \n            InternalLinkItemAST[0, 36]\n                TextAST[27, 7]: None \n",
                         "[[resource:example|option1|option2]]"
        assert_generates "WikiAST[0, 28]\n    ParagraphAST[0, 28]\n        ResourceLinkAST[0, 28]\n            InternalLinkItemAST[0, 28]\n                TextAST[20, 6]: None \n",
                         "[[resource:example||option]]"
    end

    def test_ast_structure_table
        assert_generates "WikiAST[0, 5]\n    TableAST[0, 5]\n",
                         "{|\n|}"
        assert_generates "WikiAST[0, 11]\n    TableAST[0, 11]\n        TableRowAST[0, 11]\n            TableCellAST[3, 6]\n                TextAST[4, 1]: None \n            TableCellAST[3, 6]\n                TextAST[7, 2]: None \n",
                         "{|\n|a||b\n|}"
        assert_generates "WikiAST[0, 14]\n    TableAST[0, 14]\n        TableRowAST[0, 14]\n            TableCellAST[3, 3]\n                TextAST[4, 2]: None \n        TableRowAST[0, 14]\n            TableCellAST[6, 6]\n                TextAST[10, 2]: None \n",
                         "{|\n|a\n|-\n|b\n|}"
        assert_generates "WikiAST[0, 27]\n    TableAST[0, 27]\n        TableRowAST[0, 27]\n            TableCellAST[3, 3]\n                TextAST[4, 2]: None \n        TableRowAST[0, 27]\n            TableCellAST[6, 19]\n                TextAST[23, 2]: None \n",
                         "{|\n|a\n|- align='left'\n|b\n|}"
    end

    def test_ast_structure_preformatted
        assert_generates "WikiAST[0, 3]\n    ParagraphAST[0, 3]\n        TextAST[0, 3]: None \n",
                         "  \n"
        assert_generates "WikiAST[0, 11]\n    ParagraphAST[0, 5]\n        TextAST[0, 5]: None \n    PreformattedAST[5, 6]\n        TextAST[5, 6]: None \n",
                         "text\n text\n"
        assert_generates "WikiAST[0, 11]\n    ParagraphAST[0, 5]\n        TextAST[0, 5]: None \n    PreformattedAST[5, 6]\n        TextAST[5, 6]: None \n",
                         "text\n text\n"
        assert_generates "WikiAST[0, 12]\n    PreformattedAST[0, 12]\n        TextAST[0, 1]: None \n        FormattedAST[1, 10]\n            TextAST[3, 6]: None \n        TextAST[11, 1]: None \n",
                         " ''italic''\n"
    end

    def test_ast_structure_hline
        assert_generates "WikiAST[0, 9]\n    ParagraphAST[0, 5]\n        TextAST[0, 5]: None \n    TextAST[5, 4]: HLine \n",
                         "text\n----"
        assert_generates "WikiAST[0, 10]\n    ParagraphAST[0, 6]\n        TextAST[0, 6]: None \n    TextAST[6, 4]: HLine \n",
                         "text\r\n----"
        assert_generates "WikiAST[0, 9]\n    TextAST[0, 4]: HLine \n    ParagraphAST[4, 5]\n        TextAST[4, 5]: None \n",
                         "----\ntext"
        assert_generates "WikiAST[0, 10]\n    TextAST[0, 4]: HLine \n    ParagraphAST[4, 2]\n        TextAST[4, 2]: None \n    ParagraphAST[6, 4]\n        TextAST[6, 4]: None \n",
                         "----\n\ntext"
    end

    def test_ast_structure_nowiki
        assert_generates "WikiAST[0, 18]\n    ParagraphAST[0, 27]\n        TextAST[8, 10]: None \n",
                         "<nowiki>''italic''</nowiki>"
        assert_generates "WikiAST[0, 18]\n    ParagraphAST[0, 35]\n        TextAST[0, 18]: None \n",
                         "text<nowiki>''italic''</nowiki>text"
        assert_generates "WikiAST[0, 18]\n    ParagraphAST[0, 27]\n        TextAST[8, 10]: None \n",
                         "<nowiki><u>uuu</u></nowiki>"
        assert_generates "WikiAST[0, 8]\n    ParagraphAST[0, 17]\n        TextAST[0, 8]: None \n",
                         "text<nowiki/>text"
    end

    def test_ast_structure_xhtml_markup
        assert_generates "WikiAST[0, 13]\n    ParagraphAST[0, 13]\n        ElementAST[0, 13]\n            TextAST[4, 4]: None \n",
                         "<tt>text</tt>"
        assert_generates "WikiAST[0, 5]\n    ParagraphAST[0, 5]\n        ElementAST[0, 5]\n",
                         "<tt/>"
        assert_generates "WikiAST[0, 24]\n    ParagraphAST[0, 24]\n        ElementAST[0, 24]\n            TextAST[15, 4]: None \n",
                         "<tt class='tt'>text</tt>"
        assert_generates "WikiAST[0, 16]\n    ParagraphAST[0, 16]\n        ElementAST[0, 16]\n            TextAST[4, 7]: None \n",
                         "<tt>\n\ntext\n</tt>"
        assert_generates "WikiAST[0, 29]\n    ParagraphAST[0, 29]\n        ElementAST[0, 29]\n            PasteAST[4, 20]\n                TextAST[11, 5]: None \n",
                         "<tt><paste>paste</paste></tt>"
        assert_generates "WikiAST[0, 34]\n    ParagraphAST[0, 34]\n        LinkAST[0, 34]\n            ElementAST[20, 13]\n                TextAST[24, 4]: None \n",
                         "[http://example.com <tt>text</tt>]"
    end

    def test_ast_structure_lists
        assert_generates "WikiAST[0, 2]\n    ListAST[0, 2]: ListAST \n        ListItemAST[0, 2]\n            TextAST[1, 1]: None \n",
                         "*a"
        assert_generates "WikiAST[0, 3]\n    ListAST[0, 3]: ListAST \n        ListItemAST[0, 3]\n            TextAST[1, 2]: None \n",
                         "*a\n"
        assert_generates "WikiAST[0, 10]\n    ListAST[0, 10]: ListAST \n        ListItemAST[0, 7]\n            TextAST[1, 2]: None \n            ListAST[3, 4]: ListAST \n                ListItemAST[3, 4]\n                    TextAST[5, 2]: None \n        ListItemAST[7, 3]\n            TextAST[8, 2]: None \n",
                         "*a\n**i\n*b\n"
        assert_generates "WikiAST[0, 7]\n    ListAST[0, 7]: ListAST \n        ListItemAST[0, 4]\n            ListAST[1, 3]: ListAST \n                ListItemAST[1, 3]\n                    TextAST[2, 2]: None \n        ListItemAST[4, 3]\n            TextAST[5, 2]: None \n",
                         "**i\n*b\n"
        assert_generates "WikiAST[0, 2]\n    ListAST[0, 2]: ListAST \n        ListItemAST[0, 2]\n            TextAST[1, 1]: None \n",
                         "#a"
        assert_generates "WikiAST[0, 3]\n    ListAST[0, 3]: ListAST \n        ListItemAST[0, 3]\n            TextAST[1, 2]: None \n",
                         "#a\n"
        assert_generates "WikiAST[0, 10]\n    ListAST[0, 10]: ListAST \n        ListItemAST[0, 7]\n            TextAST[1, 2]: None \n            ListAST[3, 4]: ListAST \n                ListItemAST[3, 4]\n                    TextAST[5, 2]: None \n        ListItemAST[7, 3]\n            TextAST[8, 2]: None \n",
                         "#a\n##i\n#b\n"
        assert_generates "WikiAST[0, 7]\n    ListAST[0, 7]: ListAST \n        ListItemAST[0, 4]\n            ListAST[1, 3]: ListAST \n                ListItemAST[1, 3]\n                    TextAST[2, 2]: None \n        ListItemAST[4, 3]\n            TextAST[5, 2]: None \n",
                         "##i\n#b\n"
        assert_generates "WikiAST[0, 6]\n    ListAST[0, 3]: ListAST \n        ListItemAST[0, 3]\n            TextAST[1, 2]: None \n    ListAST[3, 3]: ListAST \n        ListItemAST[3, 3]\n            TextAST[4, 2]: None \n",
                         "*a\n#b\n"
        assert_generates "WikiAST[0, 10]\n    ListAST[0, 10]: ListAST \n        ListItemAST[0, 7]\n            TextAST[1, 2]: None \n            ListAST[3, 4]: ListAST \n                ListItemAST[3, 4]\n                    TextAST[5, 2]: None \n        ListItemAST[7, 3]\n            TextAST[8, 2]: None \n",
                         "*a\n*#i\n*b\n"
        assert_generates "WikiAST[0, 2]\n    ListAST[0, 2]: ListAST \n        ListTermAST[0, 2]\n            TextAST[1, 1]: None \n",
                         ";a"
        assert_generates "WikiAST[0, 2]\n    ListAST[0, 2]: ListAST \n        ListDefinitionAST[0, 2]\n            TextAST[1, 1]: None \n",
                         ":b"
        assert_generates "WikiAST[0, 6]\n    ListAST[0, 3]: ListAST \n        ListTermAST[0, 3]\n            TextAST[1, 2]: None \n    ListAST[3, 3]: ListAST \n        ListTermAST[3, 3]\n            TextAST[4, 2]: None \n",
                         ";a\n;a\n"
        assert_generates "WikiAST[0, 7]\n    ListAST[0, 3]: ListAST \n        ListTermAST[0, 3]\n            TextAST[1, 2]: None \n    ParagraphAST[3, 4]\n        TextAST[3, 4]: None \n",
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

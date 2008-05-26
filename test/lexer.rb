require 'mediacloth/mediawikilexer'
require 'test/unit'
require 'testhelper'

class Lexer_Test < Test::Unit::TestCase

  include TestHelper
    
  def test_standard_formatted_input
    test_files("lex") { |input,result,resultname|
      lexer = MediaWikiLexer.new
      tokens = lexer.tokenize(input)
      assert_equal(result, tokens.to_s, "Mismatch in #{resultname}")
    }
  end
        
  def test_internet_formatted_input
    test_files("lex") { |input,result,resultname|
      lexer = MediaWikiLexer.new
      tokens = lexer.tokenize(input.gsub("\n", "\r\n"))
      assert_equal(result.gsub("\n", "\r\n"), tokens.to_s, "Mismatch in #{resultname}")
    }
  end
  
  def test_empty
    assert_equal([[false,false]], lex(""))
  end
  
  def test_paragraphs
    assert_equal(
      [[:PARA_START, ""], [:TEXT, "text"], [:PARA_END, ""], [false,false]],
      lex("text"))
    assert_equal(
      [[:PARA_START, ""], [:TEXT, "text\ntext"], [:PARA_END, ""], [false,false]],
      lex("text\ntext"))
    assert_equal(
      [[:PARA_START, ""], [:TEXT, "text\r\ntext"], [:PARA_END, ""], [false,false]],
      lex("text\r\ntext"))
    assert_equal(
      [[:PARA_START, ""], [:TEXT, "text\n\n"], [:PARA_END, ""], 
        [:PARA_START, ""], [:TEXT, "text"], [:PARA_END, ""], [false,false]],
      lex("text\n\ntext"))
    assert_equal(
      [[:PARA_START, ""], [:TEXT, "text\r\n\r\n"], [:PARA_END, ""], 
        [:PARA_START, ""], [:TEXT, "text"], [:PARA_END, ""], [false,false]],
      lex("text\r\n\r\ntext"))
    assert_equal(
      [[:PARA_START, ""], [:TEXT, "text\n\n"], [:PARA_END, ""], 
        [:PARA_START, ""], [:TEXT, "\ntext"], [:PARA_END, ""], [false,false]],
      lex("text\n\n\ntext"))
    assert_equal(
      [[:PARA_START, ""], [:TEXT, "text\n\n"], [:PARA_END, ""], [:PARA_START, ""],
        [:TEXT, "\n\n"], [:PARA_END, ""], [:PARA_START, ""], [:TEXT, "text"], [:PARA_END, ""],
        [false,false]],
      lex("text\n\n\n\ntext"))
    assert_equal(
      [[:PARA_START, ""], [:TEXT, "text\n"], [:PARA_END, ""],
        [:SECTION_START, "="], [:TEXT, "heading"], [:SECTION_END, "="], [false,false]],
      lex("text\n=heading="))
    assert_equal(
      [[:PARA_START, ""], [:TEXT, "text\r\n"], [:PARA_END, ""],
        [:SECTION_START, "="], [:TEXT, "heading"], [:SECTION_END, "="], [false,false]],
      lex("text\r\n=heading="))
    assert_equal(
      [[:SECTION_START, "="], [:TEXT, "heading"], [:SECTION_END, "="],
        [:PARA_START, ""], [:TEXT, "text"], [:PARA_END, ""], [false,false]],
      lex("=heading=\ntext"))
    assert_equal(
      [[:SECTION_START, "="], [:TEXT, "heading"], [:SECTION_END, "="],
        [:PARA_START, ""], [:TEXT, "text"], [:PARA_END, ""], [false,false]],
      lex("=heading=\r\ntext"))
    assert_equal(
      [[:PARA_START, ""], [:TEXT, "text\n\n"], [:PARA_END, ""],
        [:SECTION_START, "="], [:TEXT, "heading"], [:SECTION_END, "="], [false,false]],
      lex("text\n\n=heading="))
    assert_equal(
      [[:PARA_START, ""], [:TEXT, "text\r\n\r\n"], [:PARA_END, ""],
        [:SECTION_START, "="], [:TEXT, "heading"], [:SECTION_END, "="], [false,false]],
      lex("text\r\n\r\n=heading="))
  end
  
  def test_formatting
    assert_equal(
      [[:PARA_START, ""], [:ITALIC_START, "''"], [:TEXT, "italic"], [:ITALIC_END, "''"],
        [:PARA_END, ""], [false,false]],
      lex("''italic''"))
    assert_equal(
      [[:PARA_START, ""], [:BOLD_START, "'''"], [:TEXT, "bold"], [:BOLD_END, "'''"],
        [:PARA_END, ""], [false,false]],
      lex("'''bold'''"))
    assert_equal(
      [[:PARA_START, ""], [:ITALIC_START, "''"], [:TEXT, "italic"], [:BOLD_START, "'''"],
        [:TEXT, "bold"], [:BOLD_END, "'''"], [:TEXT, "italic"], [:ITALIC_END, "''"],
        [:PARA_END, ""], [false,false]],
      lex("''italic'''bold'''italic''"))
    assert_equal(
      [[:PARA_START, ""], [:ITALIC_START, "''"], [:BOLD_START, "'''"], 
        [:TEXT, "bolditalic"], [:BOLD_END, "'''"], [:ITALIC_END, "''"], 
        [:PARA_END, ""], [false,false]],
      lex("'''''bolditalic'''''"))
    assert_equal(
      [[:PARA_START, ""], [:ITALIC_START, "''"], [:TEXT, "italic\n\n"], [:ITALIC_END, ""],
        [:PARA_END, ""], [false,false]],
      lex("''italic\n\n"))
  end
  
  def test_headings
    assert_equal(
      [[:SECTION_START, "="], [:TEXT, "heading"], [:SECTION_END, "="], [false,false]],
      lex("=heading="))
    assert_equal(
      [[:SECTION_START, "=="], [:TEXT, "heading"], [:SECTION_END, "=="], [false,false]],
      lex("==heading=="))
    assert_equal(
      [[:SECTION_START, "=="], [:TEXT, " 1 <= 2 "], [:SECTION_END, "=="], [false,false]],
      lex("== 1 <= 2 =="))
    assert_equal(
      [[:SECTION_START, "=="], [:TEXT, "heading"], [:SECTION_END, "=="],
        [:PARA_START, ""], [:TEXT, "text"], [:PARA_END, ""], [false,false]],
      lex("==heading==text"))
    assert_equal(
      [[:SECTION_START, "="],  [:ITALIC_START, "''"], [:TEXT, "italic"], [:ITALIC_END, "''"],
        [:SECTION_END, "="], [false,false]],
      lex("=''italic''="))
    assert_equal(
      [[:SECTION_START, "=="], [:TEXT, "heading"], [:SECTION_END, ""], [:PARA_START, ""], 
        [:TEXT, "\n\n"], [:PARA_END, ''], [false,false]],
      lex("==heading\n\n"))
    assert_equal(
      [[:SECTION_START, "=="], [:TEXT, "heading"], [:SECTION_END, ""], [:PARA_START, ""], 
        [:TEXT, "\ntext"], [:PARA_END, ''], [false,false]],
      lex("==heading\ntext"))
  end
  
  def test_inline_links 
    assert_equal(
      [[:PARA_START, ""], [:LINK_START, ""], [:TEXT, "http://example.com"], [:LINK_END, ""],
        [:PARA_END, ""], [false, false]],
      lex("http://example.com"))
    assert_equal(
      [[:PARA_START, ""], [:LINK_START, ""], [:TEXT, "https://example.com"], [:LINK_END, ""],
        [:PARA_END, ""], [false, false]],
      lex("https://example.com"))
    assert_equal(
      [[:PARA_START, ""], [:LINK_START, ""], [:TEXT, "http://example.com"], [:LINK_END, ""],
        [:PARA_END, ""], [false, false]],
      lex("http://example.com\n"))
    assert_equal(
      [[:PARA_START, ""], [:LINK_START, ""], [:TEXT, "http://example.com"], [:LINK_END, ""],
        [:ITALIC_START, "''"], [:TEXT, "italic"], [:ITALIC_END, "''"], [:PARA_END, ""], [false, false]],
      lex("http://example.com''italic''"))
    assert_equal(
      [[:PARA_START, ""], [:TEXT, "http:notaurl"], [:PARA_END, ""], [false,false]],
      lex("http:notaurl"))
    assert_equal(
      [[:SECTION_START, "="], [:TEXT, " "], [:LINK_START, ""], [:TEXT, "http://example.com"],
        [:LINK_END, ""], [:TEXT, " "], [:SECTION_END, "="], [false, false]],
      lex("= http://example.com ="))
    assert_equal(
      [[:PARA_START, ""], [:LINK_START, ""], [:TEXT, "http://example.com/SpecialCharacters%C3%A7%C3%A3o"], [:LINK_END, ""],
        [:PARA_END, ""], [false, false]],
      lex("http://example.com/SpecialCharacters%C3%A7%C3%A3o"))
  end
  
  def test_links
    assert_equal(
      [[:PARA_START, ""], [:TEXT, "[]"], [:PARA_END, ""], [false, false]],
      lex("[]"))
    assert_equal(
      [[:PARA_START, ""], [:TEXT, "[ ]"], [:PARA_END, ""], [false, false]],
      lex("[ ]"))
    assert_equal(
      [[:PARA_START, ""], [:LINK_START, "["], [:TEXT, "http://example.com"], [:LINK_END, "]"],
        [:PARA_END, ""], [false, false]],
      lex("[http://example.com]"))
    assert_equal(
      [[:PARA_START, ""], [:LINK_START, "["], [:TEXT, "http://example.com"], [:LINK_END, "]"],
        [:PARA_END, ""], [false, false]],
      lex("[http://example.com ]"))
    assert_equal(
      [[:PARA_START, ""], [:LINK_START, "["], [:TEXT, "http://example.com"], [:LINK_END, "]"],
        [:PARA_END, ""], [false, false]],
      lex("[   http://example.com]"))
    assert_equal(
      [[:PARA_START, ""], [:LINK_START, "["], [:TEXT, "http://example.com"], [:LINKSEP, " "],
        [:TEXT, "example"], [:LINK_END, "]"], [:PARA_END, ""], [false, false]],
      lex("[http://example.com example]"))
    assert_equal(
      [[:PARA_START, ""], [:LINK_START, "["], [:TEXT, "http://example.com"], [:LINKSEP, " "],
        [:TEXT, "example"], [:LINK_END, "]"], [:PARA_END, ""], [false, false]],
      lex("[http://example.com    example]"))
    assert_equal(
      [[:PARA_START, ""], [:LINK_START, "["], [:TEXT, "http://example.com"], [:LINKSEP, " "],
        [:TEXT, "this is an example"], [:LINK_END, "]"], [:PARA_END, ""], [false, false]],
      lex("[http://example.com this is an example]"))
    assert_equal(
      [[:PARA_START, ""], [:LINK_START, "["], [:TEXT, "http://example.com"], [:LINKSEP, " "],
        [:ITALIC_START, "''"], [:TEXT, "italic"], [:ITALIC_END, "''"], [:LINK_END, "]"],
        [:PARA_END, ""], [false, false]],
      lex("[http://example.com ''italic'']"))
    assert_equal(
      [[:PARA_START, ""], [:LINK_START, "["], [:TEXT, "http://example.com"], [:LINKSEP, " "],
        [:TEXT, "[example"], [:LINK_END, "]"], [:PARA_END, ""], [false, false]],
      lex("[http://example.com [example]"))
    assert_equal(
      [[:PARA_START, ""], [:LINK_START, "["], [:TEXT, "http://example.com"], [:LINK_END, ""],
        [:TEXT, "\ntext"], [:PARA_END, ""], [false, false]],
      lex("[http://example.com\ntext"))
    assert_equal(
      [[:PARA_START, ""], [:TEXT, "[text]"], [:PARA_END, ""], [false,false]],
      lex("[text]"))
  end
  
  def test_internal_links
    assert_equal(
      [[:PARA_START, ""], [:TEXT, "[[]]"], [:PARA_END, ""], [false, false]],
      lex("[[]]"))
    assert_equal(
      [[:PARA_START, ""], [:INTLINK_START, "[["], [:TEXT, "example"], [:INTLINK_END, "]]"],
        [:PARA_END, ""], [false, false]],
      lex("[[example]]"))
    assert_equal(
      [[:PARA_START, ""], [:INTLINK_START, "[["], [:TEXT, "example page"], [:INTLINK_END, "]]"],
        [:PARA_END, ""], [false, false]],
      lex("[[example page]]"))
    assert_equal(
      [[:PARA_START, ""], [:INTLINK_START, "[["], [:TEXT, "example"], [:INTLINKSEP, "|"],
        [:TEXT, "option"], [:INTLINK_END, "]]"], [:PARA_END, ""], [false, false]],
      lex("[[example|option]]"))
    assert_equal(
      [[:PARA_START, ""], [:INTLINK_START, "[["], [:TEXT, "example"], [:INTLINKSEP, "|"],
        [:TEXT, "option1|option2"], [:INTLINK_END, "]]"], [:PARA_END, ""], [false, false]],
      lex("[[example|option1|option2]]"))
    assert_equal(
      [[:PARA_START, ""], [:INTLINK_START, "[["], [:TEXT, "resource"], [:RESOURCESEP, ":"], 
        [:TEXT, "example"], [:INTLINKSEP, "|"], [:TEXT, "option1"], [:INTLINKSEP, "|"],
        [:TEXT, "option2"], [:INTLINK_END, "]]"], [:PARA_END, ""], [false, false]],
      lex("[[resource:example|option1|option2]]"))
    assert_equal(
      [[:PARA_START, ""], [:INTLINK_START, "[["], [:TEXT, "resource"], [:RESOURCESEP, ":"], 
        [:TEXT, "example"], [:INTLINKSEP, "|"], [:TEXT, "this:that"], [:INTLINK_END, "]]"], 
        [:PARA_END, ""], [false, false]],
      lex("[[resource:example|this:that]]"))
    assert_equal(
      [[:PARA_START, ""], [:INTLINK_START, "[["], [:TEXT, "resource"], [:RESOURCESEP, ":"], 
        [:TEXT, "example"], [:INTLINKSEP, "|"],  [:INTLINK_START, "[["], [:TEXT, "link"],
        [:INTLINK_END, "]]"], [:INTLINK_END, "]]"], [:PARA_END, ""], [false, false]],
      lex("[[resource:example|[[link]]]]"))
    assert_equal(
      [[:PARA_START, ""], [:INTLINK_START, "[["], [:TEXT, "resource"], [:RESOURCESEP, ":"], 
        [:TEXT, "example"], [:INTLINKSEP, "|"], [:INTLINKSEP, "|"], [:TEXT, "option"],
        [:INTLINK_END, "]]"], [:PARA_END, ""], [false, false]],
      lex("[[resource:example||option]]"))
    assert_equal(
      [[:PARA_START, ""], [:INTLINK_START, "[["], [:TEXT, "example"], [:INTLINKSEP, "|"],
        [:TEXT, "option"], [:ITALIC_START, "''"], [:TEXT, "italic"], [:ITALIC_END, "''"],
        [:TEXT, "option"], [:INTLINK_END, "]]"], [:PARA_END, ""], [false, false]],
      lex("[[example|option''italic''option]]"))
    assert_equal(
      [[:PARA_START, ""], [:INTLINK_START, "[["], [:TEXT, "example"], [:INTLINKSEP, "|"],
        [:TEXT, "option[http://example.com]option"], [:INTLINK_END, "]]"], [:PARA_END, ""], [false, false]],
      lex("[[example|option[http://example.com]option]]"))
    assert_equal(
      [[:PARA_START, ""], [:INTLINK_START, "[["], [:TEXT, "example"], [:INTLINKSEP, "|"],
        [:TEXT, "option"], [:INTLINK_END, ""], [:TEXT, "\n\n"],  [:PARA_END, ""], [false, false]],
      lex("[[example|option\n\n"))
  end
  
  def test_table
    assert_equal([[:TABLE_START, "{|"], [:TABLE_END, "|}"], [false, false]],
      lex("{|\n|}"))
    assert_equal([[:TABLE_START, "{|"], [:TEXT, " width='100%'\n"], [:TABLE_END, "|}"],
        [false, false]],
      lex("{| width='100%'\n|}"))
    assert_equal([[:TABLE_START, "{|"], [:ROW_START, ""], [:CELL_START, "|"], [:TEXT, "a\n"], 
        [:CELL_END, ""], [:CELL_START, "|"], [:TEXT, "b\n"], [:CELL_END, ""], [:ROW_END, ""],
        [:TABLE_END, "|}"], [false, false]],
      lex("{|\n|a\n|b\n|}"))
    assert_equal([[:TABLE_START, "{|"], [:ROW_START, ""], [:CELL_START, "|"], [:TEXT, "a"], 
        [:CELL_END, ""], [:CELL_START, "||"], [:TEXT, "b\n"], [:CELL_END, ""], [:ROW_END, ""],
        [:TABLE_END, "|}"], [false, false]],
      lex("{|\n|a||b\n|}"))
    assert_equal([[:TABLE_START, "{|"], [:ROW_START, ""], [:CELL_START, "|"], [:TEXT, "a\n"], 
        [:CELL_END, ""], [:ROW_END, ""], [:ROW_START, "|-"], [:CELL_START, "|"], [:TEXT, "b\n"],
        [:CELL_END, ""], [:ROW_END, ""], [:TABLE_END, "|}"], [false, false]],
      lex("{|\n|a\n|-\n|b\n|}"))
    assert_equal([[:TABLE_START, "{|"], [:ROW_START, ""], [:CELL_START, "|"], [:TEXT, "a\n"], 
        [:CELL_END, ""], [:ROW_END, ""], [:ROW_START, "|-"], [:TEXT, " align='left'\n"], 
        [:CELL_START, "|"], [:TEXT, "b\n"], [:CELL_END, ""], [:ROW_END, ""], [:TABLE_END, "|}"],
        [false, false]],
      lex("{|\n|a\n|- align='left'\n|b\n|}"))
  end

  def test_preformatted
    assert_equal([[:PRE_START, ''], [:TEXT, " text\n"], [:PRE_END, ''], [false, false]],
      lex(" text\n"))
    assert_equal([[:PRE_START, ''], [:TEXT, " text\r\n"], [:PRE_END, ''], [false, false]],
      lex(" text\r\n"))
    assert_equal([[:PRE_START, ''], [:TEXT, " text\n text\n"], [:PRE_END, ''], [false, false]],
      lex(" text\n text\n"))
    assert_equal([[:PARA_START, ''], [:TEXT, "text\n"], [:PARA_END, ''], [:PRE_START, ''],
        [:TEXT, " text\n"], [:PRE_END, ''], [false, false]], 
      lex("text\n text\n"))
    assert_equal([[:PRE_START, ''], [:TEXT, " text\n"], [:PRE_END, ''], [:PARA_START, ''], 
        [:TEXT, "text\n"], [:PARA_END, ''], [false, false]], 
      lex(" text\ntext\n"))
    assert_equal([[:PRE_START, ''], [:TEXT, ' '], [:ITALIC_START, "''"], [:TEXT, "italic"], 
        [:ITALIC_END, "''"], [:TEXT, "\n"], [:PRE_END, ''], [false, false]],
      lex(" ''italic''\n"))
  end
  
  def test_hline
    assert_equal([[:HLINE, "----"], [false, false]], lex("----"))
    assert_equal([[:HLINE, "----"], [false, false]], lex("\n----"))
    assert_equal([[:HLINE, "----"], [false, false]], lex("\r\n----"))
    assert_equal([[:PARA_START, ""], [:TEXT, "text\n"], [:PARA_END, ""], [:HLINE, "----"], [false, false]], 
      lex("text\n----"))
    assert_equal([[:PARA_START, ""], [:TEXT, "text\r\n"], [:PARA_END, ""], [:HLINE, "----"], [false, false]], 
      lex("text\r\n----"))
    assert_equal([[:PARA_START, ""], [:TEXT, "text\n\n"], [:PARA_END, ""], [:HLINE, "----"], [false, false]], 
      lex("text\n\n----"))
    assert_equal([[:HLINE, "----"], [:PARA_START, ""], [:TEXT, "\ntext"], [:PARA_END, ""], [false, false]],
      lex("----\ntext"))
    assert_equal([[:HLINE, "----"], [:PARA_START, ""], [:TEXT, "\r\ntext"], [:PARA_END, ""], [false, false]],
      lex("----\r\ntext"))
    assert_equal([[:HLINE, "----"], [:PARA_START, ""], [:TEXT, "\n\n"], [:PARA_END, ""], [:PARA_START, ""], 
        [:TEXT, "text"], [:PARA_END, ""], [false, false]],
      lex("----\n\ntext"))
  end
  
  def test_nowiki
    assert_equal([[:PARA_START, ""], [:TEXT, "''italic''"], [:PARA_END, ""], [false, false]],
      lex("<nowiki>''italic''</nowiki>"))
    assert_equal([[:PARA_START, ""], [:TEXT, "text''italic''text"], [:PARA_END, ""], [false, false]],
      lex("text<nowiki>''italic''</nowiki>text"))
    assert_equal([[:PARA_START, ""], [:TEXT, "<u>uuu</u>"], [:PARA_END, ""], [false, false]],
      lex("<nowiki><u>uuu</u></nowiki>"))
  end
  
  def test_math
    assert_equal([[:PARA_START, ""], [:TAG_START, "math"], [:TEXT, "1 == 1 == 1"], [:TAG_END, "math"],
        [:PARA_END, ""], [false, false]],
      lex("<math>1 == 1 == 1</math>"))
  end
  
  def test_variable
    assert_equal([[:PARA_START, ""], [:VARIABLE_START, "{{"], [:TEXT, "ref"], [:VARIABLE_END, "}}"],
        [:PARA_END, ""], [false, false]],
      lex("{{ref}}"))
    assert_equal([[:PARA_START, ""], [:VARIABLE_START, "{{"], [:TEXT, "ref1}ref2"], [:VARIABLE_END, "}}"],
        [:PARA_END, ""], [false, false]],
      lex("{{ref1}ref2}}"))
    assert_equal([[:PARA_START, ""], [:VARIABLE_START, "{{"], [:TEXT, "ref1\n{|\n|not a table!\n|} "],
        [:VARIABLE_END, "}}"], [:PARA_END, ""], [false, false]],
      lex("{{ref1\n{|\n|not a table!\n|} }}"))
    assert_equal([[:PARA_START, ""], [:TEXT, "{{}}"], [:PARA_END, ""], [false, false]],
      lex("{{}}"))
    assert_equal([[:PARA_START, ""], [:VARIABLE_START, "{{"], [:TEXT, "xxx"], [:VARIABLE_START, "{{"], 
        [:TEXT, "iii"], [:VARIABLE_END, "}}"], [:TEXT, "xxx"], [:VARIABLE_END, "}}"],
        [:PARA_END, ""], [false, false]],
      lex("{{xxx{{iii}}xxx}}"))
  end
  
  def test_xhtml_markup
    assert_equal([[:PARA_START, ""], [:TAG_START, "tt"], [:TEXT, "text"], [:TAG_END, "tt"],
        [:PARA_END, ""], [false, false]],
      lex("<tt>text</tt>"))
    assert_equal([[:PARA_START, ""], [:TAG_START, "tt"], [:TAG_END, "tt"], [:PARA_END, ""], [false, false]],
      lex("<tt/>"))
    assert_equal([[:PARA_START, ""], [:TAG_START, "tt"], [:TAG_END, "tt"], [:PARA_END, ""], [false, false]],
      lex("<tt />"))
    assert_equal([[:PARA_START, ""], [:TEXT, "<123>"], [:PARA_END, ""], [false, false]],
      lex("<123>"))
    assert_equal([[:PARA_START, ""], [:TEXT, "<xx xx>"], [:PARA_END, ""], [false, false]],
      lex("<xx xx>"))
    assert_equal([[:PARA_START, ""], [:TEXT, "</xxx "], [:PARA_END, ""], [false, false]],
      lex("</xxx "))
    assert_equal([[:PARA_START, ""], [:TEXT, "<xx </xx>"], [:PARA_END, ""], [false, false]],
      lex("<xx </xx>"))
    assert_equal([[:PARA_START, ""], [:TEXT, "<xx a='b' c>"], [:PARA_END, ""], [false, false]],
      lex("<xx a='b' c>"))
    assert_equal([[:PARA_START, ""], [:TEXT, "<>"], [:PARA_END, ""], [false, false]],
      lex("<>"))
    assert_equal([[:PARA_START, ""], [:TAG_START, "tt"], [:ATTR_NAME, 'class'], [:ATTR_VALUE, 'tt'],
        [:TEXT, "text"], [:TAG_END, "tt"], [:PARA_END, ""], [false, false]],
      lex("<tt class='tt'>text</tt>"))
    assert_equal([[:PARA_START, ""], [:TAG_START, "tt"], [:ATTR_NAME, 'class'], [:ATTR_VALUE, 'tt'],
        [:TEXT, "text"], [:TAG_END, "tt"], [:PARA_END, ""], [false, false]],
      lex("<tt   class = 'tt' >text</tt >"))
    assert_equal([[:PARA_START, ""], [:TAG_START, "tt"], [:ATTR_NAME, 'class'], [:ATTR_VALUE, 'tt'],
        [:TEXT, "text"], [:TAG_END, "tt"], [:PARA_END, ""], [false, false]],
      lex("<tt\nclass\n=\n'tt'\n>text</tt\n>"))
    assert_equal([[:PARA_START, ""], [:TAG_START, "tt"], [:ATTR_NAME, 'class'], [:ATTR_VALUE, 'tt'],
        [:TAG_END, "tt"], [:PARA_END, ""], [false, false]],
      lex("<tt class='tt' />"))
    assert_equal([[:PARA_START, ""], [:TAG_START, "tt"], [:TEXT, "\ntext\n"], [:TAG_END, "tt"],
        [:PARA_END, ""], [false, false]],
      lex("<tt>\ntext\n</tt>"))
    assert_equal([[:PARA_START, ""], [:TAG_START, "tt"], [:TEXT, "\n\ntext\n"], [:TAG_END, "tt"],
        [:PARA_END, ""], [false, false]],
      lex("<tt>\n\ntext\n</tt>"))
    assert_equal([[:PARA_START, ""], [:TAG_START, "tt"], [:TEXT, "<tt/>"], [:TAG_END, "tt"],
        [:PARA_END, ""], [false, false]],
      lex("<tt><nowiki><tt/></nowiki></tt>"))
    assert_equal([[:PARA_START, ""], [:LINK_START, "["], [:TEXT, "http://example.com"], [:LINKSEP, " "],
        [:TAG_START, "tt"], [:TEXT, "text"], [:TAG_END, "tt"], [:LINK_END, "]"], [:PARA_END, ""], [false, false]],
      lex("[http://example.com <tt>text</tt>]"))
    assert_equal([[:PARA_START, ""], [:INTLINK_START, "[["], [:TEXT, "page"], [:INTLINKSEP, "|"],
        [:TAG_START, "tt"], [:TEXT, "text"], [:TAG_END, "tt"], [:INTLINK_END, "]]"], [:PARA_END, ""], [false, false]],
      lex("[[page|<tt>text</tt>]]"))
  end
  
  def test_xhtml_char_entities
    assert_equal([[:PARA_START, ""], [:CHAR_ENT, "lt"], [:PARA_END, ""], [false, false]],
      lex("&lt;"))
    assert_equal([[:PARA_START, ""], [:CHAR_ENT, "amp"], [:TEXT, "amp;"], [:PARA_END, ""], [false, false]],
      lex("&amp;amp;"))
    assert_equal([[:PARA_START, ""], [:TEXT, "&"], [:PARA_END, ""], [false, false]],
      lex("&"))
    assert_equal([[:PARA_START, ""], [:TEXT, "&amp"], [:PARA_END, ""], [false, false]],
      lex("&amp"))
    assert_equal([[:PARA_START, ""], [:TEXT, "&amp ;"], [:PARA_END, ""], [false, false]],
      lex("&amp ;"))
    assert_equal([[:PARA_START, ""], [:TEXT, "&amp amp;"], [:PARA_END, ""], [false, false]],
      lex("&amp amp;"))
    assert_equal([[:PARA_START, ""], [:TEXT, "&amp"], [:CHAR_ENT, "amp"], [:PARA_END, ""], [false, false]],
      lex("&amp&amp;"))
  end
  
  def test_unordered_lists
    assert_equal([[:UL_START, ''], [:LI_START, ''], [:TEXT, "a"], [:LI_END, ''], [:UL_END, ''],
        [false, false]],
      lex("*a"))
    assert_equal([[:UL_START, ''], [:LI_START, ''], [:TEXT, "a\n"], [:LI_END, ''], [:UL_END, ''],
        [false, false]],
      lex("*a\n"))
    assert_equal([[:UL_START, ''], [:LI_START, ''], [:TEXT, "a"], [:LI_END, ''], [:UL_END, ''],
        [false, false]],
      lex("\n*a"))
    assert_equal([[:PARA_START, ""], [:TEXT, "text\n"], [:PARA_END, ""], [:UL_START, ''], 
        [:LI_START, ''], [:TEXT, "a"], [:LI_END, ''], [:UL_END, ''], [false, false]],
      lex("text\n*a"))
    assert_equal([[:UL_START, ''], [:LI_START, ''], [:TEXT, "a\n"], [:LI_END, ''],
        [:LI_START, ''], [:TEXT, "b\n"], [:LI_END, ''], [:UL_END, ''], [false, false]],
      lex("*a\n*b\n"))
    assert_equal([[:UL_START, ''], [:LI_START, ''], [:TEXT, "a\n"],
        [:UL_START, ''], [:LI_START, ''], [:TEXT, "i\n"], [:LI_END, ''], [:UL_END, ''], [:LI_END, ''],
        [:LI_START, ''], [:TEXT, "b\n"], [:LI_END, ''], [:UL_END, ''], [false, false]],
      lex("*a\n**i\n*b\n"))
    assert_equal([[:UL_START, ''], [:LI_START, ''], [:TEXT, "a\n"],
        [:UL_START, ''], [:LI_START, ''], [:TEXT, "i\n"], [:LI_END, ''], [:UL_END, ''], [:LI_END, ''],
        [:UL_END, ''], [false, false]],
      lex("*a\n**i\n"))
    assert_equal([[:UL_START, ''], [:LI_START, ''], [:UL_START, ''],
        [:LI_START, ''], [:TEXT, "i\n"], [:LI_END, ''], [:UL_END, ''], [:LI_END, ''],
        [:UL_END, ''], [false, false]],
      lex("**i\n"))
    assert_equal([[:UL_START, ''], [:LI_START, ''], [:UL_START, ''],
        [:LI_START, ''], [:TEXT, "i\n"], [:LI_END, ''], [:UL_END, ''], [:LI_END, ''],
        [:LI_START, ''], [:TEXT, "b\n"], [:LI_END, ''], [:UL_END, ''], [false, false]],
      lex("**i\n*b\n"))
  end
  
  def test_ordered_lists
    assert_equal([[:OL_START, ''], [:LI_START, ''], [:TEXT, "a"], [:LI_END, ''], [:OL_END, ''],
        [false, false]],
      lex("#a"))
    assert_equal([[:OL_START, ''], [:LI_START, ''], [:TEXT, "a\n"], [:LI_END, ''], [:OL_END, ''],
        [false, false]],
      lex("#a\n"))
    assert_equal([[:OL_START, ''], [:LI_START, ''], [:TEXT, "a"], [:LI_END, ''], [:OL_END, ''],
        [false, false]],
      lex("\n#a"))
    assert_equal([[:PARA_START, ""], [:TEXT, "text\n"], [:PARA_END, ""], [:OL_START, ''], 
        [:LI_START, ''], [:TEXT, "a"], [:LI_END, ''], [:OL_END, ''], [false, false]],
      lex("text\n#a"))
    assert_equal([[:OL_START, ''], [:LI_START, ''], [:TEXT, "a\n"], [:LI_END, ''],
        [:LI_START, ''], [:TEXT, "b\n"], [:LI_END, ''], [:OL_END, ''], [false, false]],
      lex("#a\n#b\n"))
    assert_equal([[:OL_START, ''], [:LI_START, ''], [:TEXT, "a\n"],
        [:OL_START, ''], [:LI_START, ''], [:TEXT, "i\n"], [:LI_END, ''], [:OL_END, ''], [:LI_END, ''],
        [:LI_START, ''], [:TEXT, "b\n"], [:LI_END, ''], [:OL_END, ''], [false, false]],
      lex("#a\n##i\n#b\n"))
    assert_equal([[:OL_START, ''], [:LI_START, ''], [:TEXT, "a\n"],
        [:OL_START, ''], [:LI_START, ''], [:TEXT, "i\n"], [:LI_END, ''], [:OL_END, ''], [:LI_END, ''],
        [:OL_END, ''], [false, false]],
      lex("#a\n##i\n"))
    assert_equal([[:OL_START, ''], [:LI_START, ''], [:OL_START, ''],
        [:LI_START, ''], [:TEXT, "i\n"], [:LI_END, ''], [:OL_END, ''], [:LI_END, ''],
        [:OL_END, ''], [false, false]],
      lex("##i\n"))
    assert_equal([[:OL_START, ''], [:LI_START, ''], [:OL_START, ''],
        [:LI_START, ''], [:TEXT, "i\n"], [:LI_END, ''], [:OL_END, ''], [:LI_END, ''],
        [:LI_START, ''], [:TEXT, "b\n"], [:LI_END, ''], [:OL_END, ''], [false, false]],
      lex("##i\n#b\n"))
  end
  
  def test_mixed_lists
    assert_equal([[:UL_START, ''], [:LI_START, ''], [:TEXT, "a\n"], [:LI_END, ''], [:UL_END, ''],
        [:OL_START, ''], [:LI_START, ''], [:TEXT, "b\n"], [:LI_END, ''], [:OL_END, ''], [false, false]],
      lex("*a\n#b\n"))
    assert_equal([[:OL_START, ''], [:LI_START, ''], [:TEXT, "a\n"],
        [:UL_START, ''], [:LI_START, ''], [:TEXT, "i\n"], [:LI_END, ''], [:UL_END, ''], [:LI_END, ''],
        [:LI_START, ''], [:TEXT, "b\n"], [:LI_END, ''], [:OL_END, ''], [false, false]],
      lex("#a\n#*i\n#b\n"))
    assert_equal([[:UL_START, ''], [:LI_START, ''], [:TEXT, "a\n"],
        [:OL_START, ''], [:LI_START, ''], [:TEXT, "i\n"], [:LI_END, ''], [:OL_END, ''], [:LI_END, ''],
        [:LI_START, ''], [:TEXT, "b\n"], [:LI_END, ''], [:UL_END, ''], [false, false]],
      lex("*a\n*#i\n*b\n"))
  end
  
  def test_definition_lists
    assert_equal([[:DL_START, ''], [:DT_START, ';'], [:TEXT, "a"], [:DT_END, ''], [:DL_END, ''],
        [false, false]],
      lex(";a"))
    assert_equal([[:DL_START, ''], [:DT_START, ';'], [:TEXT, "a\n"], [:DT_END, ''], [:DL_END, ''],
        [false, false]],
      lex(";a\n"))
    assert_equal([[:DL_START, ''], [:DD_START, ':'], [:TEXT, "b"], [:DD_END, ''], [:DL_END, ''],
        [false, false]],
      lex(":b"))
    assert_equal([[:DL_START, ''], [:DD_START, ':'], [:TEXT, "b\n"], [:DD_END, ''], [:DL_END, ''],
        [false, false]],
      lex(":b\n"))
    assert_equal([[:DL_START, ''], [:DT_START, ';'], [:TEXT, "a\n"], [:DT_END, ''],
        [:DD_START, ':'], [:TEXT, "b\n"], [:DD_END, ''], [:DL_END, ''], [false, false]],
      lex(";a\n:b\n"))
    assert_equal([[:DL_START, ''], [:DT_START, ';'], [:TEXT, "a"], [:DT_END, ''],
        [:DD_START, ':'], [:TEXT, "b\n"], [:DD_END, ''], [:DL_END, ''], [false, false]],
      lex(";a:b\n"))
    assert_equal([[:DL_START, ''], [:DT_START, ';'], [:TEXT, "a\n"], [:DT_END, ''],
        [:DD_START, ':'], [:TEXT, "b\n"], [:DD_END, ''], [:DD_START, ':'], [:TEXT, "c\n"],
        [:DD_END, ''],[:DL_END, ''], [false, false]],
      lex(";a\n:b\n:c\n"))
    assert_equal([[:DL_START, ''], [:DT_START, ';'], [:TEXT, "a\n"], [:DT_END, ''], [:DL_END, ''],
        [:DL_START, ''], [:DT_START, ';'], [:TEXT, "a\n"], [:DT_END, ''], [:DL_END, ''],
        [false, false]],
      lex(";a\n;a\n"))
    assert_equal([[:DL_START, ''], [:DT_START, ';'], [:TEXT, "a\n"], [:DT_END, ''], [:DL_END, ''], 
        [:PARA_START, ''], [:TEXT, 'text'], [:PARA_END, ''], [false, false]],
      lex(";a\ntext"))
    assert_equal([[:DL_START, ''], [:DT_START, ';'], [:TEXT, "a"], [:DT_END, ''],
        [:DD_START, ':'], [:INTLINK_START, '[['], [:TEXT, "resource"], [:RESOURCESEP, ':'],
        [:TEXT, 'text'], [:INTLINK_END, ']]'], [:DD_END, ''], [:DL_END, ''], [false, false]],
      lex(";a:[[resource:text]]\n"))
  end

  
  private
  
  def lex(string)
    lexer = MediaWikiLexer.new
    lexer.tokenize(string)
  end

end

require 'mediacloth/mediawikilexer'
require 'test/unit'
require 'testhelper'

class Lexer_Test < Test::Unit::TestCase

  class << self
    include TestHelper
  end

  test_files("lex") do |input,result,resultname|
    resultname =~ /([0-9]+)$/
    define_method("test_win_unix_le_formatted_input_#{$1}") do
      lexer_unix = MediaWikiLexer.new
      tokens_unix = lexer_unix.tokenize(input)
      lexer_win = MediaWikiLexer.new
      tokens_win = lexer_win.tokenize(input.gsub("\n", "\r\n"))

      tokens_unix_check = []
      tokens_unix.each do
          |token|
          tokens_unix_check << token[0,1]
      end

      tokens_win_check = []
      tokens_win.each do
          |token|
          tokens_win_check << token[0,1]
      end
      assert_equal(tokens_unix_check, tokens_win_check, "Mismatch in #{resultname}")
    end
  end

  test_files("lex") do |input,result,resultname|
    resultname =~ /([0-9]+)$/
    define_method("test_internet_formatted_input_#{$1}") do
      lexer = MediaWikiLexer.new
      tokens = lexer.tokenize(input)
      assert_equal(result, tokens.to_s, "Mismatch in #{resultname}")
    end
  end

  def test_empty
    assert_equal([[false,false,0,0]], lex(""))
  end
  
  def test_paragraphs
    assert_equal(
      [[:PARA_START, "", 0, 0], [:TEXT, "text", 0, 4], [:PARA_END, "", 4, 0], [false,false, 4, 0]],
      lex("text"))
    assert_equal(
      [[:PARA_START, "", 0, 0], [:TEXT, "text\ntext", 0, 9], [:PARA_END, "", 9, 0], [false,false, 9, 0]],
      lex("text\ntext"))
    assert_equal(
      [[:PARA_START, "", 0, 0], [:TEXT, "text\r\ntext", 0, 10], [:PARA_END, "", 10, 0], [false,false, 10, 0]],
      lex("text\r\ntext"))
    assert_equal(
      [[:PARA_START, "", 0, 0], [:TEXT, "text\n\n", 0, 6], [:PARA_END, "", 6, 0], 
        [:PARA_START, "", 6, 0], [:TEXT, "text", 6, 4], [:PARA_END, "", 10, 0], [false,false, 10, 0]],
      lex("text\n\ntext"))
    assert_equal(
      [[:PARA_START, "", 0, 0], [:TEXT, "text\r\n\r\n", 0, 8], [:PARA_END, "", 8, 0], 
        [:PARA_START, "", 8, 0], [:TEXT, "text", 8, 4], [:PARA_END, "", 12, 0], [false,false, 12, 0]],
      lex("text\r\n\r\ntext"))
    assert_equal(
      [[:PARA_START, "", 0, 0], [:TEXT, "text\n\n", 0, 6], [:PARA_END, "", 6, 0], 
        [:PARA_START, "", 6, 0], [:TEXT, "\ntext", 6, 5], [:PARA_END, "", 11, 0], [false,false, 11, 0]],
      lex("text\n\n\ntext"))
    assert_equal(
      [[:PARA_START, "", 0, 0], [:TEXT, "text\n\n", 0, 6], [:PARA_END, "", 6, 0], [:PARA_START, "", 6, 0],
        [:TEXT, "\n\n", 6, 2], [:PARA_END, "", 8, 0], [:PARA_START, "", 8, 0], [:TEXT, "text", 8, 4], [:PARA_END, "", 12, 0],
        [false,false, 12, 0]],
      lex("text\n\n\n\ntext"))
    assert_equal(
      [[:PARA_START, "", 0, 0], [:TEXT, "text\n", 0, 5], [:PARA_END, "", 5, 0],
        [:SECTION_START, "=", 5, 1], [:TEXT, "heading", 6, 7], [:SECTION_END, "=", 13, 1], [false,false, 14, 0]],
      lex("text\n=heading="))
    assert_equal(
      [[:PARA_START, "", 0, 0], [:TEXT, "text\r\n", 0, 6], [:PARA_END, "", 6, 0],
        [:SECTION_START, "=", 6, 1], [:TEXT, "heading", 7, 7], [:SECTION_END, "=", 14, 1], [false,false, 15, 0]],
      lex("text\r\n=heading="))
    assert_equal(
      [[:SECTION_START, "=", 0, 1], [:TEXT, "heading", 1, 7], [:SECTION_END, "=", 8, 0],
        [:PARA_START, "", 8, 2], [:TEXT, "text", 10, 4], [:PARA_END, "", 14, 0], [false,false, 14, 0]],
      lex("=heading=\ntext"))
    assert_equal(
      [[:SECTION_START, "=", 0, 1], [:TEXT, "heading", 1, 7], [:SECTION_END, "=", 8, 0],
        [:PARA_START, "", 8, 3], [:TEXT, "text", 11, 4], [:PARA_END, "", 15, 0], [false,false, 15, 0]],
      lex("=heading=\r\ntext"))
    assert_equal(
      [[:PARA_START, "", 0, 0], [:TEXT, "text\n\n", 0, 6], [:PARA_END, "", 6, 0],
        [:SECTION_START, "=", 6, 1], [:TEXT, "heading", 7, 7], [:SECTION_END, "=", 14, 1], [false,false, 15, 0]],
      lex("text\n\n=heading="))
    assert_equal(
      [[:PARA_START, "", 0, 0], [:TEXT, "text\r\n\r\n", 0, 8], [:PARA_END, "", 8, 0],
        [:SECTION_START, "=", 8, 1], [:TEXT, "heading", 9, 7], [:SECTION_END, "=", 16, 1], [false,false, 17, 0]],
      lex("text\r\n\r\n=heading="))
  end
  
  def test_formatting
    assert_equal(
      [[:PARA_START, "", 0, 0], [:ITALIC_START, "''", 0, 2], [:TEXT, "italic", 2, 6], [:ITALIC_END, "''", 8, 2],
        [:PARA_END, "", 10, 0], [false,false, 10, 0]],
      lex("''italic''"))
    assert_equal(
      [[:PARA_START, "", 0, 0], [:BOLD_START, "'''", 0, 3], [:TEXT, "bold", 3, 4], [:BOLD_END, "'''", 7, 3],
        [:PARA_END, "", 10, 0], [false,false, 10, 0]],
      lex("'''bold'''"))
    assert_equal(
      [[:PARA_START, "", 0, 0], [:ITALIC_START, "''", 0, 2], [:TEXT, "italic", 2, 6], [:BOLD_START, "'''", 8, 3],
        [:TEXT, "bold", 11, 4], [:BOLD_END, "'''", 15, 3], [:TEXT, "italic", 18, 6], [:ITALIC_END, "''", 24, 2],
        [:PARA_END, "", 26, 0], [false,false, 26, 0]],
      lex("''italic'''bold'''italic''"))
    assert_equal(
      [[:PARA_START, "", 0, 0], [:ITALIC_START, "''", 0, 2], [:BOLD_START, "'''", 2, 3], 
        [:TEXT, "bolditalic", 5, 10], [:BOLD_END, "'''", 15, 3], [:ITALIC_END, "''", 18, 2], 
        [:PARA_END, "", 20, 0], [false,false, 20, 0]],
      lex("'''''bolditalic'''''"))
    assert_equal(
      [[:PARA_START, "", 0, 0], [:ITALIC_START, "''", 0, 2], [:TEXT, "italic\n\n", 2, 8], [:ITALIC_END, "", 10, 0],
        [:PARA_END, "", 10, 0], [false,false, 10, 0]],
      lex("''italic\n\n"))
  end
  
  def test_headings
    assert_equal(
      [[:SECTION_START, "=", 0, 1], [:TEXT, "heading", 1, 7], [:SECTION_END, "=", 8, 1], [false,false, 9, 0]],
      lex("=heading="))
    assert_equal(
      [[:SECTION_START, "==", 0, 2], [:TEXT, "heading", 2, 7], [:SECTION_END, "==", 9, 2], [false,false, 11, 0]],
      lex("==heading=="))
    assert_equal(
      [[:SECTION_START, "==", 0, 2], [:TEXT, " 1 <= 2 ", 2, 8], [:SECTION_END, "==", 10, 2], [false,false, 12, 0]],
      lex("== 1 <= 2 =="))
    assert_equal(
      [[:SECTION_START, "==", 0, 2], [:TEXT, "heading", 2, 7], [:SECTION_END, "==", 9, 0],
        [:PARA_START, "", 9, 2], [:TEXT, "text", 11, 4], [:PARA_END, "", 15, 0], [false,false, 15, 0]],
      lex("==heading==text"))
    assert_equal(
      [[:SECTION_START, "=", 0, 1],  [:ITALIC_START, "''", 1, 2], [:TEXT, "italic", 3, 6], [:ITALIC_END, "''", 9, 2],
        [:SECTION_END, "=", 11, 1], [false,false, 12, 0]],
      lex("=''italic''="))
    assert_equal(
      [[:SECTION_START, "==", 0, 2], [:TEXT, "heading", 2, 7], [:SECTION_END, "", 9, 0], [:PARA_START, "", 9, 0], 
        [:TEXT, "\n\n", 9, 2], [:PARA_END, '', 11, 0], [false,false, 11, 0]],
      lex("==heading\n\n"))
    assert_equal(
      [[:SECTION_START, "==", 0, 2], [:TEXT, "heading", 2, 7], [:SECTION_END, "", 9, 0], [:PARA_START, "", 9, 0], 
        [:TEXT, "\ntext", 9, 5], [:PARA_END, '', 14, 0], [false,false, 14, 0]],
      lex("==heading\ntext"))
  end
  
  def test_inline_links 
    assert_equal(
      [[:PARA_START, "", 0, 0], [:LINK_START, "", 0, 0], [:TEXT, "http://example.com", 0, 18], [:LINK_END, "", 18, 0],
        [:PARA_END, "", 18, 0], [false, false, 18, 0]],
      lex("http://example.com"))
    assert_equal(
      [[:PARA_START, "", 0, 0], [:LINK_START, "", 0, 0], [:TEXT, "https://example.com", 0, 19], [:LINK_END, "", 19, 0],
        [:PARA_END, "", 19, 0], [false, false, 19, 0]],
      lex("https://example.com"))
    assert_equal(
      [[:PARA_START, "", 0, 0], [:LINK_START, "", 0, 0], [:TEXT, "http://example.com", 0, 18], [:LINK_END, "", 18, 1],
        [:PARA_END, "", 19, 0], [false, false, 19, 0]],
      lex("http://example.com\n"))
    assert_equal(
      [[:PARA_START, "", 0, 0], [:LINK_START, "", 0, 0], [:TEXT, "http://example.com", 0, 18], [:LINK_END, "", 18, 0],
        [:ITALIC_START, "''", 18, 2], [:TEXT, "italic", 20, 6], [:ITALIC_END, "''", 26, 2], [:PARA_END, "", 28, 0], [false, false, 28, 0]],
      lex("http://example.com''italic''"))
    assert_equal(
      [[:PARA_START, "", 0, 0], [:TEXT, "http:notaurl", 0, 12], [:PARA_END, "", 12, 0], [false,false, 12, 0]],
      lex("http:notaurl"))
    assert_equal(
      [[:SECTION_START, "=", 0, 1], [:TEXT, " ", 1, 1], [:LINK_START, "", 2, 0], [:TEXT, "http://example.com", 2, 18],
        [:LINK_END, "", 20, 0], [:TEXT, " ", 20, 1], [:SECTION_END, "=", 21, 1], [false, false, 22, 0]],
      lex("= http://example.com ="))
    assert_equal(
      [[:PARA_START, "", 0, 0], [:LINK_START, "", 0, 0], [:TEXT, "http://example.com/SpecialCharacters%C3%A7%C3%A3o", 0, 49], [:LINK_END, "", 49, 0],
        [:PARA_END, "", 49, 0], [false, false, 49, 0]],
      lex("http://example.com/SpecialCharacters%C3%A7%C3%A3o"))
  end
  
  def test_links
    assert_equal(
      [[:PARA_START, "", 0, 0], [:TEXT, "[]", 0, 2], [:PARA_END, "", 2, 0], [false, false, 2, 0]],
      lex("[]"))
    assert_equal(
      [[:PARA_START, "", 0, 0], [:TEXT, "[ ]", 0, 3], [:PARA_END, "", 3, 0], [false, false, 3, 0]],
      lex("[ ]"))
    assert_equal(
      [[:PARA_START, "", 0, 0], [:LINK_START, "[", 0, 1], [:TEXT, "http://example.com", 1, 18], [:LINK_END, "]", 19, 1],
        [:PARA_END, "", 20, 0], [false, false, 20, 0]],
      lex("[http://example.com]"))
    assert_equal(
      [[:PARA_START, "", 0, 0], [:LINK_START, "[", 0, 1], [:TEXT, "http://example.com", 1, 18], [:LINKSEP, " ", 19, 1],
        [:LINK_END, "]", 20, 1], [:PARA_END, "", 21, 0], [false, false, 21, 0]],
      lex("[http://example.com ]"))
    assert_equal(
      [[:PARA_START, "", 0, 0], [:LINK_START, "[", 0, 4], [:TEXT, "http://example.com", 4, 18], [:LINK_END, "]", 22, 1],
        [:PARA_END, "", 23, 0], [false, false, 23, 0]],
      lex("[   http://example.com]"))
    assert_equal(
      [[:PARA_START, "", 0, 0], [:LINK_START, "[", 0, 1], [:TEXT, "http://example.com", 1, 18], [:LINKSEP, " ", 19, 1],
        [:TEXT, "example", 20, 7], [:LINK_END, "]", 27, 1], [:PARA_END, "", 28, 0], [false, false, 28, 0]],
      lex("[http://example.com example]"))
    assert_equal(
      [[:PARA_START, "", 0, 0], [:LINK_START, "[", 0, 1], [:TEXT, "http://example.com", 1, 18], [:LINKSEP, " ", 19, 4],
        [:TEXT, "example", 23, 7], [:LINK_END, "]", 30, 1], [:PARA_END, "", 31, 0], [false, false, 31, 0]],
      lex("[http://example.com    example]"))
    assert_equal(
      [[:PARA_START, "", 0, 0], [:LINK_START, "[", 0, 1], [:TEXT, "http://example.com", 1, 18], [:LINKSEP, " ", 19, 1],
        [:TEXT, "this is an example", 20, 18], [:LINK_END, "]", 38, 1], [:PARA_END, "", 39, 0], [false, false, 39, 0]],
      lex("[http://example.com this is an example]"))
    assert_equal(
      [[:PARA_START, "", 0, 0], [:LINK_START, "[", 0, 1], [:TEXT, "http://example.com", 1, 18], [:LINKSEP, " ", 19, 1],
        [:ITALIC_START, "''", 20, 2], [:TEXT, "italic", 22, 6], [:ITALIC_END, "''", 28, 2], [:LINK_END, "]", 30, 1],
        [:PARA_END, "", 31, 0], [false, false, 31, 0]],
      lex("[http://example.com ''italic'']"))
    assert_equal(
      [[:PARA_START, "", 0, 0], [:LINK_START, "[", 0, 1], [:TEXT, "http://example.com", 1, 18], [:LINKSEP, " ", 19, 1],
        [:TEXT, "[example", 20, 8], [:LINK_END, "]", 28, 1], [:PARA_END, "", 29, 0], [false, false, 29, 0]],
      lex("[http://example.com [example]"))
    assert_equal(
      [[:PARA_START, "", 0, 0], [:LINK_START, "[", 0, 1], [:TEXT, "http://example.com", 1, 18], [:LINK_END, "", 19, 0],
        [:TEXT, "\ntext", 19, 5], [:PARA_END, "", 24, 0], [false, false, 24, 0]],
      lex("[http://example.com\ntext"))
    assert_equal(
      [[:PARA_START, "", 0, 0], [:TEXT, "[text]", 0, 6], [:PARA_END, "", 6, 0], [false,false, 6, 0]],
      lex("[text]"))
  end
  
  def test_internal_links
    assert_equal(
      [[:PARA_START, "", 0, 0], [:TEXT, "[[]]", 0, 4], [:PARA_END, "", 4, 0], [false, false, 4, 0]],
      lex("[[]]"))
    assert_equal(
      [[:PARA_START, "", 0, 0], [:INTLINK_START, "[[", 0, 2], [:TEXT, "example", 2, 7], [:INTLINK_END, "]]", 9, 2],
        [:PARA_END, "", 11, 0], [false, false, 11, 0]],
      lex("[[example]]"))
    assert_equal(
      [[:PARA_START, "", 0, 0], [:INTLINK_START, "[[", 0, 2], [:TEXT, "example page", 2, 12], [:INTLINK_END, "]]", 14, 2],
        [:PARA_END, "", 16, 0], [false, false, 16, 0]],
      lex("[[example page]]"))
    assert_equal(
      [[:PARA_START, "", 0, 0], [:INTLINK_START, "[[", 0, 2], [:TEXT, "example", 2, 7], [:INTLINKSEP, "|", 9, 1],
        [:TEXT, "option", 10, 6], [:INTLINK_END, "]]", 16, 2], [:PARA_END, "", 18, 0], [false, false, 18, 0]],
      lex("[[example|option]]"))
    assert_equal(
      [[:PARA_START, "", 0, 0], [:INTLINK_START, "[[", 0, 2], [:TEXT, "example", 2, 7], [:INTLINKSEP, "|", 9, 1],
        [:TEXT, "option1|option2", 10, 15], [:INTLINK_END, "]]", 25, 2], [:PARA_END, "", 27, 0], [false, false, 27, 0]],
      lex("[[example|option1|option2]]"))
    assert_equal(
      [[:PARA_START, "", 0, 0], [:INTLINK_START, "[[", 0, 2], [:TEXT, "resource", 2, 8], [:RESOURCESEP, ":", 10, 1],
        [:TEXT, "example", 11, 7], [:INTLINKSEP, "|", 18, 1], [:TEXT, "option1", 19, 7], [:INTLINKSEP, "|", 26, 1],
        [:TEXT, "option2", 27, 7], [:INTLINK_END, "]]", 34, 2], [:PARA_END, "", 36, 0], [false, false, 36, 0]],
      lex("[[resource:example|option1|option2]]"))
    assert_equal(
      [[:PARA_START, "", 0, 0], [:INTLINK_START, "[[", 0, 2], [:TEXT, "resource", 2, 8], [:RESOURCESEP, ":", 10, 1],
        [:TEXT, "example", 11, 7], [:INTLINKSEP, "|", 18, 1], [:TEXT, "this:that", 19, 9], [:INTLINK_END, "]]", 28, 2], 
        [:PARA_END, "", 30, 0], [false, false, 30, 0]],
      lex("[[resource:example|this:that]]"))
    assert_equal(
      [[:PARA_START, "", 0, 0], [:INTLINK_START, "[[", 0, 2], [:TEXT, "resource", 2, 8], [:RESOURCESEP, ":", 10, 1], 
        [:TEXT, "example", 11, 7], [:INTLINKSEP, "|", 18, 1],  [:INTLINK_START, "[[", 19, 2], [:TEXT, "link", 21, 4],
        [:INTLINK_END, "]]", 25, 2], [:INTLINK_END, "]]", 27, 2], [:PARA_END, "", 29, 0], [false, false, 29, 0]],
      lex("[[resource:example|[[link]]]]"))
    assert_equal(
      [[:PARA_START, "", 0, 0], [:INTLINK_START, "[[", 0, 2], [:TEXT, "resource", 2, 8], [:RESOURCESEP, ":", 10, 1], 
        [:TEXT, "example", 11, 7], [:INTLINKSEP, "|", 18, 1], [:INTLINKSEP, "|", 19, 1], [:TEXT, "option", 20, 6],
        [:INTLINK_END, "]]", 26, 2], [:PARA_END, "", 28, 0], [false, false, 28, 0]],
      lex("[[resource:example||option]]"))
    assert_equal(
      [[:PARA_START, "", 0, 0], [:INTLINK_START, "[[", 0, 2], [:TEXT, "example", 2, 7], [:INTLINKSEP, "|", 9, 1],
        [:TEXT, "option", 10, 6], [:ITALIC_START, "''", 16, 2], [:TEXT, "italic", 18, 6], [:ITALIC_END, "''", 24, 2],
        [:TEXT, "option", 26, 6], [:INTLINK_END, "]]", 32, 2], [:PARA_END, "", 34, 0], [false, false, 34, 0]],
      lex("[[example|option''italic''option]]"))
    assert_equal(
      [[:PARA_START, "", 0, 0], [:INTLINK_START, "[[", 0, 2], [:TEXT, "example", 2, 7], [:INTLINKSEP, "|", 9, 1],
        [:TEXT, "option[http://example.com]option", 10, 32], [:INTLINK_END, "]]", 42, 2], [:PARA_END, "", 44, 0], [false, false, 44, 0]],
      lex("[[example|option[http://example.com]option]]"))
    assert_equal(
      [[:PARA_START, "", 0, 0], [:INTLINK_START, "[[", 0, 2], [:TEXT, "example", 2, 7], [:INTLINKSEP, "|", 9, 1],
        [:TEXT, "option", 10, 6], [:INTLINK_END, "", 16, 0], [:TEXT, "\n\n", 16, 2],  [:PARA_END, "", 18, 0], [false, false, 18, 0]],
      lex("[[example|option\n\n"))
  end
  
  def test_table
    assert_equal([[:TABLE_START, "{|", 0, 3], [:TABLE_END, "|}", 3, 2], [false, false, 5, 0]],
      lex("{|\n|}"))
    assert_equal([[:TABLE_START, "{|", 0, 2], [:TEXT, " width='100%'\n", 2, 14], [:TABLE_END, "|}", 16, 2], [false, false, 18, 0]],
      lex("{| width='100%'\n|}"))
    assert_equal([[:TABLE_START, "{|", 0, 3], [:ROW_START, "", 3, 0], [:CELL_START, "|", 3, 1], [:TEXT, "a\n", 4, 2],
        [:CELL_END, "", 6, 0], [:CELL_START, "|", 6, 1], [:TEXT, "b\n", 7, 2], [:CELL_END, "", 9, 0], [:ROW_END, "", 9, 0],
        [:TABLE_END, "|}", 9, 2], [false, false, 11, 0]],
      lex("{|\n|a\n|b\n|}"))
    assert_equal([[:TABLE_START, "{|", 0, 3], [:ROW_START, "", 3, 0], [:CELL_START, "|", 3, 1], [:TEXT, "a", 4, 1],
        [:CELL_END, "", 5, 0], [:CELL_START, "||", 5, 2], [:TEXT, "b\n", 7, 2], [:CELL_END, "", 9, 0], [:ROW_END, "", 9, 0],
        [:TABLE_END, "|}", 9, 2], [false, false, 11, 0]],
      lex("{|\n|a||b\n|}"))
    assert_equal([[:TABLE_START, "{|", 0, 3], [:ROW_START, "", 3, 0], [:CELL_START, "|", 3, 1], [:TEXT, "a\n", 4, 2],
        [:CELL_END, "", 6, 0], [:ROW_END, "", 6, 0], [:ROW_START, "|-", 6, 3], [:CELL_START, "|", 9, 1], [:TEXT, "b\n", 10, 2],
        [:CELL_END, "", 12, 0], [:ROW_END, "", 12, 0], [:TABLE_END, "|}", 12, 2], [false, false, 14, 0]],
      lex("{|\n|a\n|-\n|b\n|}"))
    assert_equal([[:TABLE_START, "{|", 0, 3], [:ROW_START, "", 3, 0], [:CELL_START, "|", 3, 1], [:TEXT, "a\n", 4, 2],
        [:CELL_END, "", 6, 0], [:ROW_END, "", 6, 0], [:ROW_START, "|-", 6, 2], [:TEXT, " align='left'\n", 8, 14],
        [:CELL_START, "|", 22, 1], [:TEXT, "b\n", 23, 2], [:CELL_END, "", 25, 0], [:ROW_END, "", 25, 0], [:TABLE_END, "|}", 25, 2],
        [false, false, 27, 0]],
      lex("{|\n|a\n|- align='left'\n|b\n|}"))
    assert_equal([[:TABLE_START, "{|", 0, 3], [:ROW_START, "", 3, 0], [:CELL_START, "|", 3, 1], [:TEXT, "a\n", 4, 2],
        [:CELL_END, "", 6, 0], [:ROW_END, "", 6, 0], [:ROW_START, "|-", 6, 3], [:CELL_START, "|", 9, 1],
        [:TEXT, ' colspan="4" align="center" style="background:#ffdead;"', 10, 55], [:CELL_END, "attributes", 65, 0],
        [:CELL_START, "|", 65, 1], [:TEXT, " b\n", 66, 3], [:CELL_END, "", 69, 0], [:ROW_END, "", 69, 0], [:TABLE_END, "|}", 69, 2],
        [false, false, 71, 0]],
      lex("{|\n|a\n|-\n| colspan=\"4\" align=\"center\" style=\"background:#ffdead;\"| b\n|}"))
  end

  def test_preformatted
    assert_equal([[:PARA_START, '', 0, 0], [:TEXT, "  ", 0, 2], [:PARA_END, '', 2, 0], [false, false, 2, 0]],
      lex("  "))
    assert_equal([[:PARA_START, '', 0, 0], [:TEXT, "  \n", 0, 3], [:PARA_END, '', 3, 0], [false, false, 3, 0]],
      lex("  \n"))
    assert_equal([[:PARA_START, '', 0, 0], [:TEXT, "         \n", 0, 10], [:PARA_END, '', 10, 0], [false, false, 10, 0]],
      lex("         \n"))
    assert_equal([[:PRE_START, '', 0, 0], [:TEXT, " text\n", 0, 6], [:PRE_END, '', 6, 0], [false, false, 6, 0]],
      lex(" text\n"))
    assert_equal([[:PRE_START, '', 0, 0], [:TEXT, " text\r\n", 0, 7], [:PRE_END, '', 7, 0], [false, false, 7, 0]],
      lex(" text\r\n"))
    assert_equal([[:PRE_START, '', 0, 0], [:TEXT, " text\n text\n", 0, 12], [:PRE_END, '', 12, 0], [false, false, 12, 0]],
      lex(" text\n text\n"))
    assert_equal([[:PARA_START, '', 0, 0], [:TEXT, "text\n", 0, 5], [:PARA_END, '', 5, 0], [:PRE_START, '', 5, 0],
        [:TEXT, " text\n", 5, 6], [:PRE_END, '', 11, 0], [false, false, 11, 0]], 
      lex("text\n text\n"))
    assert_equal([[:PRE_START, '', 0, 0], [:TEXT, " text\n", 0, 6], [:PRE_END, '', 6, 0], [:PARA_START, '', 6, 0], 
        [:TEXT, "text\n", 6, 5], [:PARA_END, '', 11, 0], [false, false, 11, 0]], 
      lex(" text\ntext\n"))
    assert_equal([[:PRE_START, '', 0, 0], [:TEXT, ' ', 0, 1], [:ITALIC_START, "''", 1, 2], [:TEXT, "italic", 3, 6], 
        [:ITALIC_END, "''", 9, 2], [:TEXT, "\n", 11, 1], [:PRE_END, '', 12, 0], [false, false, 12, 0]],
      lex(" ''italic''\n"))
  end
  
  def test_hline
    assert_equal([[:HLINE, "----", 0, 4], [false, false, 4, 0]], lex("----"))
    assert_equal([[:HLINE, "----", 1, 4], [false, false, 5, 0]], lex("\n----"))
    assert_equal([[:HLINE, "----", 2, 4], [false, false, 6, 0]], lex("\r\n----"))
    assert_equal([[:PARA_START, "", 0, 0], [:TEXT, "text\n", 0, 5], [:PARA_END, "", 5, 0], [:HLINE, "----", 5, 4], [false, false, 9, 0]], 
      lex("text\n----"))
    assert_equal([[:PARA_START, "", 0, 0], [:TEXT, "text\r\n", 0, 6], [:PARA_END, "", 6, 0], [:HLINE, "----", 6, 4], [false, false, 10, 0]], 
      lex("text\r\n----"))
    assert_equal([[:PARA_START, "", 0, 0], [:TEXT, "text\n\n", 0, 6], [:PARA_END, "", 6, 0], [:HLINE, "----", 6, 4], [false, false, 10, 0]], 
      lex("text\n\n----"))
    assert_equal([[:HLINE, "----", 0, 4], [:PARA_START, "", 4, 0], [:TEXT, "\ntext", 4, 5], [:PARA_END, "", 9, 0], [false, false, 9, 0]],
      lex("----\ntext"))
    assert_equal([[:HLINE, "----", 0, 4], [:PARA_START, "", 4, 0], [:TEXT, "\r\ntext", 4, 6], [:PARA_END, "", 10, 0], [false, false, 10, 0]],
      lex("----\r\ntext"))
    assert_equal([[:HLINE, "----", 0, 4], [:PARA_START, "", 4, 0], [:TEXT, "\n\n", 4, 2], [:PARA_END, "", 6, 0], [:PARA_START, "", 6, 0], 
        [:TEXT, "text", 6, 4], [:PARA_END, "", 10, 0], [false, false, 10, 0]],
      lex("----\n\ntext"))
  end
  
  def test_nowiki
    assert_equal([[:PARA_START, "", 0, 8], [:TEXT, "''italic''", 8, 10], [:PARA_END, "", 27, 0], [false, false, 27, 0]],
      lex("<nowiki>''italic''</nowiki>"))
    assert_equal([[:PARA_START, "", 0, 0], [:TEXT, "text''italic''text", 0, 18], [:PARA_END, "", 35, 0], [false, false, 35, 0]],
      lex("text<nowiki>''italic''</nowiki>text"))
    assert_equal([[:PARA_START, "", 0, 8], [:TEXT, "<u>uuu</u>", 8, 10], [:PARA_END, "", 27, 0], [false, false, 27, 0]],
      lex("<nowiki><u>uuu</u></nowiki>"))
    assert_equal([[:PARA_START, "", 0, 0], [:TEXT, "texttext", 0, 8], [:PARA_END, "", 17, 0], [false, false, 17, 0]],
      lex("text<nowiki/>text"))
  end
  
  def test_math
    assert_equal([[:PARA_START, "", 0, 0], [:TAG_START, "math", 0, 6], [:TEXT, "1 == 1 == 1", 6, 11], [:TAG_END, "math", 17, 7],
        [:PARA_END, "", 24, 0], [false, false, 24, 0]],
      lex("<math>1 == 1 == 1</math>"))
    assert_equal([[:PARA_START, "", 0, 0], [:TAG_START, "math", 0, 6], [:TEXT, "1 == 1", 6, 6], [:TAG_END, "math", 12, 7],
        [:TEXT, "xxx", 19, 3], [:TAG_START, "math", 22, 6], [:TEXT, "1 == 1", 28, 6], [:TAG_END, "math", 34, 7],
        [:PARA_END, "", 41, 0], [false, false, 41, 0]],
      lex("<math>1 == 1</math>xxx<math>1 == 1</math>"))
    assert_equal([[:PARA_START, "", 0, 0], [:TAG_START, "math", 0, 0], [:TAG_END, "math", 0, 7], [:PARA_END, "", 7, 0], [false, false, 7, 0]],
      lex("<math/>"))
  end
  
  def test_pre
    assert_equal([[:TAG_START, "pre", 0, 0], [:ATTR_NAME, "name", 0, 0], [:ATTR_VALUE, "code", 0, 17],
        [:TEXT, "1 == 1 == 1", 17, 11], [:TAG_END, "pre", 28, 6], [false, false, 34, 0]],
      lex("<pre name='code'>1 == 1 == 1</pre>"))
    assert_equal([[:TAG_START, "pre", 0, 0], [:TAG_END, "pre", 0, 6], [false, false, 6, 0]],
      lex("<pre/>"))
    assert_equal([[:TAG_START, "pre", 0, 5], [:TEXT, "1 == 1", 5, 6], [:TAG_END, "pre", 11, 0], [:PARA_START, "", 11, 7], [:TEXT, "xxx\n", 18, 4],
        [:PARA_END, "", 22, 0], [:TAG_START, "pre", 22, 5], [:TEXT, "1 == 1", 27, 6], [:TAG_END, "pre", 33, 6], [false, false, 39, 0]],
      lex("<pre>1 == 1</pre>\nxxx\n<pre>1 == 1</pre>"))
  end
  
  def test_template
    assert_equal([[:PARA_START, "", 0, 0], [:TEMPLATE_START, "{{", 0, 2], [:TEXT, "ref", 2, 3], [:TEMPLATE_END, "}}", 5, 2],
        [:PARA_END, "", 7, 0], [false, false, 7, 0]],
      lex("{{ref}}"))
    assert_equal([[:PARA_START, "", 0, 0], [:TEMPLATE_START, "{{", 0, 2], [:TEXT, "ref1}ref2", 2, 9], [:TEMPLATE_END, "}}", 11, 2],
        [:PARA_END, "", 13, 0], [false, false, 13, 0]],
      lex("{{ref1}ref2}}"))
    assert_equal([[:PARA_START, "", 0, 0], [:TEMPLATE_START, "{{", 0, 2], [:TEXT, "ref1\n{", 2, 6],
        [:INTLINKSEP, "|", 8, 2], [:INTLINKSEP, "|", 10, 1], [:TEXT, "not a table!\n", 11, 13], [:INTLINKSEP, "|", 24, 1], [:TEXT, "} ", 25, 2],
        [:TEMPLATE_END, "}}", 27, 2], [:PARA_END, "", 29, 0], [false, false, 29, 0]],
      lex("{{ref1\n{|\n|not a table!\n|} }}"))
    assert_equal([[:PARA_START, "", 0, 0], [:TEXT, "{{}}", 0, 4], [:PARA_END, "", 4, 0], [false, false, 4, 0]],
      lex("{{}}"))
#     nested templates are not yet supported
#     assert_equal([[:PARA_START, ""], [:TEMPLATE_START, "{{"], [:TEXT, "xxx"], [:TEMPLATE_START, "{{"],
#         [:TEXT, "iii"], [:TEMPLATE_END, "}}"], [:TEXT, "xxx"], [:TEMPLATE_END, "}}"],
#         [:PARA_END, ""], [false, false, 0, 0]],
#       lex("{{xxx{{iii}}xxx}}"))
  end
  
  def test_xhtml_markup
    assert_equal([[:PARA_START, "", 0, 0], [:TAG_START, "tt", 0, 4], [:TEXT, "text", 4, 4], [:TAG_END, "tt", 8, 5],
        [:PARA_END, "", 13, 0], [false, false, 13, 0]],
      lex("<tt>text</tt>"))
    assert_equal([[:PARA_START, "", 0, 0], [:TAG_START, "tt", 0, 0], [:TAG_END, "tt", 0, 5], [:PARA_END, "", 5, 0], [false, false, 5, 0]],
      lex("<tt/>"))
    assert_equal([[:PARA_START, "", 0, 0], [:TAG_START, "tt", 0, 0], [:TAG_END, "tt", 0, 6], [:PARA_END, "", 6, 0], [false, false, 6, 0]],
      lex("<tt />"))
    assert_equal([[:PARA_START, "", 0, 0], [:TEXT, "<123>", 0, 5], [:PARA_END, "", 5, 0], [false, false, 5, 0]],
      lex("<123>"))
    assert_equal([[:PARA_START, "", 0, 0], [:TEXT, "<xx xx>", 0, 7], [:PARA_END, "", 7, 0], [false, false, 7, 0]],
      lex("<xx xx>"))
    assert_equal([[:PARA_START, "", 0, 0], [:TEXT, "</xxx ", 0, 6], [:PARA_END, "", 6, 0], [false, false, 6, 0]],
      lex("</xxx "))
    assert_equal([[:PARA_START, "", 0, 0], [:TEXT, "<xx </xx>", 0, 9], [:PARA_END, "", 9, 0], [false, false, 9, 0]],
      lex("<xx </xx>"))
    assert_equal([[:PARA_START, "", 0, 0], [:TEXT, "<xx a='b' c>", 0, 12], [:PARA_END, "", 12, 0], [false, false, 12, 0]],
      lex("<xx a='b' c>"))
    assert_equal([[:PARA_START, "", 0, 0], [:TEXT, "<>", 0, 2], [:PARA_END, "", 2, 0], [false, false, 2, 0]],
      lex("<>"))
    assert_equal([[:PARA_START, "", 0, 0], [:TAG_START, "tt", 0, 0], [:ATTR_NAME, 'class', 0, 0], [:ATTR_VALUE, 'tt', 0, 15],
        [:TEXT, "text", 15, 4], [:TAG_END, "tt", 19, 5], [:PARA_END, "", 24, 0], [false, false, 24, 0]],
      lex("<tt class='tt'>text</tt>"))
    assert_equal([[:PARA_START, "", 0, 0], [:TAG_START, "tt", 0, 0], [:ATTR_NAME, 'class', 0, 0], [:ATTR_VALUE, 'tt', 0, 20],
        [:TEXT, "text", 20, 4], [:TAG_END, "tt", 24, 6], [:PARA_END, "", 30, 0], [false, false, 30, 0]],
      lex("<tt   class = 'tt' >text</tt >"))
    assert_equal([[:PARA_START, "", 0, 0], [:TAG_START, "tt", 0, 0], [:ATTR_NAME, 'class', 0, 0], [:ATTR_VALUE, 'tt', 0, 18],
        [:TEXT, "text", 18, 4], [:TAG_END, "tt", 22, 6], [:PARA_END, "", 28, 0], [false, false, 28, 0]],
      lex("<tt\nclass\n=\n'tt'\n>text</tt\n>"))
    assert_equal([[:PARA_START, "", 0, 0], [:TAG_START, "tt", 0, 0], [:ATTR_NAME, 'class', 0, 0], [:ATTR_VALUE, 'tt', 0, 0],
        [:TAG_END, "tt", 0, 17], [:PARA_END, "", 17, 0], [false, false, 17, 0]],
      lex("<tt class='tt' />"))
    assert_equal([[:PARA_START, "", 0, 0], [:TAG_START, "tt", 0, 4], [:TEXT, "\ntext\n", 4, 6], [:TAG_END, "tt", 10, 5],
        [:PARA_END, "", 15, 0], [false, false, 15, 0]],
      lex("<tt>\ntext\n</tt>"))
    assert_equal([[:PARA_START, "", 0, 0], [:TAG_START, "tt", 0, 4], [:TEXT, "\n\ntext\n", 4, 7], [:TAG_END, "tt", 11, 5],
        [:PARA_END, "", 16, 0], [false, false, 16, 0]],
      lex("<tt>\n\ntext\n</tt>"))
    assert_equal([[:PARA_START, "", 0, 0], [:TAG_START, "tt", 0, 12], [:TEXT, "<tt/>", 12, 5], [:TAG_END, "tt", 26, 5],
        [:PARA_END, "", 31, 0], [false, false, 31, 0]],
      lex("<tt><nowiki><tt/></nowiki></tt>"))
    assert_equal([[:PARA_START, "", 0, 0], [:TAG_START, "tt", 0, 4], [:PASTE_START, "", 4, 7], [:TEXT, "paste", 11, 5],
        [:PASTE_END, "", 16, 8], [:TAG_END, "tt", 24, 5], [:PARA_END, "", 29, 0], [false, false, 29, 0]],
      lex("<tt><paste>paste</paste></tt>"))
    assert_equal([[:PARA_START, "", 0, 0], [:LINK_START, "[", 0, 1], [:TEXT, "http://example.com", 1, 18], [:LINKSEP, " ", 19, 1],
        [:TAG_START, "tt", 20, 4], [:TEXT, "text", 24, 4], [:TAG_END, "tt", 28, 5], [:LINK_END, "]", 33, 1], [:PARA_END, "", 34, 0], [false, false, 34, 0]],
      lex("[http://example.com <tt>text</tt>]"))
    assert_equal([[:PARA_START, "", 0, 0], [:INTLINK_START, "[[", 0, 2], [:TEXT, "page", 2, 4], [:INTLINKSEP, "|", 6, 1],
        [:TAG_START, "tt", 7, 4], [:TEXT, "text", 11, 4], [:TAG_END, "tt", 15, 5], [:INTLINK_END, "]]", 20, 2], [:PARA_END, "", 22, 0], [false, false, 22, 0]],
      lex("[[page|<tt>text</tt>]]"))
  end
  
  def test_xhtml_char_entities
    assert_equal([[:PARA_START, "", 0, 0], [:CHAR_ENT, "lt", 0, 4], [:PARA_END, "", 4, 0], [false, false, 4, 0]],
      lex("&lt;"))
    assert_equal([[:PARA_START, "", 0, 0], [:CHAR_ENT, "amp", 0, 5], [:TEXT, "amp;", 5, 4], [:PARA_END, "", 9, 0], [false, false, 9, 0]],
      lex("&amp;amp;"))
    assert_equal([[:PARA_START, "", 0, 0], [:TEXT, "&", 0, 1], [:PARA_END, "", 1, 0], [false, false, 1, 0]],
      lex("&"))
    assert_equal([[:PARA_START, "", 0, 0], [:TEXT, "&amp", 0, 4], [:PARA_END, "", 4, 0], [false, false, 4, 0]],
      lex("&amp"))
    assert_equal([[:PARA_START, "", 0, 0], [:TEXT, "&amp ;", 0, 6], [:PARA_END, "", 6, 0], [false, false, 6, 0]],
      lex("&amp ;"))
    assert_equal([[:PARA_START, "", 0, 0], [:TEXT, "&amp amp;", 0, 9], [:PARA_END, "", 9, 0], [false, false, 9, 0]],
      lex("&amp amp;"))
    assert_equal([[:PARA_START, "", 0, 0], [:TEXT, "&amp", 0, 4], [:CHAR_ENT, "amp", 4, 5], [:PARA_END, "", 9, 0], [false, false, 9, 0]],
      lex("&amp&amp;"))
  end
  
  def test_unordered_lists
    assert_equal([[:UL_START, '', 0, 0], [:LI_START, '', 0, 1], [:TEXT, "a", 1, 1], [:LI_END, '', 2, 0], [:UL_END, '', 2, 0],
        [false, false, 2, 0]],
      lex("*a"))
    assert_equal([[:UL_START, '', 0, 0], [:LI_START, '', 0, 1], [:TEXT, "a\n", 1, 2], [:LI_END, '', 3, 0], [:UL_END, '', 3, 0],
        [false, false, 3, 0]],
      lex("*a\n"))
    assert_equal([[:UL_START, '', 1, 0], [:LI_START, '', 1, 1], [:TEXT, "a", 2, 1], [:LI_END, '', 3, 0], [:UL_END, '', 3, 0],
        [false, false, 3, 0]],
      lex("\n*a"))
    assert_equal([[:PARA_START, "", 0, 0], [:TEXT, "text\n", 0, 5], [:PARA_END, "", 5, 0], [:UL_START, '', 5, 0], 
        [:LI_START, '', 5, 1], [:TEXT, "a", 6, 1], [:LI_END, '', 7, 0], [:UL_END, '', 7, 0], [false, false, 7, 0]],
      lex("text\n*a"))
    assert_equal([[:UL_START, '', 0, 0], [:LI_START, '', 0, 1], [:TEXT, "a\n", 1, 2], [:LI_END, '', 3, 0],
        [:LI_START, '', 3, 1], [:TEXT, "b\n", 4, 2], [:LI_END, '', 6, 0], [:UL_END, '', 6, 0], [false, false, 6, 0]],
      lex("*a\n*b\n"))
    assert_equal([[:UL_START, '', 0, 0], [:LI_START, '', 0, 1], [:TEXT, "a\n", 1, 2],
        [:UL_START, '', 3, 0], [:LI_START, '', 3, 2], [:TEXT, "i\n", 5, 2], [:LI_END, '', 7, 0], [:UL_END, '', 7, 0], [:LI_END, '', 7, 0],
        [:LI_START, '', 7, 1], [:TEXT, "b\n", 8, 2], [:LI_END, '', 10, 0], [:UL_END, '', 10, 0], [false, false, 10, 0]],
      lex("*a\n**i\n*b\n"))
    assert_equal([[:UL_START, '', 0, 0], [:LI_START, '', 0, 1], [:TEXT, "a\n", 1, 2],
        [:UL_START, '', 3, 0], [:LI_START, '', 3, 2], [:TEXT, "i\n", 5, 2], [:LI_END, '', 7, 0], [:UL_END, '', 7, 0], [:LI_END, '', 7, 0],
        [:UL_END, '', 7, 0], [false, false, 7, 0]],
      lex("*a\n**i\n"))
    assert_equal([[:UL_START, '', 0, 0], [:LI_START, '', 0, 1], [:UL_START, '', 1, 0],
        [:LI_START, '', 1, 1], [:TEXT, "i\n", 2, 2], [:LI_END, '', 4, 0], [:UL_END, '', 4, 0], [:LI_END, '', 4, 0],
        [:UL_END, '', 4, 0], [false, false, 4, 0]],
      lex("**i\n"))
    assert_equal([[:UL_START, '', 0, 0], [:LI_START, '', 0, 1], [:UL_START, '', 1, 0],
        [:LI_START, '', 1, 1], [:TEXT, "i\n", 2, 2], [:LI_END, '', 4, 0], [:UL_END, '', 4, 0], [:LI_END, '', 4, 0],
        [:LI_START, '', 4, 1], [:TEXT, "b\n", 5, 2], [:LI_END, '', 7, 0], [:UL_END, '', 7, 0], [false, false, 7, 0]],
      lex("**i\n*b\n"))
  end
  
  def test_ordered_lists
    assert_equal([[:OL_START, "", 0, 0], [:LI_START, "", 0, 1], [:TEXT, "a", 1, 1], [:LI_END, "", 2, 0], [:OL_END, "", 2, 0],
        [false, false, 2, 0]],
      lex("#a"))
    assert_equal([[:OL_START, "", 0, 0], [:LI_START, "", 0, 1], [:TEXT, "a\n", 1, 2], [:LI_END, "", 3, 0], [:OL_END, "", 3, 0],
        [false, false, 3, 0]],
      lex("#a\n"))
    assert_equal([[:OL_START, '', 1, 0], [:LI_START, '', 1, 1], [:TEXT, "a", 2, 1], [:LI_END, '', 3, 0], [:OL_END, '', 3, 0],
        [false, false, 3, 0]],
      lex("\n#a"))
    assert_equal([[:PARA_START, "", 0, 0], [:TEXT, "text\n", 0, 5], [:PARA_END, "", 5, 0], [:OL_START, '', 5, 0], 
        [:LI_START, '', 5, 1], [:TEXT, "a", 6, 1], [:LI_END, '', 7, 0], [:OL_END, '', 7, 0], [false, false, 7, 0]],
      lex("text\n#a"))
    assert_equal([[:OL_START, '', 0, 0], [:LI_START, '', 0, 1], [:TEXT, "a\n", 1, 2], [:LI_END, '', 3, 0],
        [:LI_START, '', 3, 1], [:TEXT, "b\n", 4, 2], [:LI_END, '', 6, 0], [:OL_END, '', 6, 0], [false, false, 6, 0]],
      lex("#a\n#b\n"))
    assert_equal([[:OL_START, "", 0, 0], [:LI_START, "", 0, 1], [:TEXT, "a\n", 1, 2], [:OL_START, "", 3, 0], [:LI_START, "", 3, 2],
        [:TEXT, "i\n", 5, 2], [:LI_END, "", 7, 0], [:OL_END, "", 7, 0], [:LI_END, "", 7, 0], [:LI_START, "", 7, 1], [:TEXT, "b\n", 8, 2],
        [:LI_END, "", 10, 0], [:OL_END, "", 10, 0], [false, false, 10, 0]],
      lex("#a\n##i\n#b\n"))
    assert_equal([[:OL_START, "", 0, 0], [:LI_START, "", 0, 1], [:TEXT, "a\n", 1, 2], [:OL_START, "", 3, 0], [:LI_START, "", 3, 2],
        [:TEXT, "i\n", 5, 2], [:LI_END, "", 7, 0], [:OL_END, "", 7, 0], [:LI_END, "", 7, 0], [:OL_END, "", 7, 0],
        [false, false, 7, 0]],
      lex("#a\n##i\n"))
    assert_equal([[:OL_START, "", 0, 0], [:LI_START, "", 0, 1], [:OL_START, "", 1, 0], [:LI_START, "", 1, 1], [:TEXT, "i\n", 2, 2],
        [:LI_END, "", 4, 0], [:OL_END, "", 4, 0], [:LI_END, "", 4, 0], [:OL_END, "", 4, 0], [false, false, 4, 0]],
      lex("##i\n"))
    assert_equal([[:OL_START, "", 0, 0], [:LI_START, "", 0, 1], [:OL_START, "", 1, 0], [:LI_START, "", 1, 1], [:TEXT, "i\n", 2, 2],
        [:LI_END, "", 4, 0], [:OL_END, "", 4, 0], [:LI_END, "", 4, 0], [:LI_START, "", 4, 1], [:TEXT, "b\n", 5, 2], [:LI_END, "", 7, 0],
        [:OL_END, "", 7, 0], [false, false, 7, 0]],
      lex("##i\n#b\n"))
  end
  
  def test_mixed_lists
    assert_equal([[:UL_START, '', 0, 0], [:LI_START, '', 0, 1], [:TEXT, "a\n", 1, 2], [:LI_END, '', 3, 0], [:UL_END, '', 3, 0],
        [:OL_START, '', 3, 0], [:LI_START, '', 3, 1], [:TEXT, "b\n", 4, 2], [:LI_END, '', 6, 0], [:OL_END, '', 6, 0], [false, false, 6, 0]],
      lex("*a\n#b\n"))
    assert_equal([[:OL_START, '', 0, 0], [:LI_START, '', 0, 1], [:TEXT, "a\n", 1, 2],
        [:UL_START, '', 3, 0], [:LI_START, '', 3, 2], [:TEXT, "i\n", 5, 2], [:LI_END, '', 7, 0], [:UL_END, '', 7, 0], [:LI_END, '', 7, 0],
        [:LI_START, '', 7, 1], [:TEXT, "b\n", 8, 2], [:LI_END, '', 10, 0], [:OL_END, '', 10, 0], [false, false, 10, 0]],
      lex("#a\n#*i\n#b\n"))
    assert_equal([[:UL_START, '', 0, 0], [:LI_START, '', 0, 1], [:TEXT, "a\n", 1, 2],
        [:OL_START, '', 3, 0], [:LI_START, '', 3, 2], [:TEXT, "i\n", 5, 2], [:LI_END, '', 7, 0], [:OL_END, '', 7, 0], [:LI_END, '', 7, 0],
        [:LI_START, '', 7, 1], [:TEXT, "b\n", 8, 2], [:LI_END, '', 10, 0], [:UL_END, '', 10, 0], [false, false, 10, 0]],
      lex("*a\n*#i\n*b\n"))
  end
  
  def test_definition_lists
    assert_equal([[:DL_START, "", 0, 0], [:DT_START, ";", 0, 1], [:TEXT, "a", 1, 1], [:DT_END, "", 2, 0], [:DL_END, "", 2, 0],
        [false, false, 2, 0]],
      lex(";a"))
    assert_equal([[:DL_START, '', 0, 0], [:DT_START, ';', 0, 1], [:TEXT, "a\n", 1, 2], [:DT_END, '', 3, 0], [:DL_END, '', 3, 0],
        [false, false, 3, 0]],
      lex(";a\n"))
    assert_equal([[:DL_START, "", 0, 0], [:DD_START, ":", 0, 1], [:TEXT, "b", 1, 1], [:DD_END, "", 2, 0], [:DL_END, "", 2, 0],
        [false, false, 2, 0]],
      lex(":b"))
    assert_equal([[:DL_START, '', 0, 0], [:DD_START, ':', 0, 1], [:TEXT, "b\n", 1, 2], [:DD_END, '', 3, 0], [:DL_END, '', 3, 0],
        [false, false, 3, 0]],
      lex(":b\n"))
    assert_equal([[:DL_START, '', 0, 0], [:DT_START, ';', 0, 1], [:TEXT, "a\n", 1, 2], [:DT_END, '', 3, 0],
        [:DD_START, ':', 3, 1], [:TEXT, "b\n", 4, 2], [:DD_END, '', 6, 0], [:DL_END, '', 6, 0], [false, false, 6, 0]],
      lex(";a\n:b\n"))
    assert_equal([[:DL_START, '', 0, 0], [:DT_START, ';', 0, 1], [:TEXT, "a", 1, 1], [:DT_END, '', 2, 0],
        [:DD_START, ':', 2, 1], [:TEXT, "b\n", 3, 2], [:DD_END, '', 5, 0], [:DL_END, '', 5, 0], [false, false, 5, 0]],
      lex(";a:b\n"))
    assert_equal([[:DL_START, '', 0, 0], [:DT_START, ';', 0, 1], [:TEXT, "a\n", 1, 2], [:DT_END, '', 3, 0],
        [:DD_START, ':', 3, 1], [:TEXT, "b\n", 4, 2], [:DD_END, '', 6, 0], [:DD_START, ':', 6, 1], [:TEXT, "c\n", 7, 2],
        [:DD_END, '', 9, 0],[:DL_END, '', 9, 0], [false, false, 9, 0]],
      lex(";a\n:b\n:c\n"))
    assert_equal([[:DL_START, '', 0, 0], [:DT_START, ';', 0, 1], [:TEXT, "a\n", 1, 2], [:DT_END, '', 3, 0], [:DL_END, '', 3, 0],
        [:DL_START, '', 3, 0], [:DT_START, ';', 3, 1], [:TEXT, "a\n", 4, 2], [:DT_END, '', 6, 0], [:DL_END, '', 6, 0],
        [false, false, 6, 0]],
      lex(";a\n;a\n"))
    assert_equal([[:DL_START, '', 0, 0], [:DT_START, ';', 0, 1], [:TEXT, "a\n", 1, 2], [:DT_END, '', 3, 0], [:DL_END, '', 3, 0], 
        [:PARA_START, '', 3, 0], [:TEXT, 'text', 3, 4], [:PARA_END, '', 7, 0], [false, false, 7, 0]],
      lex(";a\ntext"))
    assert_equal([[:DL_START, '', 0, 0], [:DT_START, ';', 0, 1], [:TEXT, "a", 1, 1], [:DT_END, '', 2, 0],
        [:DD_START, ':', 2, 1], [:INTLINK_START, '[[', 3, 2], [:TEXT, "resource", 5, 8], [:RESOURCESEP, ':', 13, 1],
        [:TEXT, 'text', 14, 4], [:INTLINK_END, "]]", 18, 3], [:DD_END, '', 21, 0], [:DL_END, '', 21, 0], [false, false, 21, 0]],
      lex(";a:[[resource:text]]\n"))
  end

  def test_toc_and_notoc
    assert_equal([[:KEYWORD, "TOC", 0, 7], [false, false, 7, 0]], lex("__TOC__"))
    assert_equal([[:KEYWORD, "NOTOC", 0, 9], [false, false, 9, 0]], lex("__NOTOC__"))
  end

  
  private
  
  def lex(string)
    lexer = MediaWikiLexer.new
    lexer.tokenize(string)
  end

end

require 'mediacloth/mediawikilexer'
require 'mediacloth/mediawikiparser'
require 'mediacloth/mediawikisignedwikigenerator'
require 'mediacloth/mediawikilinkhandler'
require 'mediacloth/mediawikitemplatehandler'

require 'test/unit'
require 'testhelper'

class SignedWikiGenerator_Test < Test::Unit::TestCase

    class << self
      include TestHelper
    end

    def test_simple_signature_replacement
      assert_generates "[[User:Creator|Creator]]",
                       "~~~",
                        "SignatureName replacement failed"
      assert_generates "[[User:Creator|Creator]] 01:01, 01 January 2000 ",
                       "~~~~",
                        "SignatureFull replacement failed"
      assert_generates "01:01, 01 January 2000 ",
                       "~~~~~",
                        "SignatureDate replacement failed"
    end

    def test_multiple_signature_replacement
      assert_generates "[[User:Creator|Creator]]sometext[[User:Creator|Creator]]",
                       "~~~sometext~~~"
      assert_generates "[[User:Creator|Creator]]sometext[[User:Creator|Creator]] 01:01, 01 January 2000 ",
                       "~~~sometext~~~~"
      assert_generates "[[User:Creator|Creator]]sometext01:01, 01 January 2000 ",
                       "~~~sometext~~~~~"
      assert_generates "[[User:Creator|Creator]] 01:01, 01 January 2000 some\ntext[[User:Creator|Creator]]",
                       "~~~~some\ntext~~~"
      assert_generates "[[User:Creator|Creator]] 01:01, 01 January 2000 some\ntext[[User:Creator|Creator]] 01:01, 01 January 2000 ",
                       "~~~~some\ntext~~~~"
      assert_generates "[[User:Creator|Creator]] 01:01, 01 January 2000 some\ntext01:01, 01 January 2000 ",
                       "~~~~some\ntext~~~~~"
      assert_generates "01:01, 01 January 2000 sometext[[User:Creator|Creator]]",
                       "~~~~~sometext~~~"
      assert_generates "01:01, 01 January 2000 sometext[[User:Creator|Creator]] 01:01, 01 January 2000 ",
                       "~~~~~sometext~~~~"
      assert_generates "01:01, 01 January 2000 sometext01:01, 01 January 2000 ",
                       "~~~~~sometext~~~~~"
      assert_generates "[[User:Creator|Creator]]some text[[User:Creator|Creator]] 01:01, 01 January 2000 '''bold'''01:01, 01 January 2000 ",
                       "~~~some text~~~~'''bold'''~~~~~"
      assert_generates "[[User:Creator|Creator]] 01:01, 01 January 2000 ''''bold italic'''''01:01, 01 January 2000 some\ntext[[User:Creator|Creator]] 01:01, 01 January 2000 ",
                       "~~~~''''bold italic'''''~~~~~some\ntext~~~~"
    end

    def test_signature_replacement_in_wiki_structures
      assert_generates "<nowiki> ~~~ </nowiki>",
                       "<nowiki> ~~~ </nowiki>"
      assert_generates "<nowiki> ~~~~ </nowiki>",
                       "<nowiki> ~~~~ </nowiki>"
      assert_generates "<nowiki> ~~~~~ </nowiki>",
                       "<nowiki> ~~~~~ </nowiki>"
      assert_generates "<tt> [[User:Creator|Creator]] </tt>",
                       "<tt> ~~~ </tt>"
      assert_generates "<tt> [[User:Creator|Creator]] 01:01, 01 January 2000  </tt>",
                       "<tt> ~~~~ </tt>"
      assert_generates "<tt> 01:01, 01 January 2000  </tt>",
                       "<tt> ~~~~~ </tt>"
      assert_generates "<paste> ~~~ </paste>",
                       "<paste> ~~~ </paste>"
      assert_generates "<paste> ~~~~ </paste>",
                       "<paste> ~~~~ </paste>"
      assert_generates "<paste> ~~~~~ </paste>",
                       "<paste> ~~~~~ </paste>"
      assert_generates "'' [[User:Creator|Creator]] ''",
                       "'' ~~~ ''"
      assert_generates "'' [[User:Creator|Creator]] 01:01, 01 January 2000  ''",
                       "'' ~~~~ ''"
      assert_generates "'' 01:01, 01 January 2000  ''",
                       "'' ~~~~~ ''"
      assert_generates "''' [[User:Creator|Creator]] '''",
                       "''' ~~~ '''"
      assert_generates "''' [[User:Creator|Creator]] 01:01, 01 January 2000  '''",
                       "''' ~~~~ '''"
      assert_generates "''' 01:01, 01 January 2000  '''",
                       "''' ~~~~~ '''"
    end

private

   def assert_generates(result, input, message=nil)
      assert_equal(result, generate(input), message)
   end

   def generate(input)
      parser = MediaWikiParser.new
      parser.lexer = MediaWikiLexer.new
      ast = parser.parse(input)
      generator = MediaWikiSignedWikiGenerator.new
      generator.link_handler = FullLinkHandler.new
      params = MediaWikiParams.new
      params.time = Time.utc(2000, 1, 1, 1, 1, 1, 1)
      generator.params = params
      generator.parse(ast,input)
      generator.signed_wiki
   end
end

class FullLinkHandler < MediaWikiLinkHandler
  def link_for(page, text)
    "<span class=\"link\">#{text}</span>"
  end
end


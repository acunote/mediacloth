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
      assert_generates "[[User:Creator|Creator]] Sat Jan 01, 2000 01:01",
                       "~~~~",
                        "SignatureFull replacement failed"
      assert_generates "Sat Jan 01, 2000 01:01",
                       "~~~~~",
                        "SignatureDate replacement failed"
    end

    def test_multiple_signature_replacement
      assert_generates "[[User:Creator|Creator]]sometext[[User:Creator|Creator]]",
                       "~~~sometext~~~"
      assert_generates "[[User:Creator|Creator]]sometext[[User:Creator|Creator]] Sat Jan 01, 2000 01:01",
                       "~~~sometext~~~~"
      assert_generates "[[User:Creator|Creator]]sometextSat Jan 01, 2000 01:01",
                       "~~~sometext~~~~~"
      assert_generates "[[User:Creator|Creator]] Sat Jan 01, 2000 01:01some\ntext[[User:Creator|Creator]]",
                       "~~~~some\ntext~~~"
      assert_generates "[[User:Creator|Creator]] Sat Jan 01, 2000 01:01some\ntext[[User:Creator|Creator]] Sat Jan 01, 2000 01:01",
                       "~~~~some\ntext~~~~"
      assert_generates "[[User:Creator|Creator]] Sat Jan 01, 2000 01:01some\ntextSat Jan 01, 2000 01:01",
                       "~~~~some\ntext~~~~~"
      assert_generates "Sat Jan 01, 2000 01:01sometext[[User:Creator|Creator]]",
                       "~~~~~sometext~~~"
      assert_generates "Sat Jan 01, 2000 01:01sometext[[User:Creator|Creator]] Sat Jan 01, 2000 01:01",
                       "~~~~~sometext~~~~"
      assert_generates "Sat Jan 01, 2000 01:01sometextSat Jan 01, 2000 01:01",
                       "~~~~~sometext~~~~~"
      assert_generates "[[User:Creator|Creator]]some text[[User:Creator|Creator]] Sat Jan 01, 2000 01:01'''bold'''Sat Jan 01, 2000 01:01",
                       "~~~some text~~~~'''bold'''~~~~~"
      assert_generates "[[User:Creator|Creator]] Sat Jan 01, 2000 01:01''''bold italic'''''Sat Jan 01, 2000 01:01some\ntext[[User:Creator|Creator]] Sat Jan 01, 2000 01:01",
                       "~~~~''''bold italic'''''~~~~~some\ntext~~~~"
      assert_generates "* [[User:Creator|Creator]]\n* [[User:Creator|Creator]] Sat Jan 01, 2000 01:01\n* Sat Jan 01, 2000 01:01\n",
                       "* ~~~\n* ~~~~\n* ~~~~~\n"
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
      assert_generates "<tt> [[User:Creator|Creator]] Sat Jan 01, 2000 01:01 </tt>",
                       "<tt> ~~~~ </tt>"
      assert_generates "<tt> Sat Jan 01, 2000 01:01 </tt>",
                       "<tt> ~~~~~ </tt>"
      assert_generates "<paste> ~~~ </paste>",
                       "<paste> ~~~ </paste>"
      assert_generates "<paste> ~~~~ </paste>",
                       "<paste> ~~~~ </paste>"
      assert_generates "<paste> ~~~~~ </paste>",
                       "<paste> ~~~~~ </paste>"
      assert_generates "'' [[User:Creator|Creator]] ''",
                       "'' ~~~ ''"
      assert_generates "'' [[User:Creator|Creator]] Sat Jan 01, 2000 01:01 ''",
                       "'' ~~~~ ''"
      assert_generates "'' Sat Jan 01, 2000 01:01 ''",
                       "'' ~~~~~ ''"
      assert_generates "''' [[User:Creator|Creator]] '''",
                       "''' ~~~ '''"
      assert_generates "''' [[User:Creator|Creator]] Sat Jan 01, 2000 01:01 '''",
                       "''' ~~~~ '''"
      assert_generates "''' Sat Jan 01, 2000 01:01 '''",
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


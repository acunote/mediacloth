require 'mediacloth/mediawikilexer'
require 'mediacloth/mediawikiparser'
require 'mediacloth/mediawikihtmlgenerator'
require 'mediacloth/mediawikilinkhandler'

require 'test/unit'
require 'testhelper'

class HTMLGenerator_Test < Test::Unit::TestCase

    include TestHelper

    def test_input
      test_files("html") do |input,result, name|
        puts name
        assert_generates(result, input, nil, name)
      end
    end

    def test_uses_element_attributes_from_link_handler
      assert_generates '<p><a href="http://www.example.com/wiki/InternalLink" class="empty">This is just an internal link</a></p>',
                       '[[InternalLink|This is just an internal link]]',
                        ClassEmptyLinkHandler.new
    end

    def test_accepts_url_only_link_handlers
      assert_generates '<p><a href="http://www.example.com/wiki/InternalLink/">This is just an internal link</a></p>',
                       '[[InternalLink|This is just an internal link]]',
                       UrlOnlyLinkHandler.new
    end

    def test_prefers_url_from_attributes_when_provided_with_ambiguous_link_info
      assert_generates '<p><a href="http://www.example.com/wiki/InternalLink" rel="nofollow">This is just an internal link</a></p>',
                       '[[InternalLink|This is just an internal link]]',
                        AmbiguousLinkHandler.new
    end

    def test_allows_specification_of_all_attributes
      assert_generates '<p><a href="http://www.mysite.com/MyLink" id="123">Here is my link</a></p>',
                       '[[MyLink|Here is my link]]',
                        LinkAttributeHandler.new
    end

    def test_allows_full_customization_of_link_tags
      assert_generates '<p><span class="link">This doesn\'t even render into a real link</span></p>',
                       "[[AnotherLink|This doesn't even render into a real link]]",
                        FullLinkHandler.new
    end

private

  def assert_generates(result, input, link_handler=nil, message=nil)
      parser = MediaWikiParser.new
      parser.lexer = MediaWikiLexer.new
      ast = parser.parse(input)
      MediaWikiParams.instance.time = Time.utc(2000, 1, 1, 1, 1, 1, 1)
      generator = MediaWikiHTMLGenerator.new
      generator.link_handler = link_handler if link_handler
      generator.parse(ast)
      assert_equal(result, generator.html, message)
   end
end

class LinkAttributeHandler < MediaWikiLinkHandler
  def link_attributes_for(page)
    { :href => "http://www.mysite.com/#{page}", :id => '123' }
  end
end

class ClassEmptyLinkHandler < MediaWikiLinkHandler
  def link_attributes_for(resource)
    {:class => 'empty', :href => "http://www.example.com/wiki/#{resource}"}
  end
end

class UrlOnlyLinkHandler < MediaWikiLinkHandler
  def url_for(resource)
    "http://www.example.com/wiki/#{resource}/"
  end
end

class AmbiguousLinkHandler < MediaWikiLinkHandler
  def url_for(resource)
    "http://www.somewhereelse.net"
  end

  def link_attributes_for(resource)
    {:rel => 'nofollow', :href => "http://www.example.com/wiki/#{resource}"}
  end
end

class FullLinkHandler < MediaWikiLinkHandler
  def link_for(page, text)
    "<span class=\"link\">#{text}</span>"
  end
end


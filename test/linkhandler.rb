require 'mediacloth/mediawikilinkhandler'

require 'test/unit'
require 'testhelper'

class LinkHandler_Test < Test::Unit::TestCase

  def test_resolves_single_links
    handler = create_handler
    assert_equal '<a href="http://example.com/wiki/MyPage">this is my page</a>',
                 handler.link_for('MyPage', 'this is my page')
  end

  def test_forgets_previous_links
    handler = create_handler
    handler.link_for('MyPage', 'this is my page')
    assert_equal '<a href="http://example.com/wiki/YourPage">this page is yours</a>',
                 handler.link_for('YourPage', 'this page is yours')
  end

  def test_provides_suitable_elem_method_for_subclasses
    handler = create_handler
    def handler.link_for(page, text)
      elem.span(:class => 'empty') {|x| x << text }
    end
    assert_equal '<span class="empty">Here is my page</span>',
                 handler.link_for('MyPage', 'Here is my page')
  end

private

  def create_handler
    handler = MediaWikiLinkHandler.new
    def handler.url_for(page); "http://example.com/wiki/#{page}"; end
    handler
  end

end


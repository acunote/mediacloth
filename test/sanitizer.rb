require 'mediacloth/mediawikisanitizer'


require 'test/unit'
require 'testhelper'

class SanitizerTest < Test::Unit::TestCase

  def setup
    @@sanitizer ||= MediaWikiSanitizer.new
  end

  def test_sanitizes_script_tags
    assert_sanitizes_to "&lt;script&gt;alert('Unescaped code!')&lt;\/script&gt;",
                        "<script>alert('Unescaped code!')</script>"
  end

  def test_keeps_bold_and_italics_tags
    assert_sanitizes_to "This is <b>bold</b> and this is in <i>italics</i>",
                        "This is <b>bold</b> and this is in <i>italics</i>" 
  end

private

  def assert_sanitizes_to(expected, actual)
    assert_equal expected, @@sanitizer.transform(actual)
  end

end

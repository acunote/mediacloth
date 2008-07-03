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

  def test_keeps_deleted_and_inserted_tags
    assert_no_sanitization "This is <del>bold</del>, and that is <ins>inserted</ins>"
  end

  def test_keeps_bold_and_italics_tags
    assert_no_sanitization "This is <b>bold</b>, this is in <i>italics</i> and that is <em>emphasized</em>"
  end

  def test_keeps_underline_and_strikethrough_tags
    assert_no_sanitization "This is very <u>important</u>, but that
                            can <s>safely</s> be <strike>ignored</strike>"
  end

  def test_keeps_font_tags
    assert_no_sanitization %{Fonts can be <font face="serif">changed</font> using HTML tags}
  end

  def test_keeps_big_and_small_tags
    assert_no_sanitization "Text can be made <big>big</big>, <small>small</small>"
  end

  def test_keeps_sub_and_superscripts
    assert_no_sanitization "We can also use <sub>sub</sub> and <sup>superscripts</sup>"
  end

  def test_keeps_citation_tags
    assert_no_sanitization %{<cite>"Perfection is achieved, not when there is
                                    nothing left to add, but when there is
                                    nothing left to remove."</cite>
                             -- Antoine de Saint-Exupery}
  end

  def test_keeps_code_and_teletype
    assert_no_sanitization "Text inside <code>code</code> and <tt>teletype</tt>
                            usually get rendered with a fixed width font"
  end

  def test_keeps_variable_tags
    assert_no_sanitization "Here is a <var>variable</var>"
  end

  def test_keeps_strong_tags
    assert_no_sanitization "That was a very <strong>strong</strong> claim"
  end

  def test_keeps_spans
    assert_no_sanitization %{Most environments will render
                             <span style="color: red">this text</span> with
                             different colours}
  end

private

  def assert_sanitizes_to(expected, actual)
    assert_equal expected, @@sanitizer.transform(actual)
  end

  def assert_no_sanitization(expected)
    assert_sanitizes_to(expected, expected)
  end

end

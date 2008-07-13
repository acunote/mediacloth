require 'mediacloth/mediawikilexer'

require 'test/unit'
require 'testhelper'

class SanitizationTest < Test::Unit::TestCase

  include TestHelper

  def setup
    @@lexer ||= MediaWikiLexer.new
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
    assert_no_sanitization "This is very <u>important</u>, but that " +
                           "can <s>safely</s> be <strike>ignored</strike>"
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
    assert_no_sanitization  "<cite>Perfection is achieved, not when there is" +
                                  " nothing left to add, but when there is" +
                                  " nothing left to remove.</cite>" +
                            " -- Antoine de Saint-Exupery"
  end

  def test_keeps_code_and_teletype
    assert_no_sanitization "Text inside <code>code</code> and <tt>teletype</tt> " +
                           "usually get rendered with a fixed width font"
  end

  def test_keeps_variable_tags
    assert_no_sanitization "Here is a <var>variable</var>"
  end

  def test_keeps_strong_tags
    assert_no_sanitization "That was a very <strong>strong</strong> claim"
  end

  def test_keeps_spans
    assert_no_sanitization "Most environments will render " +
                           "<span style=\"color: red\">this text</span> with " +
                           "different colours"
  end

  def test_keeps_headings
    assert_no_sanitization "<h1>Heading 1</h1>" +
                           "<h2>Heading 2</h2>" +
                           "<h3>Heading 3</h3>" +
                           "<h4>Heading 4</h4>" +
                           "<h5>Heading 5</h5>" +
                           "<h6>Heading 6</h6>"
  end

  def test_keeps_divs
    assert_no_sanitization "<div>Division</div>"
  end

  def test_keeps_center_tags
    assert_no_sanitization "<center>Center</center>"
  end

  def test_keeps_blockquote_tags
    assert_no_sanitization "<blockquote>Blockquote</blockquote>"
  end

  def test_keeps_ordered_and_unordered_lists
    assert_no_sanitization "<ol>" +
                             "<li>Ordered</li>" +
                             "<li>List</li>" +
                             "<li>(And list items)</li>" +
                           "</ol>" +
                           "<ul>" +
                             "<li>Unordered</li>" +
                             "<li>List</li>" +
                             "<li>(And list items)</li>" +
                           "</ul>"
  end

  def test_keeps_table_and_main_components
    assert_no_sanitization "<table>" +
                             "<tr><th>Table</th>    <th>tag</th>   <th /></tr>" +
                             "<tr><td>and</td>      <td>its</td>   <td>components</td></tr>" +
                             "<tr><td>including</td><td>header</td><td>tags</td></tr>" +
                           "</table>"
  end

  def test_keeps_ruby_tag_and_components
    assert_no_sanitization "<ruby>" +
                             "<rb>Ruby base</rb>" +
                             "<rp>(</rp>" +
                             "<rt>Ruby text</rt>" +
                             "<rp>)</rp>" +
                           "</ruby>"
  end

  def test_keeps_paragraph_tags
    assert_no_sanitization "We can also break <p>paragraphs</p> with HTML."
  end

  def test_keeps_linebreaks
    assert_no_sanitization "Break lines with an empty element<br /><br/>"
  end

  def test_keeps_horizontal_rules
    assert_no_sanitization "<hr />Display an horizontal rule"
  end

  def test_keeps_definition_lists
    assert_no_sanitization "<dl>" +
                             "<dt>Definition terms</dt>" +
                             "<dd>And descriptions</dd>" +
                           "</dl>"
  end

  def test_keeps_preformatted_text
    assert_no_sanitization "<pre>Preformatted\ntext</pre>"
  end

  def test_keeps_nowiki_tags_and_sanitizes_inside
    assert_sanitizes_to "No &lt;yy&gt;wiki&lt;/yy&gt; ''tag''",
                        "<nowiki>No <yy>wiki</yy> ''tag''</nowiki>"
  end

  def test_keeps_math_tags
    assert_no_sanitization "<math>1 == 1</math>"
  end

  def test_sanitizes_thead_and_tbody_tags
    assert_sanitizes_to "&lt;thead&gt;Table header&lt;/thead&gt;&lt;tbody&gt;Table body&lt;/tbody&gt;",
                        "<thead>Table header</thead><tbody>Table body</tbody>"
  end

  def test_sanitizes_form_label_and_input_tags
    assert_sanitizes_to "&lt;form action=&quot;/send&quot; method=&quot;post&quot;&gt;" +
                           "&lt;label for=&quot;username&quot;&gt;Username&lt;/label&gt;" +
                           "&lt;input name=&quot;login&quot; id=&quot;username&quot; /&gt;" +
                         "&lt;/form&gt;",
                        "<form action=\"/send\" method=\"post\">" +
                          "<label for=\"username\">Username</label>" +
                          "<input name=\"login\" id=\"username\" />" +
                        "</form>"
  end

  def test_keeps_and_sanitizes_with_spaces_before_the_closing_bracket
    assert_sanitizes_to "Here is some <b  >bold</b> and <em>emphasized</em  >" +
                        " text. But &lt;script type=&quot;text/javascript&quot;  &gt;" +
                         "alert('scripts')&lt;/script   &gt; get sanitized",
                        "Here is some <b  >bold</b> and <em>emphasized</em  >" +
                        " text. But <script type=\"text/javascript\"  >" + 
                         "alert('scripts')</script   > get sanitized"
  end

  def test_ignores_case_for_whitelisted_tags
    assert_no_sanitization "<SUP>Superscript</SUP> and <CODE>code</CODE>"
  end

  def test_removes_on_attributes_even_from_legal_tags
    assert_sanitizes_to %{Here is some <b >bold</b> text},
                        %{Here is some <b onMouseOver="alert('Cuidado!')">bold</b> text}
  end

private

  def assert_sanitizes_to(expected, actual)
    assert_generates("<p>#{expected}</p>", actual)
  end

  def assert_no_sanitization(expected)
    assert_sanitizes_to(expected, expected)
  end

end

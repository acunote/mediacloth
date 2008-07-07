# Sanitizer for wiki input. Works over the raw input escaping dangerous tags
class MediaWikiSanitizer
  WHITELIST = %w{del  ins  b    i    em   u    s    strike    font
                 big  small     sub  sup  cite code tt   var  strong
                 span h1   h2   h3   h4   h5   h6   div  center
                 blockquote     ol   li   ul   table     tr   th   td
                 ruby rb   rp   rt   p    br   hr   dl   dt   dd}

  def transform(input)
    input.gsub(/<(\/?)([^\s>]+)([^>]*)>/) do
      WHITELIST.include?($2) ? $& : "&lt;#{$1}#{$2}#{$3}&gt;"
    end
  end
end


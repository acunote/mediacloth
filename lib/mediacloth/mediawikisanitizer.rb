# Sanitizer for wiki input. Works over the raw input escaping dangerous tags
class MediaWikiSanitizer
  def transform(input)
    input.gsub(/<(\/?)script>/, '&lt;\1script&gt;')
  end
end


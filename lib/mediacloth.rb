require 'mediacloth/mediawikilexer'
require 'mediacloth/mediawikiparser'
require 'mediacloth/mediawikiast'
require 'mediacloth/mediawikiparams'
require 'mediacloth/mediawikiwalker'
require 'mediacloth/mediawikihtmlgenerator'
require 'mediacloth/mediawikilinkhandler'

#Helper module to facilitate MediaCloth usage.
module MediaCloth

  #Parses wiki formatted +input+ and generates its HTML representation.
  def wiki_to_html(input, options={})
    parser = MediaWikiParser.new
    parser.lexer = MediaWikiLexer.new
    tree = parser.parse(input)
    generator = options[:generator] || MediaWikiHTMLGenerator.new
    generator.link_handler = options[:link_handler] if options[:link_handler]
    generator.parse(tree)
  end

  module_function :wiki_to_html

end

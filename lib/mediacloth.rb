require 'mediacloth/mediawikilexer'
require 'mediacloth/mediawikiparser'
require 'mediacloth/mediawikiast'
require 'mediacloth/mediawikiparams'
require 'mediacloth/mediawikiwalker'
require 'mediacloth/mediawikihtmlgenerator'
require 'mediacloth/mediawikisignedwikigenerator'
require 'mediacloth/mediawikilinkhandler'
require 'mediacloth/mediawikitemplatehandler'

#Helper module to facilitate MediaCloth usage.
module MediaCloth

  #Parses wiki formatted +input+ and generates its HTML representation.
  #
  #Can reveive options for customizing the HTML renderer and link_handler. These
  #are the available options:
  #  :generator => An HTML generator (see MediaWikiHTMLGenerator)
  #  :link_handler => A link handler (see MediaWikiLinkHandler)
  #  :template_handler => A template inclusion handler (see MediaWikiTemplateHandler)
  def wiki_to_html(input, options={})
    parser = MediaWikiParser.new
    parser.lexer = MediaWikiLexer.new
    tree = parser.parse(input)
    generator = options[:generator] || MediaWikiHTMLGenerator.new
    generator.link_handler = options[:link_handler] if options[:link_handler]
    generator.template_handler = options[:template_handler] if options[:template_handler]
    generator.params = options[:params] if options[:params]
    generator.parse(tree)
  end

  def wiki_to_signed_wiki(input, options={})
    parser = MediaWikiParser.new
    parser.lexer = MediaWikiLexer.new
    tree = parser.parse(input)
    generator = MediaWikiSignedWikiGenerator.new
    generator.link_handler = options[:link_handler] if options[:link_handler]
    generator.template_handler = options[:template_handler] if options[:template_handler]
    generator.params = options[:params] if options[:params]
    generator.parse(tree, input)
    generator.signed_wiki
  end

  module_function :wiki_to_html, :wiki_to_signed_wiki

end

require 'rubygems'
require 'builder'

# A link handler is responsible for resolving the URL and generating the HTML
# code linking to pages and other resources (images and media, for example)
# based on a wiki short name.
#
# This is the default link handler. A custom link handler will usually extend
# this class and provide the needed functionality by overriding some of the
# methods. The custom handler can be injected into an HTML generator via the
# link_handler= method. See MediaWikiHTMLGenerator for details.
class MediaWikiLinkHandler
  
  #Method invoked to resolve references to wiki pages when they occur in an
  #internal link. In all the following internal links, the page name is
  #<tt>My Page</tt>:
  #* <tt>[[My Page]]</tt>
  #* <tt>[[My Page|Click here to view my page]]</tt>
  #* <tt>[[My Page|Click ''here'' to view my page]]</tt>
  #The return value should be an URL that references the page resource
  def url_for(page)
    "javascript:void(0)"
  end

  #Provides a hash with the attributes for page links. The options provided
  #here will be added to the 'a' tag attributes and overwrite any options
  #provided by the url_for method. If this method needs to be overriden, an URL
  #reference must be provided here indexed by the <tt>:href</tt> symbol.
  def link_attributes_for(page)
     { :href => url_for(page) }
  end

  #Renders a link to a wiki page as a string. The default behaviour is to
  #return an 'a' tag, but any string can be used here like span, or bold
  #tags. This method overwrites anything provided by the <tt>url_for</tt>,
  #<tt>options_for</tt> or <tt>link_attributes_for</tt> methods.
  def link_for(page, text)
    elem.a(link_attributes_for(page)) { |x| x << text }
  end

  #Method invoked to resolve references to resources of unknown types. The
  #type is indicated by the resource prefix. Examples of inline links to
  #unknown references include:
  #* <tt>[[Media:video.mpg]]</tt> (prefix <tt>Media</tt>, resource <tt>video.mpg</tt>)
  #* <tt>[[Image:pretty.png|100px|A ''pretty'' picture]]</tt> (prefix <tt>Image</tt>,
  #  resource <tt>pretty.png</tt>, and options <tt>100px</tt> and <tt>A
  #  <i>pretty</i> picture</tt>.
  #The return value should be a well-formed hyperlink, image, object or 
  #applet tag.
  def link_for_resource(prefix, resource, options=[])
    "<a href=\"javascript:void(0)\">#{prefix}:#{resource}(#{options.join(', ')})</a>"
  end

protected

  def elem
    Builder::XmlMarkup.new
  end

end


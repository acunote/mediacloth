require 'mediacloth/mediawikiwalker'
require 'mediacloth/mediawikiparams'

#HTML generator for a MediaWiki parse tree
#
#Typical use case:
# parser = MediaWikiParser.new
# parser.lexer = MediaWikiLexer.new
# ast = parser.parse(input)
# walker = MediaWikiHTMLGenerator.new
# walker.parse(ast)
# puts walker.html
class MediaWikiHTMLGenerator < MediaWikiWalker
    attr_reader :html

    def initialize
        @html = ""
    end

    def parse(ast)
        @html = super(ast)
    end
    
    #The default link handler. A custom link handler may extend this class.
    class MediaWikiLinkHandler
      
      #Method invoked to resolve references to wiki pages when they occur in an
      #internal link. In all the following internal links, the page name is
      #<tt>My Page</tt>:
      #* <tt>[[My Page]]</tt>
      #* <tt>[[My Page|Click here to view my page]]</tt>
      #* <tt>[[My Page|Click ''here'' to view my page]]</tt>
      #The return value should be a URL that references the page resource.
      def url_for(resource)
        "javascript:void(0)"
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
      def link_for(prefix, resource, options=[])
        "<a href=\"javascript:void(0)\">#{prefix}:#{resource}(#{options.join(', ')})</a>"
      end
    end
    
    #Set this generator's URL handler.
    def link_handler=(handler)
      @link_handler = handler
    end
    
    #Returns's this generator URL handler. If no handler was set, returns the default
    #handler.
    def link_handler
      @link_handler ||= MediaWikiLinkHandler.new
    end

protected

    def parse_wiki_ast(ast)
        super(ast).join
    end

    def parse_paragraph(ast)
        if ast.children
            "<p>" + super(ast) + "</p>"
        else
            "<p><br /></p>"
        end
    end

    def parse_text(ast)
        if ast.formatting
            case(ast.formatting)
            when :None then escape(ast.contents)
            when :CharacterEntity then "&#{ast.contents};"
            when :HLine then "<hr></hr>"
            when :SignatureDate then MediaWikiParams.instance.time.to_s
            when :SignatureName then MediaWikiParams.instance.author
            when :SignatureFull then MediaWikiParams.instance.author + " " + MediaWikiParams.instance.time.to_s
            end
        else
            escape(ast.contents)
        end
    end

    def parse_formatted(ast)
        tag = ast.formatting == :Bold ? 'b' : 'i'
        "<#{tag}>" + super(ast) + "</#{tag}>"
    end

    def parse_list(ast)
        tag = list_tag(ast)
        (["<#{tag}>"] +
         super(ast) +
         ["</#{tag}>"]).join
    end

    def parse_list_item(ast)
        "<li>" + super(ast) + "</li>"
    end

    def parse_list_term(ast)
        "<dt>" + super(ast) + "</dt>"
    end

    def parse_list_definition(ast)
        "<dd>" + super(ast) + "</dd>"
    end

    def parse_preformatted(ast)
        "<pre>" + super(ast) + "</pre>"
    end

    def parse_section(ast)
        "<h#{ast.level}>" + super(ast) + "</h#{ast.level}>"
    end
    
    def parse_internal_link(ast)
        text = parse_wiki_ast(ast)
        text = escape(ast.locator) if text.length == 0
        href = link_handler.url_for(ast.locator)
        "<a href=\"#{href}\">#{text}</a>"
    end
     
    def parse_resource_link(ast)
        options = ast.children.map do |node|
            parse_internal_link_item(node)
        end
        link_handler.link_for(ast.prefix, ast.locator, options)
    end

    def parse_internal_link_item(ast)
        text = super(ast)
        text.strip
    end
    
    def parse_link(ast)
        text = super(ast)
        href = ast.url
        text = escape(href) if text.length == 0
        "<a href=\"#{href}\">#{text}</a>"
    end

    #Reimplement this
    def parse_table(ast)
        options = ast.options ? ' ' + ast.options.strip : ''
        "<table#{options}>" + super(ast) + "</table>\n"
    end

    #Reimplement this
    def parse_table_row(ast)
        options = ast.options ? ' ' + ast.options.strip : ''
        "<tr#{options}>" + super(ast) + "</tr>\n"
    end

    #Reimplement this
    def parse_table_cell(ast)
        if ast.type == :head
            "<th>" + super(ast) + "</th>"
        else
            "<td>" + super(ast) + "</td>"
        end
    end

    def parse_element(ast)
      attr = ''
      if ast.attributes
        attr = ' ' + ast.attributes.collect{ |name, value|
          name + '="' + escape(value) + '"' }.join(' ')
      end
      if ast.children.size == 0
        "<#{ast.name}#{attr} />"
      else
        "<#{ast.name}#{attr}>" + super(ast) + "</#{ast.name}>"
      end
    end

    #returns a tag name of the list in ast node
    def list_tag(ast)
        if ast.list_type == :Bulleted
            return "ul"
        elsif ast.list_type == :Numbered
            return "ol"
        elsif ast.list_type == :Dictionary
            return "dl"
        end
    end
    
    #returns the string with '<', '>', '&' and '"' escaped as XHTML character entities
    def escape(str)
        r = str.gsub(%r{[<>&"]}) do
            |match|
            case match
            when '<' then '&lt;'
            when '>' then '&gt;'
            when '&' then '&amp;'
            when '"' then '&quot;'
            end
        end
        r
    end

end

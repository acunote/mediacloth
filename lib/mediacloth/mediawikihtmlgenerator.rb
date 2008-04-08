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

    def parse(ast)
        @html = ""
        @ast = ast
        @html = super(ast)
    end
    
    #Set this generator's URL handler.
    def link_handler=(handler)
      @link_handler = handler
    end
    
    #Returns's this generator URL handler. If no handler was set, returns the
    #default handler.
    def link_handler
      @link_handler ||= MediaWikiLinkHandler.new
    end
    
    # Utility method that returns the string with '<', '>', '&' and '"' escaped as 
    # XHTML character entities
    def MediaWikiHTMLGenerator.escape(str)
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
    
    # Utility method that converts the string specified into a specially formatted text
    # string which can be used as an XHTML link anchor name.
    def MediaWikiHTMLGenerator.anchor_for(str)
      str.strip.squeeze(' ').gsub(' ', '_')
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
            when :None then MediaWikiHTMLGenerator.escape(ast.contents)
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
        generator = TextGenerator.new
        anchor = MediaWikiHTMLGenerator.anchor_for(generator.parse(ast).join(' '))
        "<h#{ast.level}><a name='#{anchor}'></a>" + super(ast) + "</h#{ast.level}>"
    end
    
    def parse_internal_link(ast)
        text = parse_wiki_ast(ast)
        text = MediaWikiHTMLGenerator.escape(ast.locator) if text.length == 0
        link_handler.link_for(ast.locator, text)
    end
     
    def parse_resource_link(ast)
        options = ast.children.map do |node|
            parse_internal_link_item(node)
        end
        link_handler.link_for_resource(ast.prefix, ast.locator, options)
    end

    def parse_category_link(ast)
        text = parse_wiki_ast(ast)
        text = MediaWikiHTMLGenerator.escape(ast.locator) if text.length == 0
        link_handler.link_for_category(ast.locator, text)
    end

    def parse_category(ast)
      text = parse_wiki_ast(ast)
      link_handler.category_add(ast.locator, ast.sort_as)
    end

    def parse_internal_link_item(ast)
        text = super(ast)
        text.strip
    end
    
    def parse_link(ast)
        text = super(ast)
        href = ast.url
        text = MediaWikiHTMLGenerator.escape(href) if text.length == 0
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
          name + '="' + MediaWikiHTMLGenerator.escape(value) + '"' }.join(' ')
      end
      if ast.children.size == 0
        "<#{ast.name}#{attr} />"
      else
        "<#{ast.name}#{attr}>" + super(ast) + "</#{ast.name}>"
      end
    end
    
    def parse_keyword(ast)
      if ast.text == 'TOC'
        generator = TocGenerator.new
        generator.parse(@ast)
        generator.html
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
    
    # AST walker that generates a table of contents, containing links to all
    # section headings in the page.
    class TocGenerator < MediaWikiHTMLGenerator

        def parse(ast)
            @html = ''
            @text_generator = TextGenerator.new
            @counter = []
            @level = 0
            ast.children.each do
              |child|
              if child.class == SectionAST
                @html += parse_section(child)
              end
            end
            while @level > 0 do
              @html += '</ul>'
              @level -= 1
            end
        end
      
        protected

        def parse_section(ast)
            level = ast.level
            html = ''
            while @level > level do
              html += '</ul>'
              @level -= 1
            end
            while @level < level do
              @counter[@level] = 0
              html += '<ul>'
              @level += 1
            end
            @counter[@level - 1] += 1
            anchor = MediaWikiHTMLGenerator.anchor_for(@text_generator.parse(ast).join(' '))
            html += "<li>#{@counter[0 ... @level].join('.')} <a href='##{anchor}'>#{parse_wiki_ast(ast)}</a></li>\n"
            html
        end
    
    end
    
      
    # AST walker that outputs just the text portions of a page.
    class TextGenerator < MediaWikiWalker

        protected
        
        def parse_text(ast)
            MediaWikiHTMLGenerator.escape(ast.contents)
        end
    
    end

end

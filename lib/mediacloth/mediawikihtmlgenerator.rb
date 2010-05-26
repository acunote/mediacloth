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
      str.strip.squeeze(' ').gsub(' ', '_').gsub('\'', '_')
    end

    
protected

    def parse_wiki_ast(ast)
        super(ast).join
    end

    def parse_paragraph(ast)
        if (children = ast.children)
          if children.size == 1 and ((text = children.first.contents) == "\n\n" || text == "\r\n\r\n")
            "<p><br />#{text}</p>"
          else
            "<p>#{super(ast)}</p>"
          end
        else
            "<p><br /></p>"
        end
    end

    def parse_paste(ast)
        return '' unless ast.children
        "<div class=\"paste\" style=\"white-space: pre-wrap;\">#{super(ast)}</div>"
    end

    def parse_text(ast)
        if ast.formatting
            case(ast.formatting)
            when :None then MediaWikiHTMLGenerator.escape(ast.contents)
            when :CharacterEntity then "&#{ast.contents};"
            when :HLine then "<hr></hr>"
            when :SignatureDate then @params.time.to_s
            when :SignatureName then link_handler.link_for("User:#{@params.author}", @params.author)
            when :SignatureFull then "#{link_handler.link_for("User:#{@params.author}", @params.author)} #{@params.time.to_s}"
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
        if ast.indented 
            original_text = super(ast)
            lines = original_text.split("\n").sort
            shortest_space = lines.last.scan(/^\s+/)[0]
            contents = ""
            if shortest_space
                original_text.each do |line|
                    contents << line.sub(shortest_space, "")
                end
            else
                contents = original_text
            end
            "<pre class=\"indent\">" + contents + "</pre>"
        else
            "<pre>" + super(ast) + "</pre>"
        end
    end

    def parse_section(ast)
        generator = TextGenerator.new
        anchor = MediaWikiHTMLGenerator.anchor_for(generator.parse(ast).join(' '))
        "<h#{ast.level}><a name='#{anchor}'></a>" + super(ast) + "</h#{ast.level}>\n"
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

    def parse_template(ast)
        parameters = ast.children.map do |node|
            if node.parameter_value
                node.parameter_value
            else
                parse_template(node.children.first)
            end
        end
        template_handler.included_template(ast.template_name, parameters)
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
        link_handler.absolute_link_for(href, text, ast.link_type)
    end

    #Reimplement this
    def parse_table(ast)
        options = ast.options ? ' ' + ast.options.strip : ''
        options << ' cellpadding="5"' unless options.include?('cellpadding')
        options << ' border="1"' unless options.include?('border')
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
            if ast.attributes
                "<td #{ast.attributes.first.contents}>" + super(ast) + "</td>"
            else
                "<td>" + super(ast) + "</td>"
            end
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

        class TocNode
            attr_accessor :children
            attr_accessor :parent
            attr_accessor :section
            def initialize
                @children = []
            end

            def add_child(child)
                @children << child
                child.parent = self
            end

            def level
                res = 0
                node = self
                while p = node.parent
                    res += 1
                    node = p
                end
                res
            end

            def number
                res = ''
                node = self
                while p = node.parent
                    res = "#{p.children.index(node)+1}." + res
                    node = p
                end
                res
            end
        end

        def parse(ast)
            @html = ''
            @text_generator = TextGenerator.new

            root = TocNode.new
            root_stack = [root]

            parse_branch = lambda do |ast| 
                ast.children.each do |child|
                    if child.class == SectionAST
                        root_stack.pop while child.level <= ((sec = root_stack.last.section) ? sec.level : 0)

                        node = TocNode.new
                        node.section = child
                        root_stack.last.add_child(node)

                        root_stack.push node
                    end
                    parse_branch.call(child)
                end
            end
            parse_branch.call(ast)

            @html += parse_section(root)
            @html = "<div class=\"wikitoc\">\n<div class=\"wikitoctitle\">Contents</div>#{@html}\n</div>\n" if @html != ''
        end

        protected

        def parse_section(toc_node)
            html = ''
            if toc_node.section
                anchor = MediaWikiHTMLGenerator.anchor_for(@text_generator.parse(toc_node.section).join(' '))
                html += "\n<li><a href='##{anchor}'><span class=\"wikitocnumber\">#{toc_node.number}</span><span class=\"wikitoctext\">#{parse_wiki_ast(toc_node.section).strip}</span></a>"
            end

            unless toc_node.children.empty?
                html += "\n<ul>"
                toc_node.children.each do |child_node|
                    html += parse_section(child_node)
                end
                html += "\n</ul>"
            end

            html += "</li>" if html[0,4] == "<li>"
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

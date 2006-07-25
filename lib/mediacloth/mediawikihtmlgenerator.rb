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

protected

    def parse_wiki_ast(ast)
        super(ast)
    end

    def parse_paragraph(ast)
        @html += "<p>"
        super(ast)
        @html += "</p>"
    end

    def parse_text(ast)
        tag = formatting_to_tag(ast)
        if tag[0].empty?
            @html += ast.contents
        else
            @html += "<#{tag[0]}#{tag[1]}>#{ast.contents}</#{tag[0]}>"
        end
        super(ast)
    end

    def parse_formatted(ast)
        tag = formatting_to_tag(ast)
        @html += "<#{tag}>"
        super(ast)
        @html += "</#{tag}>"
    end

    def parse_list(ast)
        tag = list_tag(ast)
        @html += "<#{tag}>"
        super(ast)
        @html += "</#{tag}>"
    end

    def parse_list_item(ast)
        @html += "<li>"
        super(ast)
        @html += "</li>"
    end

    def parse_preformatted(ast)
        super(ast)
    end

    def parse_section(ast)
        @html += "<h#{ast.level}>"
        @html += ast.contents.strip
        @html += "</h#{ast.level}>"
        super(ast)
    end

private

    #returns an array with a tag name and tag attributes
    def formatting_to_tag(ast)
        tag = ["", ""]
        if ast.formatting == :Bold
            tag = ["b", ""]
        elsif ast.formatting == :Italic
            tag = ["i", ""]
        elsif ast.formatting == :Link or ast.formatting == :ExternalLink
            links = ast.contents.split
            link = links[0]
            link_name = links[1, links.length-1].join(" ")
            link_name = link if link_name.empty?
            ast.contents = link_name
            tag = ["a", " href=\"#{link}\" rel=\"nofollow\""]
        elsif ast.formatting == :HLine
            ast.contents = ""
            tag = ["hr", ""]
        elsif ast.formatting == :SignatureDate
            ast.contents = MediaWikiParams.instance.time.to_s
        elsif ast.formatting == :SignatureName
            ast.contents = MediaWikiParams.instance.author
        elsif ast.formatting == :SignatureFull
            ast.contents = MediaWikiParams.instance.author + " " + MediaWikiParams.instance.time.to_s
        end
        tag
    end

    #returns a tag name of the list in ast node
    def list_tag(ast)
        if ast.list_type == :Bulleted
            return "ul"
        elsif ast.list_type == :Numbered
            return "ol"
        end
    end

end

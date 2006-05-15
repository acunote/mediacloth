require 'mediawikiwalker'

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

    def parseWikiAST(ast)
        super(ast)
    end

    def parseText(ast)
        tag = formattingToTag(ast)
        if tag[0].empty?
            @html += ast.contents
        else
            @html += "<#{tag[0]}#{tag[1]}>#{ast.contents}</#{tag[0]}>"
        end
        super(ast)
    end

    def parseList(ast)
        tag = listTag(ast)
        @html += "<#{tag}>"
        super(ast)
        @html += "</#{tag}>"
    end

    def parseListItem(ast)
        @html += "<li>"
        super(ast)
        @html += "</li>"
    end

    def parsePreformatted(ast)
        super(ast)
    end

    def parseSection(ast)
        super(ast)
    end

private

    #returns an array with a tag name and tag attributes
    def formattingToTag(ast)
        tag = ["", ""]
        if ast.formatting == :Bold
            tag = ["b", ""]
        elsif ast.formatting == :Italic
            tag = ["i", ""]
        elsif ast.formatting == :Link or ast.formatting == :ExternalLink
            tag = ["a", " href=#{ast.contents.split}"]
        elsif ast.formatting == :HLine
            ast.contents = ""
            tag = ["hr", ""]
        end
        tag
    end

    #returns a tag name of the list in ast node
    def listTag(ast)
        if ast.type == :Bulleted
            return "ul"
        elsif ast.type == :Numbered
            return "ol"
        end
    end

end

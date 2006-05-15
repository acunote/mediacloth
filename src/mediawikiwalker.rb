require 'mediawikiast'

#Default walker to traverse the parse tree.
#
#The walker traverses the entire parse tree and does nothing.
#To implement some functionality during this process, reimplement
#<i>parse...</i> methods and don't forget to call super() to not
#break the walk.
#
#Current implementations: MediaWikiHTMLGenerator, DebugWalker
class MediaWikiWalker

    #Walks through the AST
    def parse(ast)
        parseWikiAST(ast)
    end

protected

#===== reimplement these methods and don't forget to call super() ====#

    #Reimplement this
    def parseWikiAST(ast)
        ast.children.each do |c|
            parseText(c) if c.class == TextAST
            parseList(c) if c.class == ListAST
            parsePreformatted(c) if c.class == PreformattedAST
            parseSection(c) if c.class == SectionAST
        end
    end

    #Reimplement this
    def parseText(ast)
    end

    #Reimplement this
    def parseList(ast)
        ast.children.each do |c|
            parseListItem(c) if c.class == ListItemAST
        end
    end

    #Reimplement this
    def parseListItem(ast)
        parseWikiAST(ast)
    end

    #Reimplement this
    def parsePreformatted(ast)
    end

    #Reimplement this
    def parseSection(ast)
    end

end

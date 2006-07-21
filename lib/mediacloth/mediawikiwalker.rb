require 'mediacloth/mediawikiast'

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
        parse_wiki_ast(ast)
    end

protected

#===== reimplement these methods and don't forget to call super() ====#

    #Reimplement this
    def parse_wiki_ast(ast)
        ast.children.each do |c|
            parse_formatted(c) if c.class == FormattedAST
            parse_text(c) if c.class == TextAST
            parse_list(c) if c.class == ListAST
            parse_preformatted(c) if c.class == PreformattedAST
            parse_section(c) if c.class == SectionAST
            parse_paragraph(c) if c.class == ParagraphAST
        end
    end

    #Reimplement this
    def parse_paragraph(ast)
        parse_wiki_ast(ast)
    end

    #Reimplement this
    def parse_formatted(ast)
        parse_wiki_ast(ast)
    end

    #Reimplement this
    def parse_text(ast)
    end

    #Reimplement this
    def parse_list(ast)
        ast.children.each do |c|
            parse_list_item(c) if c.class == ListItemAST
        end
    end

    #Reimplement this
    def parse_list_item(ast)
        parse_wiki_ast(ast)
    end

    #Reimplement this
    def parse_preformatted(ast)
    end

    #Reimplement this
    def parse_section(ast)
    end

end

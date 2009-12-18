require 'mediacloth/mediawikiwalker'
require 'mediacloth/mediawikiparams'

class MediaWikiSignedWikiGenerator < MediaWikiWalker
    
    attr_reader :signed_wiki
    
    def parse(ast, wiki)
        @signed_wiki = wiki
        #For supporting multiple signatures in wiki
        @index_inc = 0
        super(ast)
    end

protected

    def parse_wiki_ast(ast)
        super(ast).join
    end

    def parse_text(ast)
        if ast.formatting
            case(ast.formatting)
            when :SignatureDate then
                signature = @params.time
                @signed_wiki[ast.index + @index_inc, ast.length] = signature
                @index_inc += signature.length - ast.length
            when :SignatureName then
                signature = link_handler.link_for("User:#{@params.author}", @params.author)
                @signed_wiki[ast.index + @index_inc, ast.length] = signature
                @index_inc += signature.length - ast.length
            when :SignatureFull then
                signature = "#{link_handler.link_for("User:#{@params.author}", @params.author)} #{@params.time}"
                @signed_wiki[ast.index + @index_inc, ast.length] = signature
                @index_inc += signature.length - ast.length
          end
        else
            ast.contents
        end
    end

end

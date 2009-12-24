require 'mediacloth/mediawikiwalker'

#A walker to build textual representation of the parse tree.
#
#Use as any other walker and then query for tree:
# parser = MediaWikiParser.new
# parser.lexer = MediaWikiLexer.new
# ast = parser.parse(input)
# walker = DebugWalker.new
# walker.parse(ast)
# puts walker.tree
class DebugWalker < MediaWikiWalker

    #The textual representation of the parse tree.
    attr_reader :tree

    def initialize
        super
        @tree = ""
        @left_space = 0
    end

protected

    def parse_wiki_ast(ast)
        info(ast)
        @left_space += 1
        super(ast) if ast.children
        @left_space -= 1
    end

    def parse_text(ast)
        info(ast, ast.formatting)
        super(ast)
    end

    def parse_list(ast)
        info(ast, ast.class)
        @left_space += 1
        super(ast)
        @left_space -= 1
    end

    def parse_internal_link(ast)
        info(ast)
        @left_space += 1
        ast.children.map do |c|
            parse_wiki_ast(c)
        end
        @left_space -= 1
    end

    def parse_resource_link(ast)
        info(ast)
        @left_space += 1
        ast.children.map do |c|
            parse_wiki_ast(c)
        end
        @left_space -= 1
    end

    def parse_category_link(ast)
        info(ast)
        @left_space += 1
        ast.children.map do |c|
            parse_wiki_ast(c)
        end
        @left_space -= 1
    end

private
    #Pretty-print ast node information
    def info(ast, *args)
        @tree += "#{"    " * @left_space}#{ast.class}[#{ast.index}, #{ast.length}]"
        if args.length > 0
            @tree += ": "
            args.each { |arg| @tree += "#{arg} " }
        end
        @tree += "\n"
    end

end

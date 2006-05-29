#AST Node
class AST
    attr_accessor :contents
    attr_accessor :parent
    attr_accessor :children

    def initialize
        @children = []
        @parent = nil
        @contents = ""
    end
end

#The root node for all wiki parse trees
class WikiAST < AST

end

#The node to represent a simple or formatted text
class TextAST < AST
    #Currently recognized formatting: :None, :Bold, :Italic, :Link, :InternalLink, :HLine
    attr_accessor :formatting
end

#The node to represent a list
class ListAST < AST
    #Currently recognized types: :Bulleted, :Numbered
    attr_accessor :type
end

#The node to represent a list item
class ListItemAST < AST
end

#The node to represent a section
class SectionAST < AST
end

#The node to represent a preformatted contents
class PreformattedAST < AST
end

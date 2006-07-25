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

#The node to represent paragraph with text inside
class ParagraphAST < AST
end

#The node to represent a simple or formatted text
#with more AST nodes inside.
class FormattedAST < AST
    #Currently recognized formatting: :Bold, :Italic, :Link, :InternalLink, :HLine
    attr_accessor :formatting
end

#The node to represent a simple or formatted text
class TextAST < FormattedAST
    #Currently recognized formatting: :Link, :InternalLink, :HLine
end

#The node to represent a list
class ListAST < AST
    #Currently recognized types: :Bulleted, :Numbered
    attr_accessor :list_type
end

#The node to represent a list item
class ListItemAST < AST
end

#The node to represent a section
class SectionAST < AST
    #The level of the section (1,2,3...) that would correspond to
    #<h1>, <h2>, <h3>, etc.
    attr_accessor :level
end

#The node to represent a preformatted contents
class PreformattedAST < AST
end

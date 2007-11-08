#The parser for the MediaWiki language.
#
#Usage together with a lexer:
# inputFile = File.new("data/input1", "r")
# input = inputFile.read
# parser = MediaWikiParser.new
# parser.lexer = MediaWikiLexer.new
# parser.parse(input)
class MediaWikiParser

token TEXT BOLD_START BOLD_END ITALIC_START ITALIC_END LINK_START LINK_END LINKSEP
    INTLINK_START INTLINK_END INTLINKSEP RESOURCESEP PRE_START PRE_END
    SECTION_START SECTION_END HLINE SIGNATURE_NAME SIGNATURE_DATE SIGNATURE_FULL
    PARA_START PARA_END UL_START UL_END OL_START OL_END LI_START LI_END
    DL_START DL_END DT_START DT_END DD_START DD_END TAG_START TAG_END ATTR_NAME ATTR_VALUE
    TABLE_START TABLE_END ROW_START ROW_END HEAD_START HEAD_END CELL_START CELL_END


rule

wiki:
    repeated_contents
        {
            @nodes.push WikiAST.new
            #@nodes.last.children.insert(0, val[0])
            #puts val[0]
            @nodes.last.children += val[0]
        }
    ;

contents:
      text
        {
            result = val[0]
        }
    | bulleted_list
        {
            result = val[0]
        }
    | numbered_list
        {
            result = val[0]
        }
    | dictionary_list
        {
            list = ListAST.new
            list.list_type = :Dictionary
            list.children = val[0]
            result = list
        }
    | preformatted
        {
            result = val[0]
        }
    | section
        {
            result = val[0]
        }
    | tag
        {
            result = val[0]
        }
    | PARA_START para_contents PARA_END
        {
            p = ParagraphAST.new
            p.children = val[1]
            result = p
        }
    | LINK_START link_contents LINK_END
        {
            l = LinkAST.new
            l.url = val[1][0]
            l.children += val[1][1..-1] if val[1].length > 1
            result = l
        }
    | INTLINK_START TEXT RESOURCESEP TEXT reslink_repeated_contents INTLINK_END
        {
            l = ResourceLinkAST.new
            l.prefix = val[1]
            l.locator = val[3]
            l.children = val[4] unless val[4].nil? or val[4].empty?
            result = l
        }
    | INTLINK_START TEXT intlink_repeated_contents INTLINK_END
        {
            l = InternalLinkAST.new
            l.locator = val[1]
            l.children = val[2] unless val[2].nil? or val[2].empty?
            result = l
        }
    | table
    ;

para_contents: 
        {
            result = nil
        }
    | repeated_contents
        {
            result = val[0]
        }
    ;

tag:
      TAG_START tag_attributes TAG_END 
        {
            if val[0] != val[2] 
                raise Racc::ParseError.new("XHTML end tag #{val[2]} does not match start tag #{val[0]}")
            end
            elem = ElementAST.new
            elem.name = val[0]
            elem.attributes = val[1]
            result = elem
        }
    | TAG_START tag_attributes repeated_contents TAG_END 
        {
            if val[0] != val[3] 
                raise Racc::ParseError.new("XHTML end tag #{val[3]} does not match start tag #{val[0]}")
            end
            elem = ElementAST.new
            elem.name = val[0]
            elem.attributes = val[1]
            elem.children += val[2]
            result = elem
        }
    ;

tag_attributes:
        {
            result = nil
        }
    | ATTR_NAME tag_attributes
        {
            attr_map = val[2] ? val[2] : {}
            attr_map[val[0]] = true
            result = attr_map 
        }
    | ATTR_NAME ATTR_VALUE tag_attributes
        {
            attr_map = val[2] ? val[2] : {}
            attr_map[val[0]] = val[1]
            result = attr_map 
        }
    ;
      

link_contents:
      TEXT
        {
            result = val
        }
    | TEXT LINKSEP link_repeated_contents
        {
            result = [val[0]]
            result += val[2]
        }
    ;


link_repeated_contents:
      repeated_contents
        {
            result = val[0]
        }
    | repeated_contents LINKSEP link_repeated_contents
        {
            result = val[0]
            result += val[2] if val[2]
        }
    ;


intlink_repeated_contents:
        {
            result = nil
        }
    | INTLINKSEP repeated_contents
        {
            result = val[1]
        }
    ;

reslink_repeated_contents:
        {
            result = nil
        }
    | INTLINKSEP reslink_repeated_contents
        {
            result = val[1]
        }
    | INTLINKSEP repeated_contents reslink_repeated_contents
        {
            i = InternalLinkItemAST.new
            i.children = val[1]
            result = [i]
            result += val[2] if val[2]
        }
    ;

repeated_contents: contents
        {
            result = []
            result << val[0]
        }
    | repeated_contents contents
        {
            result = []
            result += val[0]
            result << val[1]
        }
    ;

text: element
        {
            p = TextAST.new
            p.formatting = val[0][0]
            p.contents = val[0][1]
            result = p
        }
    | formatted_element
        {
            result = val[0]
        }
    ;

table:
      TABLE_START table_contents TABLE_END
        {
            table = TableAST.new
            table.children = val[1] unless val[1].nil? or val[1].empty?
            result = table
        }
    | TABLE_START TEXT table_contents TABLE_END
        {
            table = TableAST.new
            table.options = val[1]
            table.children = val[2] unless val[2].nil? or val[2].empty?
            result = table
        }

table_contents:
        {
            result = nil
        }
    | ROW_START row_contents ROW_END table_contents
        {
            row = TableRowAST.new
            row.children = val[1] unless val[1].nil? or val[1].empty?
            result = [row]
            result += val[3] unless val[3].nil? or val[3].empty?
        }
    | ROW_START TEXT row_contents ROW_END table_contents
        {
            row = TableRowAST.new
            row.children = val[2] unless val[2].nil? or val[2].empty?
            row.options = val[1]
            result = [row]
            result += val[4] unless val[4].nil? or val[4].empty?
        }

row_contents:
        {
            result = nil
        }
    | HEAD_START HEAD_END row_contents
        {
            cell = TableCellAST.new
            cell.type = :head
            result = [cell]
            result += val[2] unless val[2].nil? or val[2].empty?
        }
    | HEAD_START repeated_contents HEAD_END row_contents
        {
            cell = TableCellAST.new
            cell.children = val[1] unless val[1].nil? or val[1].empty?
            cell.type = :head
            result = [cell]
            result += val[3] unless val[3].nil? or val[3].empty?
        }
    | CELL_START CELL_END row_contents
        {
            cell = TableCellAST.new
            cell.type = :body
            result = [cell]
            result += val[2] unless val[2].nil? or val[2].empty?
        }
    | CELL_START repeated_contents CELL_END row_contents
        {
            cell = TableCellAST.new
            cell.children = val[1] unless val[1].nil? or val[1].empty?
            cell.type = :body
            result = [cell]
            result += val[3] unless val[3].nil? or val[3].empty?
        }
    

element:
      TEXT
        { return [:None, val[0]] }
    | HLINE
        { return [:HLine, val[0]] }
    | SIGNATURE_DATE
        { return [:SignatureDate, val[0]] }
    | SIGNATURE_NAME
        { return [:SignatureName, val[0]] }
    | SIGNATURE_FULL
        { return [:SignatureFull, val[0]] }
    ;

formatted_element: 
      BOLD_START BOLD_END
        {
            result = FormattedAST.new
            result.formatting = :Bold
            result
        } 
    | ITALIC_START ITALIC_END
        {
            result = FormattedAST.new
            result.formatting = :Italic
            result
        }
    | BOLD_START repeated_contents BOLD_END
        {
            p = FormattedAST.new
            p.formatting = :Bold
            p.children += val[1]
            result = p
        }
    | ITALIC_START repeated_contents ITALIC_END
        {
            p = FormattedAST.new
            p.formatting = :Italic
            p.children += val[1]
            result = p
        }
    ;

bulleted_list: UL_START list_item list_contents UL_END
        {
            list = ListAST.new
            list.list_type = :Bulleted
            list.children << val[1]
            list.children += val[2]
            result = list
        }
    ;

numbered_list: OL_START list_item list_contents OL_END
        {
            list = ListAST.new
            list.list_type = :Numbered
            list.children << val[1]
            list.children += val[2]
            result = list
        }
    ;

list_contents:
        { result = [] }
    list_item list_contents
        {
            result << val[1]
            result += val[2]
        }
    |
        { result = [] }
    ;

list_item: 
      LI_START LI_END
        {
            result = ListItemAST.new
        }
    | LI_START repeated_contents LI_END
        {
            li = ListItemAST.new
            li.children += val[1]
            result = li
        }
    ;

dictionary_list:  
      DL_START dictionary_term dictionary_contents DL_END
        {
            result = [val[1]]
            result += val[2]
        }
    | DL_START dictionary_contents DL_END
        {
            result = val[1]
        }
    ;

dictionary_term:
      DT_START DT_END
        {
            result = ListTermAST.new
        }
    | DT_START repeated_contents DT_END
        {
            term = ListTermAST.new
            term.children += val[1]
            result = term
        }

dictionary_contents:
      dictionary_definition dictionary_contents
        {
            result = [val[0]]
            result += val[1] if val[1]
        }
    |
        {
            result = []
        }

dictionary_definition:
      DD_START DD_END
        {
            result = ListDefinitionAST.new
        }
    | DD_START repeated_contents DD_END
        {
            term = ListDefinitionAST.new
            term.children += val[1]
            result = term
        }

preformatted: PRE_START repeated_contents PRE_END
        {
            p = PreformattedAST.new
            p.children += val[1]
            result = p
        }
    ;

section: SECTION_START repeated_contents SECTION_END
        { result = [val[1], val[0].length] 
            s = SectionAST.new
            s.children = val[1]
            s.level = val[0].length
            result = s
        }
    ;

end

---- header ----
require 'mediacloth/mediawikiast'

---- inner ----

attr_accessor :lexer

def initialize
    @nodes = []
    super
end

#Tokenizes input string and parses it.
def parse(input)
    @yydebug=true
    lexer.tokenize(input)
    do_parse
    return @nodes.last
end

#Asks the lexer to return the next token.
def next_token
    return @lexer.lex
end

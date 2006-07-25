#The parser for the MediaWiki language.
#
#Usage together with a lexer:
# inputFile = File.new("data/input1", "r")
# input = inputFile.read
# parser = MediaWikiParser.new
# parser.lexer = MediaWikiLexer.new
# parser.parse(input)
class MediaWikiParser

token BOLDSTART BOLDEND ITALICSTART ITALICEND LINKSTART LINKEND
    INTLINKSTART INTLINKEND SECTION_START SECTION_END TEXT PRE
    HLINE SIGNATURE_NAME SIGNATURE_DATE SIGNATURE_FULL
    UL_START UL_END LI_START LI_END OL_START OL_END
    PARA_START PARA_END

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
    | preformatted
        {
            p = PreformattedAST.new
            p.contents = val[0]
            result = p
        }
    | section
        {
            s = SectionAST.new
            s.contents = val[0][0]
            s.level = val[0][1]
            result = s
        }
    | PARA_START para_contents PARA_END
        {
            if val[1]
                p = ParagraphAST.new
                p.children = val[1]
                result = p
            end
        }
    ;

#TODO: remove empty paragraphs in lexer
para_contents: 
        {
            result = nil
        }
    | repeated_contents
        {
            result = val[0]
        }

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

element: LINKSTART TEXT LINKEND
        { return [:Link, val[1]] }
    | INTLINKSTART TEXT INTLINKEND
        { return [:InternalLink, val[1]] }
    | TEXT
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

formatted_element: BOLDSTART repeated_contents BOLDEND
        {
            p = FormattedAST.new
            p.formatting = :Bold
            p.children += val[1]
            result = p
        }
    | ITALICSTART repeated_contents ITALICEND
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

list_item: LI_START repeated_contents LI_END
        {
            li = ListItemAST.new
            li.children += val[1]
            result = li
        }
    ;

preformatted: PRE
        { result = val[0] }
    ;

section: SECTION_START TEXT SECTION_END
        { result = [val[1], val[0].length] }
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

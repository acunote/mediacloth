#The parser for the MediaWiki language.
#
#Usage together with a lexer:
# inputFile = File.new("data/input1", "r")
# input = inputFile.read
# parser = MediaWikiParser.new
# parser.lexer = MediaWikiLexer.new
# parser.parse(input)
class MediaWikiParser

token BOLD ITALIC LINKSTART LINKEND
    INTLINKSTART INTLINKEND SECTION TEXT PRE
    HLINE SIGNATURE_NAME SIGNATURE_DATE SIGNATURE_FULL
    UL_START UL_END LI_START LI_END OL_START OL_END

rule

wiki:
        {
            @nodes.push WikiAST.new
        }
    contents wiki
        {
            @nodes.last.children.insert(0, val[1])
        }
    |
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
    | preformatted
        {
            p = PreformattedAST.new
            p.contents = val[0]
            result = p
        }
    | section
        {
            s = SectionAST.new
            s.contents = val[0]
            result = s
        }
    ;

repeated_contents:
        { result = [] }
    contents repeated_contents_cont
        {
            result << val[1]
            result += val[2]
        }
    ;

repeated_contents_cont:
        { result = [] }
    contents repeated_contents_cont
        {
            result << val[1]
            result += val[2]
        }
    |
        { result = [] }
    ;

text: element
        {
            p = TextAST.new
            p.formatting = val[0][0]
            p.contents = val[0][1]
            result = p
        }
    ;

element: BOLD TEXT BOLD
        { return [:Bold, val[1]] }
    | ITALIC TEXT ITALIC
        { return [:Italic, val[1]] }
    | LINKSTART TEXT LINKEND
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

bulleted_list: UL_START list_item list_contents UL_END
        {
            list = ListAST.new
            list.type = :Bulleted
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

section: SECTION TEXT SECTION
        { result = val[1] }
    ;

end

---- header ----
require 'mediawikiast'

---- inner ----

attr_accessor :lexer

def initialize
    @nodes = []
    super
end

#Tokenizes input string and parses it.
#--
#TODO: return AST here
#++
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

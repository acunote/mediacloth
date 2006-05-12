#The parser for the WikiMedia language.
#
#Usage together with a lexer:
# inputFile = File.new("data/input1", "r")
# input = inputFile.read
# parser = WikiMediaParser.new
# parser.lexer = WikiMediaLexer.new
# parser.parse(input)

class WikiMediaParser

token BOLD ITALIC LINKSTART LINKEND
    INTLINKSTART INTLINKEND SECTION TEXT PRE
    HLINE SIGNATURE_NAME SIGNATURE_DATE SIGNATURE_FULL
    UL_START UL_END LI_START LI_END OL_START OL_END

rule

wiki: wiki contents
    |
    ;

contents: paragraph
/*         { puts "paragraph" } */
    | bulleted_list
/*         { puts "bulleted_list" } */
    | preformatted
/*         { puts "preformatted" } */
    | section
/*         { puts "section" } */
    ;

paragraph: element
    | HLINE
/*         { puts val[1] } */
    ;

element: BOLD
    | ITALIC
    | LINKSTART TEXT LINKEND
    | INTLINKSTART TEXT INTLINKEND
    | TEXT
    ;

bulleted_list: UL_START list_item list_contents UL_END
/*         { puts val[0] } */
    ;

list_contents: list_item list_contents
    |
    ;

list_item: LI_START contents LI_END
    ;

preformatted: PRE
/*         { puts val[0] } */
    ;

preformatted_cont: preformatted
    |
    ;

section: SECTION TEXT SECTION
    ;

end

---- inner ----

attr_accessor :lexer

#Tokenizes input string and parses it.
#--
#TODO: return AST here
#++
def parse(input)
    @yydebug=true
    lexer.tokenize(input)
    return do_parse
end

#Asks the lexer to return the next token.
def next_token
    return @lexer.lex
end

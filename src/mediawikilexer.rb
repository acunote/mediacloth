#The lexer for MediaWiki language.
#
#Standalone usage:
# file = File.new("somefile", "r")
# input = file.read
# lexer = MediaWikiLexer.new
# lexer.tokenize(input)
#
#Inside RACC-generated parser:
# ...
# ---- inner ----
# attr_accessor :lexer
# def parse(input)
#     lexer.tokenize(input)
#     return do_parse
# end
# def next_token
#     return @lexer.lex
# end
# ...
# parser = MediaWikiParser.new
# parser.lexer = MediaWikiLexer.new
# parser.parse(input)
class MediaWikiLexer

    #Initialized the lexer with a match table.
    #
    #The match table tells the lexer which method to invoke
    #on given input char during "tokenize" phase.
    def initialize
        @position = 0
        @pairStack = [[false, false]] #stack of tokens for which a pair should be found
        @listStack = []
        @lexerTable = Hash.new(method(:matchOther))
        @lexerTable["'"] = method(:matchItalicOrBold)
        @lexerTable["="] = method(:matchSection)
        @lexerTable["["] = method(:matchLinkStart)
        @lexerTable["]"] = method(:matchLinkEnd)
        @lexerTable[" "] = method(:matchSpace)
        @lexerTable["*"] = method(:matchList)
        @lexerTable["#"] = method(:matchList)
        @lexerTable[";"] = method(:matchList)
        @lexerTable[":"] = method(:matchList)
        @lexerTable["-"] = method(:matchLine)
        @lexerTable["~"] = method(:matchSignature)
    end

    #Transforms input stream (string) into the stream of tokens.
    #Tokens are collected into an array of type [ [TOKEN_SYMBOL, TOKEN_VALUE], ..., [false, false] ].
    #This array can be given as input token-by token to RACC based parser with no
    #modification. The last token [false, false] inficates EOF.
    def tokenize(input)
        @tokens = []
        @cursor = 0
        @text = input
        @nextToken = []

        #This tokenizer algorithm assumes that everything that is not
        #matched by the lexer is going to be :TEXT token. Otherwise it's usual
        #lexer algo which call methods from the match table to define next tokens.
        while (@cursor < @text.length)
            @currentToken = [:TEXT, ''] unless @currentToken
            @tokenStart = @cursor
            @char = @text[@cursor, 1]

            if @lexerTable[@char].call == :TEXT
                @currentToken[1] += @text[@tokenStart, 1]
            else
                #skip empty :TEXT tokens
                @tokens << @currentToken unless emptyTextToken?
                @nextToken[1] = @text[@tokenStart, @cursor - @tokenStart]
                @tokens << @nextToken
                #hack to enable sub-lexing!
                if @subTokens
                    @tokens += @subTokens
                    @subTokens = nil
                end
                #end of hack!
                @currentToken = nil
                @nextToken = []
            end
        end
        #add the last TEXT token if it exists
        @tokens << @currentToken if @currentToken and not emptyTextToken?

        #RACC wants us to put this to indicate EOF
        @tokens << [false, false]
        @tokens
    end

    #Returns the next token from the stream. Useful for RACC parsers.
    def lex
        token = @tokens[@position]
        @position += 1
        return token
    end


private
    #-- ================== Match methods ================== ++#

    #Matches anything that was not matched. Returns :TEXT to indicate
    #that matched characters should go into :TEXT token.
    def matchOther
        @cursor += 1
        return :TEXT
    end

    #Matches italic or bold symbols:
    # "'''"     { return :BOLD; }
    # "''"      { return :ITALIC; }
    def matchItalicOrBold
        if @text[@cursor, 3] == "'''" and @pairStack.last[0] != :ITALIC
            matchBold
            @cursor += 3
            return
        end
        if @text[@cursor, 2] == "''"
            matchItalic
            @cursor += 2
            return
        end
        matchOther
    end

    def matchBold
        @nextToken[0] = :BOLD
        if @pairStack.last[0] == :BOLD
            @pairStack.pop
        else
            @pairStack.push @nextToken
        end
    end

    def matchItalic
        @nextToken[0] = :ITALIC
        if @pairStack.last[0] == :ITALIC
            @pairStack.pop
        else
            @pairStack.push @nextToken
        end
    end

    #Matches sections
    # "=+"  { return SECTION; }
    def matchSection
        if (@text[@cursor-1, 1] == "\n") or (@pairStack.last[0] == :SECTION)
            i = 0
            i += 1 while @text[@cursor+i, 1] == "="
            @cursor += i
            @nextToken[0] = :SECTION

            if @pairStack.last[0] == :SECTION
                @pairStack.pop
            else
                @pairStack.push @nextToken
            end
        else
            matchOther
        end
    end

    #Matches start of the hyperlinks
    # "[["      { return INTLINKSTART; }
    # "["       { return LINKSTART; }
    def matchLinkStart
        if @text[@cursor, 2] == "[["
            @nextToken[0] = :INTLINKSTART
            @cursor += 2
        else
            @nextToken[0] = :LINKSTART
            @cursor += 1
        end
    end

    #Matches end of the hyperlinks
    # "]]"      { return INTLINKEND; }
    # "]"       { return LINKEND; }
    def matchLinkEnd
        if @text[@cursor, 2] == "]]"
            @nextToken[0] = :INTLINKEND
            @cursor += 2
        else
            @nextToken[0] = :LINKEND
            @cursor += 1
        end
    end

    #Matches space to find preformatted areas which start with a space after a newline
    # "\n\s[^\n]*"     { return PRE; }
    def matchSpace
        if atStartOfLine?
            matchUntillEOL
            @nextToken[0] = :PRE
            stripWSFromTokenStart
        else
            matchOther
        end
    end

    #Matches any kind of list by using sublexing technique. MediaWiki lists are context-sensitive
    #therefore we need to do some special processing with lists. The idea here is to strip
    #the leftmost symbol indicating the list from the group of input lines and use separate
    #lexer to process extracted fragment.
    def matchList
        if atStartOfLine?
            listId = @text[@cursor, 1]
            subText = extractListContents(listId)
            extracted = 0

            #hack to tokenize everything inside the list
            @subTokens = []
            subLines = ""
            @subTokens << [:LI_START, ""]
            subText.each do |t|
                extracted += 1
                if textIsList? t
                    subLines += t
                else
                    if not subLines.empty?
                        @subTokens += subLex(subLines)
                        subLines = ""
                    end
                    if @subTokens.last[0] != :LI_START
                        @subTokens << [:LI_END, ""]
                        @subTokens << [:LI_START, ""]
                    end
                    @subTokens += subLex(t.lstrip)
                end
            end
            if not subLines.empty?
                @subTokens += subLex(subLines)
                @subTokens << [:LI_END, ""]
            else
                @subTokens << [:LI_END, ""]
            end

            #end of hack
            @cursor += subText.length + extracted
            @tokenStart = @cursor

            case
                when listId == "*"
                    @nextToken[0] = :UL_START
                    @subTokens << [:UL_END, ""]
                when listId == "#"
                    @nextToken[0] = :OL_START
                    @subTokens << [:OL_END, ""]
                when listId == ";", listId == ":"
                    @nextToken[0] = :DL_START
                    @subTokens << [:DL_END, ""]
            end

        else
            matchOther
        end
    end

    #Matches the line until \n
    def matchUntillEOL
        val = @text[@cursor, 1]
        while (val != "\n") and (!val.nil?)
            @cursor += 1
            val = @text[@cursor, 1]
        end
        @cursor += 1
    end

    #Matches hline tag that start with "-"
    # "\n----"      { return HLINE; }
    def matchLine
        if atStartOfLine? and @text[@cursor, 4] == "----"
            @nextToken[0] = :HLINE
            @cursor += 4
        else
            matchOther
        end
    end

    #Matches signature
    # "~~~~~"      { return SIGNATURE_DATE; }
    # "~~~~"      { return SIGNATURE_FULL; }
    # "~~~"      { return SIGNATURE_NAME; }
    def matchSignature
        if @text[@cursor, 5] == "~~~~~"
            @nextToken[0] = :SIGNATURE_DATE
            @cursor += 5
        elsif @text[@cursor, 4] == "~~~~"
            @nextToken[0] = :SIGNATURE_FULL
            @cursor += 4
        elsif @text[@cursor, 3] == "~~~"
            @nextToken[0] = :SIGNATURE_NAME
            @cursor += 3
        else
            matchOther
        end
    end

    #-- ================== Helper methods ================== ++#

    #Checks if the token is placed at the start of the line.
    def atStartOfLine?
        if @cursor == 0 or @text[@cursor-1, 1] == "\n"
            true
        else
            false
        end
    end

    #Adjusts @tokenStart to skip leading whitespaces
    def stripWSFromTokenStart
        @tokenStart += 1 while @text[@tokenStart, 1] == " "
    end

    #Returns true if the TEXT token is empty or contains newline only
    def emptyTextToken?
        @currentToken == [:TEXT, ''] or @currentToken == [:TEXT, "\n"]
    end

    #Returns true if the text is a list, i.e. starts with one of #;*: symbols
    #that indicate a list
    def textIsList?(text)
        return text =~ /^[#;*:].*/
    end

    #Runs sublexer to tokenize subText
    def subLex(subText)
        subLexer = MediaWikiLexer.new
        subTokens = subLexer.tokenize(subText)
        subTokens.pop
        subTokens
    end

    #Extract list contents of list type set by listId variable.
    #Example list:
    # *a
    # **a
    #Extracted list with id "*" will look like:
    # a
    # *a
    def extractListContents(listId)
        i = @cursor+1
        list = ""
        while i < @text.length
            curr = @text[i, 1]
            if (curr == "\n") and (@text[i+1, 1] != listId)
                list+=curr
                break
            end
            list += curr unless (curr == listId) and (@text[i-1, 1] == "\n")
            i += 1
        end
        list
    end

end


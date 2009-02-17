require 'strscan'
  
class String
  def is_empty_token?
    self.size == 0 or self == "\n" or self == "\r\n"
  end
end


class MediaWikiLexer
  
  INLINE_ELEMENTS = [:LINK, :INTLINK, :BOLD, :ITALIC]
  BLOCK_ELEMENTS = [:PARA, :PRE, :UL, :OL, :DL, :LI, :SECTION, :TABLE, :ROW, :CELL, :HEAD]
  PARA_BREAK_ELEMENTS = [:UL, :OL, :DL, :PRE, :PASTE_START, :SECTION, :TABLE, :HLINE, :KEYWORD]
  
  NAME_CHAR_TABLE = (0 .. 255).collect{|n| n.chr =~ /[a-zA-Z0-9_\-]/ ? true : false}
  TOKEN_CHAR_TABLE = (0 .. 255).collect{|n| n.chr =~ /[a-zA-Z0-9_\-.;:?&~=#%\/]/ ? true : false}


  HTML_TAGS = %w{ a abbr acronym address applet area b base basefont bdo big blockquote body br
    button caption center cite code col colgroup dd del dir div dfn dl dt em fieldset font form frame
    frameset h1 h2 h3 h4 h5 h6 head hr html i iframe img input ins isindex kbd label legend li link map
    menu meta noframes noscript object ol optgroup option p param pre q s samp script select small span
    strike strong style sub sup table tbody td textarea tfoot th thead title tr tt u ul var xmp }
  WIKI_TAGS = %w{ nowiki math paste }
  TAGS_WITHOUT_CLOSE_TAG = %w{ br hr img }

  
  def initialize
    # Current position in token list
    @position = 0
    
    # Lexer table of methods that handle only formatting, e.g. bold or italicized
    # text; or spans of XHTML, or wiki-escape, markup
    @formatting_lexer_table = {}
    @formatting_lexer_table["'"] = method(:match_quote)
    @formatting_lexer_table["<"] = method(:match_left_angle)
    @formatting_lexer_table["&"] = method(:match_ampersand)
    @formatting_lexer_table["{"] = method(:match_left_curly)
    
    # Lexer table of methods that handle everything that may occur in-line in
    # addition to formatting, i.e. links and signatures
    @inline_lexer_table = @formatting_lexer_table.dup
    @inline_lexer_table["["] = method(:match_left_square)
    @inline_lexer_table["~"] = method(:match_tilde)
    @inline_lexer_table["h"] = method(:match_h_char)
        
    # Default lexer table, which includes all in-line formatting and links, plus
    # methods that handle constructs that begin on a newline
    @default_lexer_table = @inline_lexer_table.dup
    @default_lexer_table[" "] = method(:match_space)
    @default_lexer_table["="] = method(:match_equal)
    @default_lexer_table["*"] = method(:match_star)
    @default_lexer_table["#"] = method(:match_hash)
    @default_lexer_table[":"] = method(:match_colon)
    @default_lexer_table[";"] = method(:match_semicolon)
    @default_lexer_table["-"] = method(:match_dash)
    @default_lexer_table["_"] = method(:match_underscore)
    @default_lexer_table["\n"] = method(:match_newline)
    @default_lexer_table["\r"] = method(:match_newline)
    
    # Lexer table used inside spans of markup, wherein spans of newlines are not
    # automatically treated as paragraphs.
    @markup_lexer_table = @default_lexer_table.dup
    @markup_lexer_table["\n"] = nil
    @markup_lexer_table["\r"] = nil
    
    # Lexer table used inside of headings
    @heading_lexer_table = @inline_lexer_table.dup
    @heading_lexer_table["="] = method(:match_equal_in_heading)
    @heading_lexer_table["\n"] = method(:match_newline_in_heading)
    
    # Lexer table used inside the left half of an external link
    @link_lexer_table = {}
    @link_lexer_table["]"] = method(:match_right_square_in_link)
    @link_lexer_table["\n"] = method(:match_newline_in_link)
    @link_lexer_table["\r"] = method(:match_newline_in_link)
    @link_lexer_table[" "] = method(:match_space_in_link)
    
    # Lexer table used inside the right half of an external link, or the right
    # half of an internal link
    @link_opt_lexer_table = @inline_lexer_table.dup
    @link_opt_lexer_table["]"] = method(:match_right_square_in_link)
    @link_opt_lexer_table["\n"] = method(:match_newline_in_link)
    @link_opt_lexer_table["\r"] = method(:match_newline_in_link)
    
    # Lexer table used inside the left half of an internal link or internal
    # resource link
    @intlink_lexer_table = {}
    @intlink_lexer_table["]"] = method(:match_right_square_in_intlink)
    @intlink_lexer_table["\r"] = method(:match_newline_in_intlink)
    @intlink_lexer_table["\n"] = method(:match_newline_in_intlink)
    @intlink_lexer_table[":"] = method(:match_colon_in_intlink)
    @intlink_lexer_table["|"] = method(:match_pipe_in_intlink)
    @intlink_lexer_table["C"] = method(:match_c_char_in_intlink)
    
    # Lexer table used inside the category name of the left half of an 
    # internal link
    @intlink_cat_lexer_table = {}
    @intlink_cat_lexer_table["]"] = method(:match_right_square_in_intlink)
    @intlink_cat_lexer_table["\r"] = method(:match_newline_in_intlink)
    @intlink_cat_lexer_table["\n"] = method(:match_newline_in_intlink)
    @intlink_cat_lexer_table["|"] = method(:match_pipe_in_intlink)    
    
    # Lexer table used inside the right half of an internal link
    @intlink_opt_lexer_table = @formatting_lexer_table.dup
    @intlink_opt_lexer_table["]"] = method(:match_right_square_in_intlink)
    @intlink_opt_lexer_table["\n"] = method(:match_newline_in_intlink)
    @intlink_opt_lexer_table["\r"] = method(:match_newline_in_intlink)
    
    # Lexer table used inside the right half of an internal resource link
    @resourcelink_opt_lexer_table = @inline_lexer_table.dup
    @resourcelink_opt_lexer_table["]"] = method(:match_right_square_in_intlink)
    @resourcelink_opt_lexer_table["\n"] = method(:match_newline_in_intlink)
    @resourcelink_opt_lexer_table["\r"] = method(:match_newline_in_intlink)
    @resourcelink_opt_lexer_table["|"] = method(:match_pipe_in_intlink)
    
    # Lexer table used to parse tables
    @table_lexer_table = @inline_lexer_table.dup
    @table_lexer_table["*"] = method(:match_star)
    @table_lexer_table["#"] = method(:match_hash)
    @table_lexer_table["|"] = method(:match_pipe_in_table)
    @table_lexer_table["!"] = method(:match_bang_in_table)
    @table_lexer_table["{"] = method(:match_left_curly)
    @table_lexer_table[" "] = method(:match_space)
    
    # Lexer table used to parse ordered and unordered list items (which may nest)
    @items_lexer_table = @inline_lexer_table.dup
    @items_lexer_table["\n"] = method(:match_newline_in_items)
    
    # Lexer table used to parse entries in a definition list (which may not nest)
    @entries_lexer_table = @inline_lexer_table.dup
    @entries_lexer_table["\n"] = method(:match_newline_in_entries)
    @entries_lexer_table[":"] = method(:match_colon_in_entries)
    
    # Lexer table used inside spans of indented text
    @indent_lexer_table = @inline_lexer_table.dup
    @indent_lexer_table["\n"] = method(:match_newline_in_indent)
    
    # Lexer table used inside spans of pre-formatted text
    @pre_lexer_table = {}
    @pre_lexer_table["<"] = method(:match_left_angle_in_pre)
        
    # Lexer table used inside spans of <code>
    @code_lexer_table = @inline_lexer_table.dup
    @code_lexer_table[" "] = method(:match_space_in_code)
    @code_lexer_table["<"] = method(:match_left_angle_in_code)

    # Lexer table used when inside spans of wiki-escaped text
    @nowiki_lexer_table = {}
    @nowiki_lexer_table["<"] = method(:match_left_angle_in_nowiki)

    @paste_lexer_table = {}
    @paste_lexer_table["<"] = method(:match_left_angle_in_paste)
    @paste_lexer_table["\n"] = method(:match_newline_in_paste)
    @paste_lexer_table["\r"] = method(:match_newline_in_paste)

    # Lexer table used when inside spans of math
    @math_lexer_table = {}
    @math_lexer_table["<"] = method(:match_left_angle_in_math)
        
    # Lexer table used when inside a wiki template inclusion
    @template_lexer_table = {}
    @template_lexer_table["{"] = method(:match_left_curly_in_template)
    @template_lexer_table["|"] = method(:match_pipe_in_template)
    @template_lexer_table["}"] = method(:match_right_curly_in_template)
        
    @template_param_lexer_table = {}
    @template_param_lexer_table["{"] = method(:match_left_curly_in_template)
    @template_param_lexer_table["}"] = method(:match_right_curly_in_template)
    @template_param_lexer_table["|"] = method(:match_pipe_in_template)
        
    # Begin lexing in default state
    @lexer_table = LexerTable.new
    @lexer_table.push(@default_lexer_table)
  end

  
  def tokenize(input)
    @text = input
    # Current position in the input text
    @cursor = 0
    # Tokens to be returned
    @tokens = []
    # Stack of open token spans
    @context = []
    # Already lexed character data, not yet added to a TEXT token
    @pending = ''
    # List symbols from the most recent line item of a list, e.g. '***'
    @list = ''
        
    start_span(:PARA)
        
    while (@cursor < @text.length)
      @char = @text[@cursor, 1]
      if @lexer_table[@char]
        @lexer_table[@char].call
      else
        @pending << @char
        @cursor += 1
      end
    end
    
    if @pending.is_empty_token?
      if @context.size > 0 and @tokens.last[0] == :PARA_START
        @context.pop
        @tokens.pop 
      end
    else
      @tokens << [:TEXT, @pending]
      @pending = ''
    end
    while(@context.size > 0) do
      @tokens << [(@context.pop.to_s + '_END').to_sym, '']
    end
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
  
  def match_text
    @pending << @char
    @cursor += 1
  end
  
  def match_ampersand
    i = @cursor + 1
    i += 1 while i < @text.size and NAME_CHAR_TABLE[@text[i]]
    if @text[i, 1] == ';'
      append_to_tokens([:CHAR_ENT, @text[(@cursor + 1) ... i]])
      @cursor = i + 1
    else
      match_text
    end
  end
  
  def match_quote
    if @text[@cursor, 5] == "'''''"
      if @context.last == :BOLD
        match_bold
        @cursor += 3
      else
        match_italic
        @cursor += 2
      end
    elsif @text[@cursor, 3] == "'''"
      match_bold
      @cursor += 3
    elsif @text[@cursor, 2] == "''"
      match_italic
      @cursor += 2
    else
      match_text
    end
  end

  def match_bold
    if @context.last == :BOLD
      end_span(:BOLD, "'''")
    else
      start_span(:BOLD, "'''")
    end
  end

  def match_italic
    if @context.last == :ITALIC
      end_span(:ITALIC, "''")
    else
      start_span(:ITALIC, "''")
    end
  end

  def match_tilde
    if @text[@cursor, 5] == "~~~~~"
      empty_span(:SIGNATURE_DATE, "~~~~~")
      @cursor += 5
    elsif @text[@cursor, 4] == "~~~~"
      empty_span(:SIGNATURE_FULL, "~~~~")
      @cursor += 4
    elsif @text[@cursor, 3] == "~~~"
      empty_span(:SIGNATURE_NAME, "~~~")
      @cursor += 3
    else
      match_text
    end
  end
    
  def match_left_angle
    next_char = @text[@cursor + 1]
    if next_char == 47
      # Might be an XHTML end tag
      if @text[@cursor .. -1] =~ %r{</([a-zA-Z][a-zA-Z0-9\-_]*)(\s*)>} and @context.include?(:TAG)
        # Found an XHTML end tag
        tag_name = $1
        end_span(:TAG, $1)
        @lexer_table.pop
        @cursor += $1.length + $2.length + 3
      else
        match_text
      end
    elsif next_char > 64 and next_char < 123
      # Might be an XHTML open or empty tag
      scanner = StringScanner.new(@text[@cursor .. -1])
      if scanner.scan(%r{<([a-zA-Z][a-zA-Z0-9\-_]*)}) and (HTML_TAGS.include?(scanner[1]) or WIKI_TAGS.include?(scanner[1]))
        # Sequence begins with a valid tag name, so check for attributes
        tag_name = scanner[1]
        attrs = {}
        while scanner.scan(%r{\s+([a-zA-Z][a-zA-Z0-9\-_]*)\s*=\s*('([^']+)'|"([^"]+)"|([^>\s]+))}) do
          attrs[scanner[1]] = scanner[3] ? scanner[3] : (scanner[4] ? scanner[4] : scanner[5])
        end
        scanner.scan(%r{\s*})
        if ((c = scanner.get_byte) == '>' or (c == '/' and scanner.get_byte == '>'))
          # Found an XHTML start or empty tag
          if tag_name == 'nowiki'
            @lexer_table.push(@nowiki_lexer_table) unless c == '/'
          elsif tag_name == 'paste'
            unless c == '/'
                maybe_close_para(:PASTE_START, true)
                append_to_tokens([:PASTE_START, ''])
                @cursor += scanner.pos
                @lexer_table.push(@paste_lexer_table)
                #eat newline after <paste> if if exists because otherwise
                #it will be transformed into <br/>
                if @text[@cursor, 1] == "\n"
                    @cursor += 1
                elsif @text[@cursor, 2] == "\r\n"
                    @cursor += 2
                end
                return
            end
          else
            if tag_name == 'pre'
              table = @pre_lexer_table
            elsif tag_name == 'code'
              table = @code_lexer_table
            elsif tag_name == 'math'
              table = @math_lexer_table
            else
              table = @markup_lexer_table
            end
            start_span(:TAG, tag_name)
            attrs.collect do |(name, value)| 
              append_to_tokens([:ATTR_NAME, name])
              append_to_tokens([:ATTR_VALUE, value]) if value
            end
            if c == '/' or TAGS_WITHOUT_CLOSE_TAG.include? tag_name
              end_span(:TAG, tag_name)
            else
              @lexer_table.push(table)
            end
          end
          @cursor += scanner.pos
        else
          match_text
        end
      else
        match_text
      end
    else
      match_text
    end
  end

  def match_equal
    if at_start_of_line?
      @heading = extract_char_sequence('=')
      if at_end_of_line? or blank_line?
        #special case - no header text, just "=" signs
        #try to split header into "=" formatting and text with "=":
        # example:
        #  ==== should become: = == =
        #  ===== should become: == = ==
        if @heading =~ /(={6})(=+)(={6})/ or
                @heading =~ /(={5})(=+)(={5})/ or
                @heading =~ /(={4})(=+)(={4})/ or
                @heading =~ /(={3})(=+)(={3})/ or
                @heading =~ /(={2})(=+)(={2})/ or
                @heading =~ /(=)(=+)(=)/
            start_span(:SECTION, $1)
            @tokens << [:TEXT, $2]
            end_span(:SECTION, $3)
        else
            @cursor -= @heading.length
            match_text
        end
      else
        start_span(:SECTION, @heading)
        @lexer_table.push(@heading_lexer_table)
      end
    else
      match_text
    end
  end
  
  def match_equal_in_heading
    heading = extract_char_sequence('=')
    if @heading.length <= heading.length 
      end_span(:SECTION, heading)
      @lexer_table.pop
      skip_newline
    else
      @pending << heading
    end
  end
  
  def match_newline_in_heading 
    end_span(:SECTION)
    @lexer_table.pop
  end

  def match_left_square
    if @text[@cursor, 2] == "[["
      if @text[@cursor + 2, 1] != "]"
        start_span(:INTLINK, "[[")
        @cursor += 2
        @lexer_table.push(@intlink_lexer_table)
      else
        match_text
      end
    elsif @text[@cursor + 1 .. -1] =~ %r{\A\s*((http|https|file)://|mailto:)}
      start_span(:LINK, "[")
      @cursor += 1
      skip_whitespace
      @lexer_table.push(@link_lexer_table)
    else
      match_text
    end
  end

  def match_right_square_in_link
    end_span(:LINK, "]")
    @cursor += 1
    @lexer_table.pop
  end

  def match_right_square_in_intlink
    if @text[@cursor, 2] == "]]"
      end_span(:INTLINK, "]]")
      @cursor += 2
      @lexer_table.pop
    else
      match_text
    end
  end
  
  def match_space_in_link
    skip_whitespace
    append_to_tokens([:LINKSEP, ' ']) unless @text[@cursor, 1] == ']'
    @lexer_table.pop
    @lexer_table.push(@link_opt_lexer_table)
  end
    
  def match_pipe_in_intlink
    if @tokens.last[0] == :INTLINK_START
      @lexer_table.pop
      @lexer_table.push(@intlink_opt_lexer_table)
    end
    append_to_tokens([:INTLINKSEP, "|"])
    @cursor += 1
  end
  
  def match_colon_in_intlink
    if not @pending.is_empty_token?
      @lexer_table.pop
      @lexer_table.push(@resourcelink_opt_lexer_table)  
    end
    append_to_tokens([:RESOURCESEP, ":"])
    @cursor += 1
  end
  
  def match_c_char_in_intlink
    if @text[@cursor, 9] == 'Category:'
      append_to_tokens([:CATEGORY, 'Category:'])
      @lexer_table.pop
      @lexer_table.push(@intlink_cat_lexer_table)
      @cursor += 9
    else
      match_text
    end
  end
  
  def match_newline_in_link
    end_span(:LINK)
    @lexer_table.pop
  end
  
  def match_newline_in_intlink
    end_span(:INTLINK)
    @lexer_table.pop
  end

  def match_h_char
    if @text[@cursor, 7] == 'http://' || @text[@cursor, 8] == 'https://'
      text = @text[@cursor, 7]
      @cursor += 7
      while @cursor < @text.size and TOKEN_CHAR_TABLE[@text[@cursor]] do
        text << @text[@cursor, 1]
        @cursor += 1
      end
      start_span(:LINK)
      @pending = text
      end_span(:LINK)
    else
      match_text
    end
  end

  def match_space
    if at_start_of_line? and !blank_line?
      start_span(:PRE)
      @lexer_table.push(@indent_lexer_table)
      match_text
    else
      match_text
    end
  end
  
  def match_newline_in_indent
    match_text
    unless @text[@cursor, 1] == " "
      @tokens << [:TEXT, @pending]
      @pending = ''
      end_span(:PRE)
      @lexer_table.pop
    end
  end

  def match_star
    if at_start_of_line?
      @list = extract_char_sequence('#*')
      open_list(@list)
      @lexer_table.push(@items_lexer_table)
    else
      match_text
    end
  end
  
  def match_hash
    if at_start_of_line?
      @list = extract_char_sequence('#*')
      open_list(@list)
      @lexer_table.push(@items_lexer_table)
    else
      match_text
    end
  end
  
  def match_underscore
    if @text[@cursor, 7] == '__TOC__'
      empty_span(:KEYWORD, 'TOC')
      @cursor += 7
    elsif @text[@cursor, 9] == '__NOTOC__'
      empty_span(:KEYWORD, 'NOTOC')
      @cursor += 9
    else
      match_text
    end
  end
  
  def match_newline_in_items
    if @text[@cursor, 1] == "\n"
      newline = "\n"
      char = @text[@cursor + 1, 1]
    else
      newline = "\r\n"
      char = @text[@cursor + 2, 1]
    end
    @pending << newline
    @cursor += newline.length
    if (char == @list[0, 1])
      list = extract_char_sequence('#*')
      if list == @list
        end_span(:LI) 
        start_span(:LI)
      else
        l = @list.length > list.length ? list.length : @list.length
        i = 0
        i += 1 while (i < l and @list[i] == list[i])
        if i < @list.length
          close_list(@list[i .. -1])
          if @context.last == :LI
            end_span(:LI) 
            start_span(:LI)
          end
        end
        if i < list.length
          start_span(:LI) if @context.last != :LI
          open_list(list[i .. -1]) 
        end
        @list = list
      end
    else
      close_list(@list)
      @lexer_table.pop
    end
  end
  
  def match_dash
    if at_start_of_line? and @text[@cursor, 4] == "----"
      empty_span(:HLINE, "----")
      @cursor += 4
    else
      match_text
    end
  end
    
  def match_left_angle_in_nowiki
    if @text[@cursor, 9] == '</nowiki>'
      @cursor += 9
      @lexer_table.pop
    else
      match_text
    end
  end

  def match_left_angle_in_paste
    if @text[@cursor, 8] == '</paste>'
      @cursor += 8
      @lexer_table.pop
      append_to_tokens([:PASTE_END, ''])
      maybe_open_para(:PASTE_END)
    else
      match_text
    end
  end

  def match_newline_in_paste
    append_to_tokens([:TAG_START, 'br'])
    append_to_tokens([:TAG_END, 'br'])
    if @text[@cursor, 1] == "\n"
      @cursor += 1
    elsif @text[@cursor, 2] == "\r\n"
      @cursor += 2
    end
  end

  def match_left_angle_in_math
    if @text[@cursor, 7] == '</math>'
      end_span(:TAG, 'math')
      @cursor += 7
      @lexer_table.pop
    else
      match_text
    end
  end
    
  def match_left_angle_in_pre
    if @text[@cursor, 6] == '</pre>'
      end_span(:TAG, 'pre')
      @cursor += 6
      #eat newline after </pre>
      if @text[@cursor, 1] == "\n"
        @cursor += 1
      elsif @text[@cursor, 2] == "\r\n"
        @cursor += 2
      end
      @lexer_table.pop
    else
      match_text
    end
  end

  def match_space_in_code
    match_text
  end

  def match_left_angle_in_code
    if @text[@cursor, 7] == '</code>'
      end_span(:TAG, 'code')
      @cursor += 7
      @lexer_table.pop
    else
      match_left_angle
    end
  end

  def match_left_curly
    if at_start_of_line? and @text[@cursor + 1, 1] == '|'
      start_span(:TABLE, "{|")
      @cursor += 2
      @lexer_table.push(@table_lexer_table)
    elsif @text[@cursor + 1, 1] == '{' and @text[@cursor + 2, 2] != "}}"
      start_span(:TEMPLATE, "{{")
      @cursor += 2
      @lexer_table.push(@template_lexer_table)
    else
      match_text
    end
  end
  
  def match_left_curly_in_template
    if @text[@cursor + 1, 1] == '{' and @text[@cursor + 2, 2] != "}}"
      start_span(:TEMPLATE, "{{")
      @cursor += 2
      @lexer_table.push(@template_lexer_table)
    else
      match_text
    end
  end
  
  def match_right_curly_in_template
    if @text[@cursor + 1, 1] == '}'
      end_span(:TEMPLATE, "}}")
      @cursor += 2
      @lexer_table.pop
    else
      match_text
    end
  end

  def match_pipe_in_template
    if @tokens.last[0] == :TEMPLATE_START
      @lexer_table.pop
      @lexer_table.push(@template_param_lexer_table)
    end
    append_to_tokens([:INTLINKSEP, "|"])
    @cursor += 1
  end
    
  def match_bang_in_table
    if at_start_of_line?
      @cursor += 1
      if @context.last == :CELL
        end_span(:CELL)
      elsif @context.last == :HEAD
        end_span(:HEAD)
      elsif @context.last != :ROW
        start_span(:ROW)
      end
      start_span(:HEAD, "!")
    else
      match_text
    end
  end
    
  def match_pipe_in_table
    if at_start_of_line?
      @cursor += 1
      context = @context[@context.rindex(:TABLE) + 1 .. -1]
      if @text[@cursor, 1] == '-'
        end_span(:ROW) if context.include? :ROW
        start_span(:ROW, "|-")
        @cursor += 1
      elsif @text[@cursor, 1] == '}'
        end_span(:TABLE, "|}")
        @cursor += 1
        @lexer_table.pop
        skip_newline
      else
        if context.include? :CELL
          end_span(:CELL)
        elsif context.include? :HEAD
          end_span(:HEAD)
        end
        start_span(:ROW) unless @context.last == :ROW
        start_span(:CELL, "|")
      end
    elsif @text[@cursor + 1, 1] == '|'
      @cursor += 2
      context = @context[@context.rindex(:TABLE) + 1 .. -1]
      if context.include?:CELL
        end_span(:CELL)
        start_span(:CELL, "||")
      elsif context.include? :HEAD
        end_span(:HEAD)
        start_span(:HEAD, "||")
      end
    else
      context = @context[@context.rindex(:TABLE) + 1 .. -1]
      if context.include? :CELL
        end_span(:CELL, "attributes")
        start_span(:CELL, "|")
        @char = ''
      end
      match_text
    end
  end

  def match_newline
    if @text[@cursor, 2] == "\n\n"
      @pending << "\n\n"
      @cursor += 2
      end_span(:PARA)
      start_span(:PARA)
    elsif @text[@cursor, 4] == "\r\n\r\n"
      @pending << "\r\n\r\n"
      @cursor += 4
      end_span(:PARA)
      start_span(:PARA)
    else
      match_text
    end
  end
  
  def match_newline_in_table
    if @text[@cursor, 2] == "\n\n"
      start_span(:PARA)
      append_to_tokens([:TEXT, "\n\n"])
      end_span(:PARA)
      @cursor += 2
    elsif @text[@cursor, 4] == "\r\n\r\n"
      start_span(:PARA)
      append_to_tokens([:TEXT, "\r\n\r\n"])
      end_span(:PARA)
      @cursor += 4
    else
      match_text
    end
  end
  
  def match_semicolon
    if at_start_of_line?
      start_span(:DL)
      start_span(:DT, ';')
      @lexer_table.push(@entries_lexer_table)
      @cursor += 1
    else
      match_text
    end
  end
  
  def match_colon
    if at_start_of_line?
      start_span(:DL)
      start_span(:DD, ':')
      @lexer_table.push(@entries_lexer_table)
      @cursor += 1
    else
      match_text
    end
  end
  
  def match_colon_in_entries
    if @context.include? :DD
      end_span(:DD)
    elsif @context.include? :DT
      end_span(:DT)
    end
    start_span(:DD, ':')
    @cursor += 1
  end
  
  def match_newline_in_entries
    match_text
    unless @text[@cursor, 1] == ':'
      if @context.include? :DD
        end_span(:DD)
      elsif @context.include? :DT
        end_span(:DT)
      end
      end_span(:DL)
      @lexer_table.pop
    end
  end
  
  
  #-- ================== Helper methods ================== ++#
    
  # Returns true if the text cursor is on the first character of a line
  def at_start_of_line?
    @cursor == 0 or @text[@cursor - 1, 1] == "\n"
  end

  # Returns true if the text cursor is after the last character of a line
  def at_end_of_line?
    @text[@cursor, 1] == "\n" or @text[@cursor, 1].nil?
  end

  def blank_line?
    i = @cursor
    i += 1 while (@text[i,1] == ' ')
    return (@text[i,1] == '' or (@text[i,1] == "\n") or (@text[i,2] == "\r\n"))
  end

  # Advances the text cursor to the next non-blank character, without appending
  # any of the blank characters to the pending text buffer
  def skip_whitespace 
    @cursor += 1 while @text[@cursor, 1] == ' '
  end
  
  # Advances the text cursor beyond the next newline sequence, if any. This is 
  # used to strip newlines after certain block-level elements, like section
  # headings and tables, to prevent an empty paragraph when the block is followed
  # by an extra newline sequence.
  def skip_newline
    if @text[@cursor, 2] == "\r\n"
      @cursor += 2
    elsif @text[@cursor, 1] == "\n"
      @cursor += 1
    end
  end
  
  # Extracts from the input text the sequence of characters consisting of the
  # character or characters specified, and returns the sequence as a string. The
  # text cursor is advanaced to point to the next character after the sequence.
  def extract_char_sequence(char)
    sequence = ''
    if char.length == 1
      while @text[@cursor, 1] == char do
        sequence << char
        @cursor += 1
      end
    else
      chars = char.split('')
      while chars.include?(@text[@cursor, 1]) do
        sequence << @text[@cursor, 1]
        @cursor += 1
      end
    end
    sequence
  end
  
  # Opens list and list item spans for each item symbol in the string specified.
  def open_list(symbols)
    symbols.split('').each do
      |symbol|
      if symbol == '*'
        start_span(:UL)
      else
        start_span(:OL)
      end
      start_span(:LI)
    end
  end
  
  # Closes list and list item spans for each item symbol in the string specified.
  def close_list(symbols)
    symbols.split('').reverse.each do
      |symbol|
      end_span(:LI)
      if symbol == '*'
        end_span(:UL)
      else
        end_span(:OL)
      end
    end
  end
    
  # Open a token span for the symbol specified. This will append a token start
  # to the list of output tokens, and push the symbol onto the context stack. If
  # there is an open paragraph, and the symbol is a block element, then the
  # open paragraph will be closed (or, if empty, removed) before the token start
  # is appended.
  def start_span(symbol, text='')
    maybe_close_para(symbol, ['pre','table','p'].include?(text))
    @context << symbol
    append_to_tokens [(symbol.to_s + '_START').to_sym, text]
  end
    
  # Close a token span for the symbol specified. This will append an end token
  # to the list of output tokens, and pop the symbol from the context stack. Any
  # unclosed contexts on top of this symbol's context will also be close (this
  # generally happens when in-line markup is not terminated before a new block
  # begins). If the context is empty as a result, a new paragraph will be opened.
  def end_span(symbol, text='')
    while(@context.size > 0 and @context.last != symbol) do
      append_to_tokens [(@context.pop.to_s + '_END').to_sym, '']
    end
    @context.pop
    append_to_tokens [(symbol.to_s + '_END').to_sym, text]
    maybe_open_para(symbol)
  end
  
  def empty_span(symbol, text='')
    maybe_close_para(symbol)
    append_to_tokens [symbol, text]
    maybe_open_para(symbol)
  end
  
  def maybe_close_para(symbol, force = false)
    if @context.size > 0 and (PARA_BREAK_ELEMENTS.include?(symbol) or force)
      i = 1
      i += 1 while INLINE_ELEMENTS.include?(@context[-i])
      if @context[-i] == :PARA
        if @pending.is_empty_token? and @tokens.last[0] == :PARA_START
          @context.pop
          @tokens.pop
        else
          (1 .. i).each do
            symbol = @context.pop
            append_to_tokens [(symbol.to_s + '_END').to_sym, '']
          end
        end
      end
    end
  end
  
  def maybe_open_para(symbol)
    if @context.size == 0 and symbol != :PARA
      @tokens << [:PARA_START, '']
      @context << :PARA
    end
  end
  
  def append_to_tokens(token)
    unless @pending.is_empty_token?
      @tokens << [:TEXT, @pending]
    end
    @pending = ''
    @tokens << token
  end
  
  
  class LexerTable
    
    def initialize
      @tables = []
    end
    
    def push(table)
      @tables << table
      @table = table
    end
    
    def pop
      @tables.pop
      @table = @tables.last
    end
    
    def[] (char)
      @table[char]
    end
    
  end

end

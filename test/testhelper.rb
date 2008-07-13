require 'hpricot'

module TestHelper

    #Helper method for file-based comparison tests.
    #
    #Looks in "data/" directory for files named "inputXXX",
    #substitutes "input" with baseName and loads the contents
    #of "inputXXX" file into the "input" variable and the
    #contents of "baseNameXXX" into the "result" variable.
    #
    #Then it calls the block with input and result as parameters.
    def test_files(baseName, &action)
        Dir.glob(File.dirname(__FILE__) + "/data/input*").each do |filename|
            resultname = filename.gsub(/input(.*)/, "#{baseName}\\1")
            #exclude backup files
            if not resultname.include?("~")
                input_file = File.new(filename, "r")
                input = input_file.read
                if File.exists?(resultname)
                    result_file = File.new(resultname, "r")
                    result = result_file.read

                    yield(input, result, resultname)
                end
            end
        end
    end

  def assert_generates(result, input, link_handler=nil, message=nil)
      parser = MediaWikiParser.new
      parser.lexer = MediaWikiLexer.new
      ast = parser.parse(input)
      MediaWikiParams.instance.time = Time.utc(2000, 1, 1, 1, 1, 1, 1)
      generator = MediaWikiHTMLGenerator.new
      generator.link_handler = link_handler if link_handler
      generator.parse(ast)
      assert_same_html(result, generator.html, message)
  end

  def assert_same_html(expected, result, message)
    assert_equal(Hpricot(expected).to_s, Hpricot(result).to_s, message)
  end

end

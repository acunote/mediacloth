module TestHelper

    #Helper method for file-based comparison tests.
    #
    #Looks in "data/" directory for files named "inputXXX",
    #substitutes "input" with baseName and loads the contents
    #of "inputXXX" file into the "input" variable and the
    #contents of "baseNameXXX" into the "result" variable.
    #
    #Then it calls the block with input and result as parameters.
    def testFiles(baseName, &action)
        Dir.glob("data/input*").each do |filename|
            resultname = filename.gsub(/input(.*)/, "#{baseName}\\1")
            #exclude backup files
            return if resultname.include?("~")

            inputFile = File.new(filename, "r")
            input = inputFile.read
            return if not File.exists?(resultname)
            resultFile = File.new(resultname, "r")
            result = resultFile.read

            yield(input, result)
        end
    end
end

class MediaWikiTemplateHandler

    def included_template(name, parameters)
        serialized_parameters = "|" + parameters.join('|') if parameters and !parameters.empty?
        "{{#{name}#{serialized_parameters}}}"
    end

end

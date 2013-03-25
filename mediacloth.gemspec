require 'rubygems'

SPEC = Gem::Specification.new do |s|
    s.name      = "mediacloth"
    s.version   = "0.6"
    s.author    = "Pluron Inc."
    s.email     = "support@pluron.com"
    s.homepage  = "https://github.com/adymo/mediacloth"
    s.platform  = Gem::Platform::RUBY
    s.description = "MediaWiki syntax to HTML converter"
    s.summary   = "Ruby library to convert MediaWiki syntax to HTML, similar to Kramdown or Redcloth."

    s.add_development_dependency('racc',    '>= 1.1.3')

    candidates  = Dir.glob("{bin,docs,lib,test}/**/*")
    s.files     = candidates.delete_if do |item|
                    item.include?("rdoc")
                  end

    s.require_path      = "lib"
    s.has_rdoc          = true
    s.extra_rdoc_files  = ["README.md"]
    s.rdoc_options      << '--title' << 'MediaCloth' << '--main' << 'README.md'
end

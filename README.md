MediaCloth is the MediaWiki syntax parser and html generator written in ruby. It's small, fast and aims to recognize the complete MediaWiki language.

## Installation
To install the library run:

    ruby setup.rb


## Usage
The quickest way to parse your input and produce html formatted text is:

    require 'mediacloth'
    puts MediaCloth::wiki_to_html("'''Hello'''''World''!")

You can also provide a hash with custom options if you want to use another generator or link handler:

    require 'mediacloth'
    puts MediaCloth::wiki_to_html("'''Hello'''''World''!", :link_handler => MyLinkHandler.new)

Both examples should produce

    <b>Hello</b><i>World</i>!

## API Docs
To generate API documentation run:

    rake rdoc

## Development
To run tests execute

    rake test

To regenerate test data (html and lex files from wiki input), run:

    rake test:regenerate

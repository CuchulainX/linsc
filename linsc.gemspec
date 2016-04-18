# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "linsc"
  spec.version       = "0.0.13"
  spec.authors       = ["Dan Molloy"]
  spec.email         = ["danieljmolloy1@gmail.com"]
  spec.date = '2016-03-31'

  spec.summary       = %q{Scrape Linkedin and import to Salesforce}
  spec.description   = %q{A gem for scraping public data of Linkedin connections and importing the data to Salesforce.}
  spec.homepage      = "https://github.com/danmolloy/linsc"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.files.delete('exe/linsc')
  spec.files.delete('lib/linsc/version.rb')
  spec.bindir        = "bin"
  spec.executables   = ["linsc"]
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"

  spec.add_runtime_dependency "mechanize", "~> 2.7"
  spec.add_runtime_dependency "i18n", "~> 0.7"

end

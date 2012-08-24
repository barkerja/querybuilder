# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{querybuilder}
  s.version = "1.1.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Gaspard Bucher"]
  s.date = %q{2012-08-24}
  s.description = %q{QueryBuilder is an interpreter for the "pseudo sql" language. This language
    can be used for two purposes:

     1. protect your database from illegal SQL by securing queries
     2. ease writing complex relational queries by abstracting table internals}
  s.email = %q{gaspard@teti.ch}
  s.extensions = ["lib/extconf.rb"]
  s.extra_rdoc_files = [
    "README.rdoc"
  ]
  s.files = [
    "History.txt",
    "Manifest.txt",
    "README.rdoc",
    "Rakefile",
    "lib/extconf.rb",
    "lib/query_builder.rb",
    "lib/query_builder/error.rb",
    "lib/query_builder/info.rb",
    "lib/query_builder/parser.rb",
    "lib/query_builder/processor.rb",
    "lib/query_builder/query.rb",
    "lib/querybuilder.rb",
    "lib/querybuilder_ext.c",
    "lib/querybuilder_ext.rl",
    "lib/querybuilder_rb.rb",
    "lib/querybuilder_rb.rl",
    "lib/querybuilder_syntax.rl",
    "lib/tasks/build.rake",
    "old_QueryBuilder.rb",
    "querybuilder.gemspec",
    "script/console",
    "script/destroy",
    "script/generate",
    "test/database.rb",
    "test/dummy_test.rb",
    "test/mock/custom_queries/test.yml",
    "test/mock/dummy.rb",
    "test/mock/dummy_processor.rb",
    "test/mock/queries/bar.yml",
    "test/mock/queries/foo.yml",
    "test/mock/user_processor.rb",
    "test/query_test.rb",
    "test/querybuilder/basic.yml",
    "test/querybuilder/custom.yml",
    "test/querybuilder/errors.yml",
    "test/querybuilder/filters.yml",
    "test/querybuilder/group.yml",
    "test/querybuilder/having.yml",
    "test/querybuilder/joins.yml",
    "test/querybuilder/mixed.yml",
    "test/querybuilder/rubyless.yml",
    "test/querybuilder/select.yml",
    "test/querybuilder_test.rb",
    "test/test_helper.rb"
  ]
  s.homepage = %q{http://zenadmin.org/524}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.6.2}
  s.summary = %q{QueryBuilder is an interpreter for the "pseudo sql" language.}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rubyless>, [">= 0.7.0"])
      s.add_development_dependency(%q<shoulda>, [">= 0"])
      s.add_development_dependency(%q<yamltest>, [">= 0.5.0"])
    else
      s.add_dependency(%q<rubyless>, [">= 0.7.0"])
      s.add_dependency(%q<shoulda>, [">= 0"])
      s.add_dependency(%q<yamltest>, [">= 0.5.0"])
    end
  else
    s.add_dependency(%q<rubyless>, [">= 0.7.0"])
    s.add_dependency(%q<shoulda>, [">= 0"])
    s.add_dependency(%q<yamltest>, [">= 0.5.0"])
  end
end


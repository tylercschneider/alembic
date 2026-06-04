require_relative "lib/alembic/version"

Gem::Specification.new do |spec|
  spec.name        = "alembic"
  spec.version     = Alembic::VERSION
  spec.authors     = [ "tylercschneider" ]
  spec.email       = [ "tylercschneider@gmail.com" ]
  spec.homepage    = "https://github.com/tylercschneider/alembic"
  spec.summary     = "Distill expertise into interactive diagnostics."
  spec.description = "Alembic builds and runs data-driven interactive diagnostics — scored assessments and branching guides — that place a visitor on an outcome and capture the result. A runtime engine plus a UI builder."
  spec.license     = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 8.1.3"
end

#!/usr/bin/env ruby
# PATH-independent on purpose. The sh version of this file called `gem` and
# `foreman` through PATH, and on a machine where the shims were not wired it
# found the system Ruby's gem — "incompatible library version", then
# "foreman: not found" (exit 127). Real session, 11.08.
#
# As a Ruby script this file is pinned by init-project's shebang loop, and
# Gem.ruby / Gem.bin_path resolve inside the running Ruby — PATH is never
# consulted. foreman stays out of the Gemfile; foreman's own README advises
# against bundling it.
require "rubygems"

begin
  gem "foreman"
rescue Gem::LoadError
  puts "Installing foreman..."
  system(Gem.ruby, "-S", "gem", "install", "foreman") || abort("foreman install failed")
  Gem.clear_paths
end

ENV["PORT"] ||= "3000"
exec Gem.ruby, Gem.bin_path("foreman", "foreman"), "start", "-f", "Procfile.dev"

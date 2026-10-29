# frozen_string_literal: true

require "bundler/gem_tasks"
require "minitest/test_task"

Minitest::TestTask.create

require "standard/rake"

task default: %i[test standard]

desc "Continuously rerun tests when source/test files change"
task "test:watch" do
  sh "bin/retest --notify"
end

desc "Build YARD documentation"
task "doc:build" do
  sh "bin/yard doc"
end

desc "Start YARD server at localhost:8808"
task "doc:server" do
  sh "bin/yard server --reload"
end

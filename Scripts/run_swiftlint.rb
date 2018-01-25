#!/usr/bin/env ruby

require 'xcodeproj'

if ARGV[0].nil?
  puts "usage: #{$0} your.xcodeproj"
  exit 1
end

project_path = File.expand_path(ARGV[0], Dir.pwd)
project = Xcodeproj::Project.open(project_path)

PHASE_NAME = "Run SwiftLint"

project.targets.each do |target|
  next if target.build_phases.any? do |phase|
    phase.respond_to?(:name) and phase.name == PHASE_NAME
  end

  next if target.name.include? "Package"
  next if target.name.include? "Tests"

  phase = project.new(Xcodeproj::Project::Object::PBXShellScriptBuildPhase)
  phase.name = PHASE_NAME
  phase.shell_script = <<-EOS
  if which swiftlint >/dev/null; then
    swiftlint
  else
    echo "warning: SwiftLint not installed; download it from https://github.com/realm/SwiftLint"
  fi
  EOS

  target.build_phases.unshift phase

  puts "Added a build phase \"#{PHASE_NAME}\" to #{target.name}"
end

project.save

#!/usr/bin/env ruby

require 'xcodeproj'

project_path = File.expand_path('../../Swasm.xcodeproj', __FILE__)
project = Xcodeproj::Project.open(project_path)

targets = ["Swasm", "SwasmTests"]

def add_swiftlint(project, target, phase_name)
  return if target.build_phases.any? do |phase|
    phase.respond_to?(:name) and phase.name == phase_name
  end

  phase = project.new(Xcodeproj::Project::Object::PBXShellScriptBuildPhase)
  phase.name = phase_name
  phase.shell_script = <<-EOS
  if which swiftlint >/dev/null; then
    swiftlint
  else
    echo "warning: SwiftLint not installed; download it from https://github.com/realm/SwiftLint"
  fi
  EOS

  target.build_phases.unshift(phase)

  puts "Added a build phase named \"#{phase_name}\""
end

def add_swiftformat(project, target, phase_name)
  return if target.build_phases.any? do |phase|
    phase.respond_to?(:name) and phase.name == phase_name
  end

  phase = project.new(Xcodeproj::Project::Object::PBXShellScriptBuildPhase)
  phase.name = phase_name
  phase.shell_script = <<-EOS
  if which swiftformat >/dev/null; then
  swiftformat . --verbose
  else
    echo "warning: SwiftFormat not installed; download it from https://github.com/nicklockwood/SwiftFormat"
  fi
  EOS

  target.build_phases.unshift(phase)

  puts "Added a build phase named \"#{phase_name}\""
end


project.targets.each do |target|
  next unless targets.include? target.name

  add_swiftlint(project, target, "Run SwiftLint")
  add_swiftformat(project, target, "Run SwiftFormat")
end

project.save()


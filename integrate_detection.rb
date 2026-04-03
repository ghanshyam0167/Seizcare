#!/usr/bin/env ruby
# integrate_detection.rb
# Adds required frameworks to targets for the new detection pipeline.
# Since both targets use PBXFileSystemSynchronizedRootGroup, all Swift files
# in Detection/ and Watch Managers/ are already auto-included by Xcode.
# This script only needs to handle frameworks and the mlmodel resource.

require 'xcodeproj'

PROJECT_PATH   = './Seizcare.xcodeproj'
IPHONE_TARGET  = 'Seizcare'
WATCH_TARGET   = 'SeizcareWatch Watch App'

project = Xcodeproj::Project.open(PROJECT_PATH)
puts "✅ Opened project: #{PROJECT_PATH}"

iphone = project.targets.find { |t| t.name == IPHONE_TARGET }
watch  = project.targets.find { |t| t.name == WATCH_TARGET  }

raise "❌ Could not find iPhone target '#{IPHONE_TARGET}'" unless iphone
raise "❌ Could not find Watch target '#{WATCH_TARGET}'"   unless watch

puts "✅ Found targets: #{iphone.name} | #{watch.name}"

# ─────────────────────────────────────────────────────────────────────────────
# Helper: add a system framework to a target's Frameworks build phase
# ─────────────────────────────────────────────────────────────────────────────
def add_framework(project, target, framework_name)
  already = target.frameworks_build_phase.files.any? do |f|
    f.display_name.to_s == framework_name
  end
  if already
    puts "   ⚠️  #{framework_name} already linked to #{target.name}"
    return
  end

  # Create a file reference in the Frameworks group
  frameworks_group = project.frameworks_group
  ref = frameworks_group.files.find { |f| f.path.to_s.include?(framework_name) }
  unless ref
    ref = frameworks_group.new_file("System/Library/Frameworks/#{framework_name}")
    ref.source_tree = 'SDKROOT'
    ref.last_known_file_type = 'wrapper.framework'
  end

  target.frameworks_build_phase.add_file_reference(ref)
  puts "   ✅ Linked #{framework_name} → #{target.name}"
end

# ─────────────────────────────────────────────────────────────────────────────
# 1. iPhone target — Accelerate.framework
# ─────────────────────────────────────────────────────────────────────────────
puts "\n📦 [iPhone] Adding Accelerate.framework..."
add_framework(project, iphone, 'Accelerate.framework')

# ─────────────────────────────────────────────────────────────────────────────
# 2. Watch target — CoreMotion.framework
# ─────────────────────────────────────────────────────────────────────────────
puts "\n📦 [Watch] Adding CoreMotion.framework..."
add_framework(project, watch, 'CoreMotion.framework')

# ─────────────────────────────────────────────────────────────────────────────
# 3. Verify SeizureModel.mlmodel is in iPhone Resources (not Sources)
#    It's in the root group as a standalone file ref added to Sources — move it
#    to the Resources build phase so the compiler doesn't try to compile it.
# ─────────────────────────────────────────────────────────────────────────────
puts "\n🤖 Checking SeizureModel.mlmodel target membership..."

ml_ref = project.main_group.children.find do |c|
  c.respond_to?(:path) && c.path.to_s == 'SeizureModel.mlmodel'
end

if ml_ref
  puts "   Found SeizureModel.mlmodel ref (UUID: #{ml_ref.uuid})"

  # Remove from Sources build phase if present (incorrect placement)
  src_phase = iphone.source_build_phase
  src_files_with_ml = src_phase.files.select { |f| f.display_name.to_s.include?('SeizureModel') }
  src_files_with_ml.each do |f|
    src_phase.remove_build_file(f)
    puts "   ✅ Removed SeizureModel.mlmodel from Sources (was incorrect)"
  end

  # Ensure it's in the Resources build phase
  res_phase = iphone.resources_build_phase
  already_in_resources = res_phase.files.any? { |f| f.display_name.to_s.include?('SeizureModel') }
  unless already_in_resources
    res_phase.add_file_reference(ml_ref)
    puts "   ✅ Added SeizureModel.mlmodel to Resources build phase"
  else
    puts "   ⚠️  SeizureModel.mlmodel already in Resources — OK"
  end
else
  puts "   ⚠️  SeizureModel.mlmodel not found as standalone ref — likely handled by FS sync"
end

# ─────────────────────────────────────────────────────────────────────────────
# 4. Report framework state
# ─────────────────────────────────────────────────────────────────────────────
puts "\n📋 Final framework list:"
project.targets.each do |t|
  puts "  #{t.name}:"
  t.frameworks_build_phase.files.each { |f| puts "    • #{f.display_name}" }
end

# ─────────────────────────────────────────────────────────────────────────────
# 5. Save
# ─────────────────────────────────────────────────────────────────────────────
project.save
puts "\n✅ project.pbxproj saved"

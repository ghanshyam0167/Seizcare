require 'xcodeproj'

project_path = './Seizcare.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.first
group = project.main_group.find_subpath(File.join('Seizcare'), true)

# files to add
files = [
  'OTPVerificationViewController.swift',
  'ResetPasswordViewController.swift'
]

files.each do |file_name|
  file_path = File.join('.', 'Seizcare', file_name)
  
  if File.exist?(file_path)
    # Check if already exists in group
    file_ref = group.files.find { |f| f.path == file_name || (f.path && f.path.include?(file_name)) }
    unless file_ref
      file_ref = group.new_reference(file_name)
      puts "Added reference for #{file_name}"
    end
    
    # Check if already in build phases
    build_phase = target.source_build_phase
    unless build_phase.files_references.include?(file_ref)
      build_phase.add_file_reference(file_ref)
      puts "Added #{file_name} to build phase"
    end
  else
    puts "File does not exist: #{file_path}"
  end
end

project.save
puts "Project saved"

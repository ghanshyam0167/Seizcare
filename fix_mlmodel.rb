require 'xcodeproj'

project = Xcodeproj::Project.open('./Seizcare.xcodeproj')
iphone = project.targets.find { |t| t.name == 'Seizcare' }

ml_ref = project.main_group.children.find do |c|
  c.respond_to?(:path) && c.path.to_s == 'SeizureModel.mlmodel'
end

if ml_ref
  # Remove from Resources
  res_phase = iphone.resources_build_phase
  res_files = res_phase.files.select { |f| f.display_name.to_s.include?('SeizureModel') }
  res_files.each do |f|
    res_phase.remove_build_file(f)
  end

  # Add to Sources
  src_phase = iphone.source_build_phase
  unless src_phase.files.any? { |f| f.display_name.to_s.include?('SeizureModel') }
    src_phase.add_file_reference(ml_ref)
    puts "Added SeizureModel.mlmodel back to Sources phase"
  end
end

project.save

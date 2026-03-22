#!/usr/bin/env ruby
# Script pour corriger les duplications de localisation

require 'xcodeproj'

project_path = '/Users/studio_m3/moulinsart/PrivExpensIA/PrivExpensIA.xcodeproj'
project = Xcodeproj::Project.open(project_path)

puts "🔧 Correction des duplications de localisation..."

# Trouver la phase Copy Bundle Resources
target = project.targets.find { |t| t.name == 'PrivExpensIA' }
resources_phase = target.resources_build_phase

# Collecter tous les Localizable.strings à supprimer
files_to_remove = []

# Parcourir tous les fichiers
project.files.each do |file|
  if file.path && file.path.include?('resources/i18n') && file.path.include?('Localizable.strings')
    puts "❌ Suppression de la référence duplicate: #{file.path}"
    files_to_remove << file
  end
end

# Supprimer les références des variant groups aussi
project.main_group.children.each do |child|
  if child.is_a?(Xcodeproj::Project::Object::PBXVariantGroup) && child.name == 'Localizable.strings'
    child.files.each do |file|
      if file.path && file.path.include?('resources/i18n')
        puts "❌ Suppression du variant duplicate: #{file.path}"
        child.files.delete(file)
      end
    end
  end
end

# Supprimer de la phase Copy Bundle Resources
resources_phase.files.each do |build_file|
  if build_file.file_ref
    file_path = build_file.file_ref.path
    if file_path && file_path.include?('resources/i18n')
      puts "❌ Suppression de Copy Bundle: #{file_path}"
      resources_phase.files.delete(build_file)
    end
  end
end

# Supprimer les références du projet
files_to_remove.each do |file|
  file.remove_from_project
end

# Compter ce qui reste
remaining_lproj = 0
remaining_strings = 0

project.files.each do |file|
  if file.path
    if file.path.include?('.lproj')
      remaining_lproj += 1
    elsif file.path.include?('Localizable.strings')
      remaining_strings += 1
    end
  end
end

# Sauvegarder
project.save

puts "\n✅ Duplications supprimées!"
puts "📊 Fichiers restants:"
puts "   - Dossiers .lproj: #{remaining_lproj}"
puts "   - Localizable.strings: #{remaining_strings}"
puts "\n🎯 Prochaine étape: Build dans Xcode"
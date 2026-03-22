#!/usr/bin/env ruby
# Script pour ajouter les fichiers de localisation au projet Xcode

require 'xcodeproj'

# Ouvrir le projet
project_path = '/Users/studio_m3/moulinsart/PrivExpensIA/PrivExpensIA.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Trouver la target principale
target = project.targets.find { |t| t.name == 'PrivExpensIA' }

if target.nil?
  puts "❌ Target PrivExpensIA non trouvée"
  exit 1
end

puts "✅ Target trouvée: #{target.name}"

# Trouver ou créer le groupe Resources
main_group = project.main_group
resources_group = main_group.find_subpath('Resources', true)

# Chemins des fichiers de localisation
lproj_dirs = [
  'en.lproj',
  'fr-CH.lproj',
  'de-CH.lproj',
  'it-CH.lproj',
  'es.lproj',
  'ja.lproj',
  'ko.lproj',
  'sk.lproj'
]

# Trouver la phase Copy Bundle Resources
resources_phase = target.resources_build_phase

added_count = 0

lproj_dirs.each do |lproj_name|
  # Chercher dans les deux emplacements possibles
  paths = [
    "/Users/studio_m3/moulinsart/PrivExpensIA/PrivExpensIA/#{lproj_name}",
    "/Users/studio_m3/moulinsart/PrivExpensIA/resources/i18n/#{lproj_name}"
  ]
  
  path = paths.find { |p| File.exist?(p) }
  
  if path.nil?
    puts "⚠️  #{lproj_name} non trouvé"
    next
  end
  
  # Vérifier si déjà dans le projet
  existing = resources_group.files.find { |f| f.path&.include?(lproj_name) }
  
  if existing
    puts "📁 #{lproj_name} déjà dans le projet"
  else
    # Ajouter au groupe Resources
    file_ref = resources_group.new_file(path)
    file_ref.last_known_file_type = 'folder'
    
    # Ajouter à la phase Copy Bundle Resources
    resources_phase.add_file_reference(file_ref)
    
    puts "✅ #{lproj_name} ajouté au projet"
    added_count += 1
  end
end

# Aussi chercher les fichiers Localizable.strings
Dir.glob("/Users/studio_m3/moulinsart/PrivExpensIA/**/*.lproj/Localizable.strings").each do |strings_path|
  lproj_dir = File.dirname(strings_path)
  lproj_name = File.basename(lproj_dir)
  
  # Créer une référence variant group pour Localizable.strings si elle n'existe pas
  variant_group = project.main_group.find_file_by_path('Localizable.strings')
  if variant_group.nil?
    variant_group = project.main_group.new_variant_group('Localizable.strings')
    resources_phase.add_file_reference(variant_group)
    puts "✅ Variant group Localizable.strings créé"
  end
  
  # Ajouter la variante de langue
  lang_code = lproj_name.gsub('.lproj', '')
  existing_variant = variant_group.files.find { |f| f.path&.include?(lproj_name) }
  
  if existing_variant.nil? && File.exist?(strings_path)
    file_ref = variant_group.new_file(strings_path)
    file_ref.name = lang_code
    puts "✅ Localizable.strings ajouté pour #{lang_code}"
  end
end

# Configurer les langues supportées dans le projet
project.root_object.known_regions = ['en', 'fr-CH', 'de-CH', 'it-CH', 'es', 'ja', 'ko', 'sk']
puts "✅ Langues configurées: #{project.root_object.known_regions.join(', ')}"

# Sauvegarder le projet
project.save
puts "\n🎉 Projet sauvegardé avec #{added_count} nouvelles ressources de localisation"
puts "📝 Prochaines étapes:"
puts "   1. Clean Build Folder dans Xcode"
puts "   2. Build le projet"
puts "   3. Tester avec le MCP"
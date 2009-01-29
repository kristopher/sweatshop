namespace :sweatshop do

  # Work whether RSpec is in use or not
  if File.exists?("#{RAILS_ROOT}/spec") && File.directory?("#{RAILS_ROOT}/spec")
    FOLDER = "#{RAILS_ROOT}/spec"
  else
    FOLDER = "#{RAILS_ROOT}/test"
  end

  desc "Generate factories for all ActiveRecord Models"
  task :generate do
    require "#{RAILS_ROOT}/config/environment"

    updated_models = []

    if ENV['MODELS']
      models_to_factorize = ENV['MODELS'].split(" ").map {|m| m.constantize}
    else
      models_to_factorize = models
    end

    models_to_factorize.each{ |model| updated_models << model.to_s if generate_factory(model) }

t   print_outro(updated_models)
  end

  def generate_factory(model)
    name = model.to_s.tableize.singularize
    out_path = "#{FOLDER}/factories.rb"

    begin
      out_file = File.open(out_path, "a")

      # Produce an error BEFORE we write to the file
      test = model.columns_hash

      b_var = name[0...1]
      out_file.puts "\nFactory.define :#{name} do |#{b_var}|"

      model.columns_hash.each_pair do |key, val|
        unless key =~ /^(id|type)$/
          if key =~ /([a-z_]*)_id/
            # Example #=> g.organization { |o| o.association(:organization) }
            key = "#{$1}"
            value = "{ |a| a.association(:#{$1.to_sym}) }"
          else
            value = case val.type.to_s
              when "string", "text": "'foo'"
              when "integer": 1
              when "float": 1.0
              when "date": "'#{Date.today}'"
              when "datetime", "time", "timestamp": "'#{Time.now}'"
              when "boolean": false
              when "binary": "''"
            end
          end

          out_file.puts "  #{b_var}.#{key} #{value}"
        end
      end

      out_file.puts "end\n"
      out_file.close
    rescue Exception => e
      puts "I can't generate a factory for '#{model}'!"
      false
    end

    true
  end

  def models
    Dir.glob("#{RAILS_ROOT}/app/models/*.rb").map{|p| File.basename(p, ".rb").camelize.constantize}.select{|m| m < ActiveRecord::Base}
  end

  def print_outro(models)
    puts "\nCreated Factories for: \n#{models.to_sentence}"
    helper = if FOLDER == "#{RAILS_ROOT}/spec" then "spec/spec_helper.rb" else "test/test_helper.rb" end

    puts <<-END

Make sure you put the two following lines into #{helper}:
  require 'factory_girl'
  require File.expand_path(File.dirname(__FILE__)) + '/factories'
    END
  end

end

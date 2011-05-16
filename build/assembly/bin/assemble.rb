#!/usr/bin/env ruby

$: << File.dirname( __FILE__ ) + '/../lib'

require 'assembly_tool'
require 'fileutils'
require 'rexml/document'

class Assembler 

  attr_accessor :tool
  attr_accessor :jboss_zip
  attr_accessor :jruby_zip

  attr_accessor :torquebox_version
  attr_accessor :jboss_version
  attr_accessor :jruby_version

  attr_accessor :m2_repo

  def initialize() 
    @tool = AssemblyTool.new
    determine_versions

    @m2_repo   = nil 
    if ( ENV['M2_REPO'] ) 
      @m2_repo = ENV['M2_REPO']
    else
      @m2_repo   = ENV['HOME'] + '/.m2/repository'
    end

    puts "Maven repo: #{@m2_repo}"
    @jboss_zip = @m2_repo + "/org/jboss/as/jboss-as-build/#{@jboss_version}/jboss-as-build-#{@jboss_version}.zip"
    @jruby_zip = @m2_repo + "/org/jruby/jruby-dist/#{@jruby_version}/jruby-dist-#{@jruby_version}-bin.zip"
  end

  def determine_versions
    doc = REXML::Document.new( File.read( tool.base_dir + '/../../parent/pom.xml' ) )
    @torquebox_version = doc.get_elements( "project/version" ).first.text
    @jboss_version     = doc.get_elements( "project/properties/version.jbossas" ).first.text
    @jruby_version     = doc.get_elements( "project/properties/version.jruby" ).first.text
    puts "TorqueBox.... #{@torquebox_version}" 
    puts "JBoss........ #{@jboss_version}" 
    puts "JRuby........ #{@jruby_version}"
    #puts doc
  end

  def clean()
    FileUtils.rm_rf   tool.build_dir
  end

  def prepare()
    FileUtils.mkdir_p tool.torquebox_dir
    FileUtils.mkdir_p tool.gem_repo_dir
  end

  def lay_down_jboss
    if File.exist?( tool.jboss_dir ) 
      #puts "JBoss already laid down"
    else
      puts "Laying down JBoss"
      Dir.chdir( File.dirname( tool.jboss_dir ) ) do 
        `unzip -q #{jboss_zip}`
        original_dir= File.expand_path( Dir[ 'jboss-*' ].first )
        FileUtils.mv original_dir, tool.jboss_dir
      end
    end
  end

  def lay_down_jruby
    if ( File.exist?( tool.jruby_dir ) )
      #puts "JRuby already laid down" 
    else
      puts "Laying down JRuby" 
      Dir.chdir( File.dirname( tool.jruby_dir ) ) do
        `unzip -q #{jruby_zip}`
        original_dir= File.expand_path( Dir[ 'jruby-*' ].first )
        FileUtils.mv original_dir, tool.jruby_dir
      end
    end
  end

  def install_modules
    modules = Dir[ tool.base_dir + '/../../modules/*/target/*-module/' ].map do |module_dir|
      [ File.basename( module_dir, '-module' ).gsub( /torquebox-/, '' ), module_dir ]
    end

    # Ensure core module is first
    modules.unshift( modules.assoc( "core" ) ).uniq!

    modules.each do |module_name, module_dir|
      tool.install_module( module_name, module_dir )
    end
  end

  def install_gems
    # Install gems in order specified by modules in gems/pom.xml
    gem_pom = REXML::Document.new( File.read( tool.base_dir + '/../../gems/pom.xml' ) )
    gem_dirs = gem_pom.get_elements( "project/modules/module" ).map { |m| m.text }

    gem_dirs.each do |gem_dir|
      Dir[ tool.base_dir + '/../../gems/' + gem_dir + '/target/*.gem' ].each do |gem_package|
        puts "Install gem: #{gem_package}"
        tool.install_gem( gem_package )
      end
    end
    tool.update_gem_repo_index
  end

  def install_share
    # torquebox-rake-support gem needs this
    puts "TODO: Need to install share dir for torquebox-rake-support"
  end

  def assemble() 
    #clean
    prepare
    lay_down_jruby
    lay_down_jboss
    install_modules
    install_gems
    install_share
  end
end

Assembler.new.assemble


#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'open-uri'
require 'rubygems'
require 'plist'
require 'zlib'
require 'archive/tar/minitar'
include Archive::Tar

release = 'mac-os-x-1081'
targetdir = 'projects'
tmpdir = '.projects.tmp'
releaseurl = "http://opensource.apple.com/release/#{release}/"

releaseplist = "http://opensource.apple.com/plist/#{release}.plist"
print "# Downloading package list…"
STDOUT.flush
data = Plist.parse_xml(open(releaseplist).read)
puts " OK"

if ARGV.length == 0
  puts "# Listing all projects from #{releaseurl}"
  data["projects"].each do | key, value |
    puts "   #{key}"
  end
  exit(0)
end
ARGV.each do | projectname |
  project = data["projects"][projectname]
  projectdir = "#{projectname}-#{project['version']}"
  tgzurl = "http://opensource.apple.com/tarballs/#{projectname}/#{projectdir}.tar.gz"
  if File.exists?(File.join(targetdir, projectdir))
    puts "#{projectdir} already downloaded, skipping."
    next
  end
  print "Downloading and untarring #{tgzurl}…"
  STDOUT.flush
  tgz = Zlib::GzipReader.new(open(tgzurl))
  Minitar.unpack(tgz, tmpdir)
  File.rename(File.join(tmpdir, projectdir), File.join(targetdir, projectdir))
  puts " OK."
end
puts "Kthxbye."

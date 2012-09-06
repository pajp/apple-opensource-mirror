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

if ARGV[0] == "--release"
  ARGV.shift
  release = "mac-os-x-" + ARGV.shift.gsub(/\./, "")
end

releaseplist = "http://opensource.apple.com/plist/#{release}.plist"
print "# Downloading package list from #{releaseplist}…"
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

def tag_project(dir, release)
    `xattr -w nu.dll.aosm.#{release} \`date +%s\` "#{dir}"`
end

if not File.exists?(targetdir)
  Dir.mkdir(targetdir)
end

ARGV.each do | projectname |
  project = data["projects"][projectname]
  projectdir = "#{projectname}-#{project['version']}"
  tgzurl = "http://opensource.apple.com/tarballs/#{projectname}/#{projectdir}.tar.gz"
  fulltarget = File.join(targetdir, projectdir)
  if File.exists?(fulltarget)
    puts "#{projectdir} already downloaded, skipping."
    tag_project(fulltarget, release)
    next
  end
  print "Downloading and untarring #{tgzurl}…"
  STDOUT.flush
  begin
    tgz = Zlib::GzipReader.new(open(tgzurl))
    Minitar.unpack(tgz, tmpdir)
    File.rename(File.join(tmpdir, projectdir), fulltarget)
    tag_project(fulltarget, release)
    puts " OK."
  rescue OpenURI::HTTPError
    puts " failed."
  end
end
puts "Kthxbye."

#!/usr/bin/env ruby
#
# This script iterates over all projects downloaded by mirror.rb and fetch.sh,
# creates a git repository for each project and attempts to create a git commit
# for each project version in the correct order. It also creates git tags for
# the OS releases containing a particular version, making it easy to track
# changes between OS releases and e.g. get diffs between arbitrary versions
#

# problematic projects
ignore = [ 'libauto' ]

require 'strscan'

# https://github.com/jordi/version_sorter/blob/master/version_sorter.rb
module VersionSorter
  extend self

  def sort(list)
    ss     = StringScanner.new ''
    pad_to = 0
    list.each { |li| pad_to = li.size if li.size > pad_to }

    list.sort_by do |li|
      ss.string = li
      parts     = ''

      begin
        if match = ss.scan_until(/\d+|[a-z]+/i)
          parts << match.rjust(pad_to)
        else
          break
        end
      end until ss.eos?

      parts
    end
  end

  def rsort(list)
    sort(list).reverse!
  end
end

if not File.exists?("projects")
  puts "No projects found."
  exit 1
end

projects = {}

Dir.entries("projects").each do | projectdir |
  next if projectdir == "." or projectdir == ".."
  projectname, projectversion = projectdir.split("-")
  next if ignore.include?(projectname)
  if ARGV.count > 0
    inargs = false
    ARGV.each do | arg |
      if projectname == arg
        inargs = true
      end
    end
    next unless inargs;
  end
  if not projects[projectname]
    projects[projectname] = [ projectversion ]
  else
    projects[projectname].push(projectversion)
  end
end

basedir = Dir.pwd

if not ENV.include?('GITHUB_AUTH')
  puts "Warning: GITHUB_AUTH not defined, will not create GitHub projects"
end

index = open("projects.html", "w")

basehref = "http://github.com/aosm/"
index.puts "<ul>"

projects.keys.sort.each do | project | 
  puts "PROJECT: #{project}"
  index.puts "<li><a id=\"#{project}\" href=\"#{basehref}#{project}\">#{project}</a>: "

  Dir.chdir(basedir)
  versions = VersionSorter.sort(projects[project])
  gitdir = "gitify/#{project}"
  if not File.exists?(gitdir)
    Dir.mkdir(gitdir)
  end
  if not File.exists?("#{gitdir}/.git")
    system "git init #{gitdir}"
  end

  Dir.chdir(gitdir)
  json_file = "../../metadata/#{project}.github.json"
  if not File.size?(json_file) and ENV.include?('GITHUB_AUTH')
    puts "Creating GitHub repo"
    system "curl -i -u #{ENV['GITHUB_AUTH']} https://api.github.com/orgs/aosm/repos -d '{\"name\":\"#{project}\"}' > #{json_file}"
  end
  if ENV.include?('GITHUB_AUTH') and `git remote`.chomp.eql?("")
    puts "Adding remote"
    system "git remote add origin git@github.com:aosm/#{project}"
  end

  puts "Generating HTML"
  index.puts "versions: <ul>"
  versions.each do | version |
    version_os_printed = {}
    index.puts "<li><a id=\"#{project}-#{version}\" href=\"#{basehref}#{project}/tree/#{version}\">#{version}</a> "
    srcdir = "#{basedir}/projects/#{project}-#{version}"
    xattrs = `xattr -l #{srcdir} | grep '^nu\.dll.aosm\.' | cut -f 1 -d :`.split(/[\r\n]+/)
    index.puts " in OS releases: "
    xattrs.each do | xattr |
      tag = xattr.sub("nu.dll.aosm.", "")
      if not version_os_printed.include?(tag)
        index.puts "<a href=\"#{basehref}#{project}/tree/#{tag}\">#{tag}</a> "
        version_os_printed[tag] = true
      end
    end
  end
  index.puts "</ul>"

  if not `git tag -l #{versions[-1]}`.chomp.eql?("")
    puts "The latest version (#{versions[-1]}) already imported to git"
  else
    versions.each do | version | 
      puts "VERSION: #{version}"
      if not `git tag -l #{version}`.chomp.eql?("")
        puts "Version #{version} already imported to git"
        next
      end
      puts "Importing version #{version}"
      srcdir="#{basedir}/projects/#{project}-#{version}"
      xattrs=`xattr -l #{srcdir} | grep '^nu\.dll.aosm\.' | cut -f 1 -d :`.split(/[\r\n]+/)
      if not system "rsync -avz --delete --exclude=.git #{srcdir}/ ."
        puts "Error: failed to rsync #{project} version #{version}"
        exit 1
      end
      if not system "git add ."
        puts "Error: failed to add #{project} version #{version} to git"
        exit 1
      end
      if not system "git commit -am \"version #{version}\""
        puts "Error: failed to commit #{project} version #{version} to git"
        exit 1
      end    
      if not system "git tag #{version}"
        puts "Error: failed to tag #{project} version #{version}"
        exit 1
      end
      xattrs.each do | xattr |
        tag = xattr.sub("nu.dll.aosm.", "")
        if not system "git tag #{tag}" 
          puts "Error: failed to set release tag #{tag} for #{project} version #{version}"
          exit 1
        end
      end
    end
  end
  tree_push_file = "../../metadata/#{project}-#{versions[-1]}.tree.pushed"
  tags_push_file = "../../metadata/#{project}-#{versions[-1]}.tags.pushed"
  if not File.exists?(tree_push_file)
    if system "git push --all -u origin"
      system "touch #{tree_push_file}"
    end
  end
  if not File.exists?(tags_push_file)
    if system "git push --tags"
      system "touch #{tags_push_file}"
    end
  end
end
index.puts "</ul>"
index.close

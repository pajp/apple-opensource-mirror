#!/usr/bin/env ruby
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

include VersionSorter
projects = {}
Dir.entries("projects").each do | projectdir |
  next if projectdir == "." or projectdir == ".."
  projectname, projectversion = projectdir.split("-")
  if not projects[projectname]
    projects[projectname] = [ projectversion ]
  else
    projects[projectname].push(projectversion)
  end
end

basedir = Dir.pwd

projects.keys.sort.each do | project | 
  Dir.chdir(basedir)
  versions = VersionSorter.sort(projects[project])
  gitdir = "gitify/#{project}"
  if not File.exists?(gitdir)
    Dir.mkdir(gitdir)
  end
  if not File.exists?("#{gitdir}/.git")
    puts `git init #{gitdir}`
  end

  versions.each do | version | 
    puts "PROJECT: #{project} VERSION: #{version}" 
    Dir.chdir(basedir)
    Dir.chdir(gitdir)
    if `git remote`.chomp.eql?("")
      system("curl -i -u #{ENV['GITHUB_AUTH']} https://api.github.com/orgs/aosm/repos -d '{\"name\":\"#{project}\"}' > ../../#{project}.github.json");
      system("git remote add origin git@github.com:aosm/#{project}");
    end
    if not `git tag -l #{version}`.eql?("")
      puts "already imported to git"
      system("git push --all -u origin")
      system("git push --tags")
      next
    end
    srcdir="#{basedir}/projects/#{project}-#{version}"
    xattrs=`xattr -l #{srcdir} | grep '^nu\.dll.aosm\.' | cut -f 1 -d :`.split(/[\r\n]+/)
    system("rsync -avz --delete --exclude=.git #{srcdir}/ .");
    system("git add .");
    system("git commit -am \"version #{version}\""); 
    system("git tag #{version}");
    xattrs.each do | xattr |
      tag = xattr.sub("nu.dll.aosm.", "")
      system("git tag #{tag}");
    end
    system("git push --all -u origin")
    system("git push --tags")
  end
end


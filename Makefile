index.html: header.html projects.html footer.html
	cat header.html projects.html footer.html > $@

projects.html: gitify.rb
	./gitify.rb


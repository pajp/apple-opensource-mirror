index.html: header.html projects.html footer.html
	cat header.html projects.html footer.html | sed -e 's/%DATE%/'"`date`"/g > $@

projects.html: gitify.rb
	./gitify.rb


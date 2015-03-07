gulp = require 'gulp'
shell = require 'gulp-shell'

gulp.task 'docs', shell.task './node_modules/.bin/endokken --extension html'

gulp.task 'website', ['docs']

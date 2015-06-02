del = require 'del'
gulp = require 'gulp'
shell = require 'gulp-shell'
rsync = require 'gulp-rsync'

gulp.task 'clean:docs', (callback) ->
  del 'docs', callback

gulp.task 'docs', ['clean:docs'], shell.task 'endokken --extension html'

gulp.task 'docs-deploy', ['docs'], ->
  gulp.src 'docs/*'
  .pipe rsync
    root: 'docs',
    hostname: 'spawn.rpvhost.net',
    destination: '/home/jysperm/mabolo'

gulp.task 'website', ['docs-deploy']

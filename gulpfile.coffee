gulp = require 'gulp'
shell = require 'gulp-shell'
rsync = require 'gulp-rsync'

gulp.task 'docs', shell.task 'endokken --extension html'

gulp.task 'docs-deploy', ['docs'], ->
  gulp.src 'docs/*'
  .pipe rsync
    root: 'docs',
    hostname: 'spawn.rpvhost.net',
    destination: '/home/jysperm/mabolo'

gulp.task 'test', shell.task [
  'mocha --colors --compilers coffee:coffee-script/register'
  '--require test/env -- test/*.test.coffee'
].join ' '

gulp.task 'test-bail', shell.task [
  'mocha --colors --compilers coffee:coffee-script/register'
  '--require test/env --bail -- test/*.test.coffee'
].join(' '), ignoreErrors: true

gulp.task 'website', ['docs-deploy']

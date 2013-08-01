fs = require 'fs'
fs = require 'fs'
exec = require('child_process').exec

task "docs", "generate documentation", ->
  exec "docco README.md jnoid.coffee.md examples/*.coffee.md"
  fs.writeFileSync "#{__dirname}/docs/index.html", '
<!DOCTYPE html>
<html>
<head>
  <title>Jnoid simple example</title>
  <meta http-equiv="refresh" content="0; url=README.html">
</head>
<body>
Redirecting to <a href="README.html">README.html</a>
</body>
</html>
  '
  exec "cd docs && git add --all && git commit -m 'Re-generated documentation.' && git push origin gh-pages"
  exec "git submodule update"
  console.log "Documentation has been updated."


# Until GitHub has proper Literate CoffeeScript highlighting support, let's
# manually futz the README ourselves.
task "readme", "rebuild the readme file", ->
  source = fs.readFileSync('jnoid.coffee.md').toString()
  source = source.replace /\n\n    ([\s\S\n]*?)\n\n(?!    )/mg, (match, code) ->
    "\n```coffeescript\n#{code.replace(/^    /mg, '')}\n```\n"
  fs.writeFileSync 'README.md', source

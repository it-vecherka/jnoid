fs = require 'fs'

task "doc", "generate documentation", ->
  exec "docco -l linear jnoid.coffee.md"

# Until GitHub has proper Literate CoffeeScript highlighting support, let's
# manually futz the README ourselves.
task "readme", "rebuild the readme file", ->
  source = fs.readFileSync('jnoid.coffee.md').toString()
  source = source.replace /\n\n    ([\s\S\n]*?)\n\n(?!    )/mg, (match, code) ->
    "\n```coffeescript\n#{code.replace(/^    /mg, '')}\n```\n"
  fs.writeFileSync 'README.md', source

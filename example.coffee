fs = require 'fs'
coffeescript = require 'coffee-script'
_ = require 'underscore'
express = require 'express'
examplesList = fs.readdirSync("#{__dirname}/examples")
argv = require('optimist').argv

exampleName = argv._[0] or throw "Specify the example name. Available examples: #{examplesList}"
app = express()

app.get '/', (req, res)->
  res.set('Content-Type', 'text/html')
  res.send '
<!DOCTYPE html>
<html>
<head>
  <title>Jnoid simple example</title>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">

  <script src="http://code.jquery.com/jquery-latest.min.js" type="text/javascript"></script>
  <link href="http://netdna.bootstrapcdn.com/bootstrap/3.0.0-rc1/css/bootstrap.min.css" rel="stylesheet">
  <script src="http://netdna.bootstrapcdn.com/bootstrap/3.0.0-rc1/js/bootstrap.min.js"></script>

</head>
<body>

  <div class="navbar navbar-inverse">
    <div class="navbar-inner">
      <div class="container">
        <a class="navbar-brand" href="#">Jnoid</a>
      </div>
    </div>
  </div>

  <div class="container" id="center">
  </div>

  <script type="text/javascript">
    window.template = function (html) {
      $("#center").html(html);
    }
  </script>
  <script type="text/javascript" src="jnoid.js"></script>
  <script type="text/javascript" src="example.js"></script>
</body>
</html>
'

app.get '/jnoid.js', (req, res)->
  source = fs.readFileSync(fs.realpathSync("#{__dirname}/jnoid.coffee.md", "utf-8")).toString()
  res.set('Content-Type', 'text/javascript')
  res.send coffeescript.compile source, literate: true

app.get '/example.js', (req, res)->
  source = fs.readFileSync(fs.realpathSync("#{__dirname}/examples/#{exampleName}.coffee.md", "utf-8")).toString()
  res.set('Content-Type', 'text/javascript')
  res.send coffeescript.compile source, literate: true

app.get '/check-login/:login', (req, res)->
  if _.contains ['Peter', 'Jack', 'Jackson', 'Samuel'], req.params.login
    res.send 406, "Peter, Jack, Jackson and Samuel is taken"
  else
    res.send 200, "The name '#{req.params.login}' is available for new login"

app.get '/register', (req, res)->
  if req.query['login'] && req.query['fullname']
    res.send 200, "Ok"
  else
    res.send 406, "Not Acceptable"

app.listen(3000)
console.log "Starting example `#{exampleName}` on 3000"
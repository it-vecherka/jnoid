fs = require 'fs'
coffeescript = require 'coffee-script'
_ = require('underscore')
express = require('express')
app = express()

app.use express.static "#{__dirname}/public"

app.get '/jnoid.js', (req, res)->
  source = fs.readFileSync(fs.realpathSync("#{__dirname}/../../jnoid.coffee.md", "utf-8")).toString()
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

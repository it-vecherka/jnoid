_ = require('underscore')
express = require('express')
app = express()


app.use express.static "#{__dirname}/public"

app.get '/check-login/:login', (req, res)->
  if _.contains ['Peter', 'Jack', 'Jackson', 'Samuel'], req.params.login
    res.send 406, "Peter, Jack, Jackson and Samuel is busy"
  else
    res.send 200, "The name '#{req.params.login}' is availavbe for new login"

app.get '/register', (req, res)->
  if req.query['login'] && req.query['fullname'] && req.query['fullname'].length < 30
    res.send 200, "Ok"
  else
    res.send 406, "Not Acceptable"



app.listen(3000)
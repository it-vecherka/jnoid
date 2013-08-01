Simple example
======

Here is a template for the form which required for the current example

    template('
        <form class="form-horizontal" action="/register" method="get">
          <div class="control-group" id="login">
            <label class="control-label" for="inputLogin">Login</label>
            <div class="controls">
              <input type="text" id="inputLogin" placeholder="Login" name="login">
              <span class="help-block"><!-- to display validation errors --></span>
            </div>
          </div>
          <div class="control-group" id="fullname">
            <label class="control-label" for="inputPassword">Fullname</label>
            <div class="controls">
              <input type="text" id="inputFullname" placeholder="Fullname" name="fullname">
              <span class="help-block"><!-- to display validation errors --></span>
            </div>
          </div>
          <div class="control-group">
            <div class="controls">
              <button type="submit" id="submit" class="btn" disabled="disabled">Sign in</button>
            </div>
          </div>
        </form>
    ')

So lets start with the example

    textFieldValue = (textField) ->
      Jnoid.Stream.fromDOM(textField, "keyup input").map((e) ->
        $(e.target).val()
      ).box($(textField).val()).skipDuplicates()

    Messages =
      provideLogin: "Provide login"
      provideFullname: "Provide fullname"
      fullnameTooLong: "Fullname is too long"
      checking: "Checking"
      good: "Good"

    isGood = (message) -> message is Messages.good

    nonEmpty = (x) -> x.length > 0

    validateAjax = (params) ->
      Jnoid.Stream.fromPromise($.ajax(params)).box(Messages.checking).map(->
        Messages.good
      ).recover (e) ->
        e.responseText


    validateLogin = (login) ->
      if login.length <= 0
        Messages.provideLogin
      else
        Messages.good

    validateFullname = (fullname) ->
      if fullname.length <= 0
        Messages.provideFullname
      else if fullname.length > 30
        Messages.fullnameTooLong
      else
        Messages.good

    login = textFieldValue($("#login input"))
    fullname = textFieldValue($("#fullname input"))
    toLoginCheck = (login) ->
      url: "/check-login/" + login

    availMessages = login.filter(nonEmpty).map(toLoginCheck).flatMap(validateAjax)
    loginMessages = login.map(validateLogin).merge(availMessages)
    fullnameMessages = fullname.map(validateFullname)
    buttonEnabled = loginMessages.map(isGood).and(fullnameMessages.map(isGood))

The `setAttribute` is a helper, but it not in the library yet.

    setAttribute = (element, attribute) ->
      (value) ->
        $(element).attr attribute, value

    setText = (element) ->
      (value) ->
        $(element).text value


So, here is the application

    loginMessages.onValue setText $("#login .help-block")
    fullnameMessages.onValue setText $("#fullname .help-block")
    buttonEnabled.not().onValue setAttribute $("#submit"), "disabled"

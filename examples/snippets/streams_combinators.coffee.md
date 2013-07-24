Streams api
===========

Quick review of the api we may want on streams

Constructors
------------

`unit` makes a stream that throws one value and immediately ends.

    Jnoid.unit() # empty stream
    Jnoid.unit(10) # stream with immediate value of 10

`error` makes a stream that throws one error and immediately ends.

    Jnoid.error(10) # stream with immediate error of 10

`fromPromise` makes a stream from a promise, e.g., ajax.

    Jnoid.fromPromise $.ajax params

`fromDom` makes a stream from DOM events:

    Jnoid.fromDOM $("#input"), "keyup"

Simple transforms
-----------------

`map` transforms values. For example, the following will return a list of
true-false values.

    priceValue.map (x)-> x > 0

`filter` keeps in stream only values that match the predicate. For
example the following will return a stream of only positive values in
that stream.

    priceValue.filter (x)-> x > 0

`take` returns a stream proxying values from the base stream,
ending after `n` values.

    voteClick.take 10

`takeWhile` returns a stream proxying values from the base stream,
ending when a predicate on a value returns `false`.

    healthPoints.takeWhile (hp)-> hp > 0

`skipDuplicates` returns a stream proxying values from the base
stream, skipping the consequtive duplicates.

    username.skipDuplicates()

`recover` returns a stream, keeping values intact, but turning
errors from the base stream to values, using the transform
function.

    ajaxResponse.recover (e)-> e.responseText

Advanced transforms
-------------------

`merge` merges streams into just one stream. When event appears on
any of them, it appears in resulting stream. Stream ends when all
merged streams end.

    plusClicks.map(-> 1).merge(minusClicks.map(-> -1))

`zip` merges stream into one in a totally different way. It holds
till all of the zipped streams has a value, then it pops in a
resulting stream a touple with the latest values of each stream.

    usernameOk = username.map (x)-> x.length > 0
    username.zip(usernameOk)

`zipWith` applies a function to the resulting tuple afterwards.

    password.zipWith passwordConfirmation, (l, r)-> l == r

`and`, `or` and `not` are obvious:

    usernameOk.and passwordOk
    drivingLicensePresent.or hasCar.not()

`takeUntil` takes values from base stream until a value pops on
another stream, then ends.

    ajaxInProcess.takeUntil ajaxResponse

`debounce` only passes events after a quiet period.

    username.debounce 500

Hardcode: the flatMap
---------------------

`flatMap` is a serious businees. It takes a function that
transforms values in original stream to streams. Then it collects
all of them to the resulting stream, as `merge` does. It ends when
root stream ends and all of the children ends.

    listenTo.flatMap ([source, object])->
      if source == "dom"
        Jnoid.fromDOM($(object), "click")
      else if source == "ajax"
        Jnoid.fromPromise($.ajax(object))
      else
        Jnoid.unit()

`flatMapLatest` is mostly the same, but instead of including
events from latest spawned stream it includes events only from
latest spawned stream. It can be thought as a switch from one
stream to another.

    requests = usernames.map((u)-> "/check-username/" + u)
    requests.flatMapLatest($.ajax)

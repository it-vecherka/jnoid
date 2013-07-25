Signals api
===========

Quick review of the api we may want on signals

Constructors
------------

`unit` makes a signal that throws one value and immediately ends.

    Signal.unit() # empty signal
    Signal.unit(10) # signal with immediate value of 10

`error` makes a signal that throws one error and immediately ends.

    Signal.error(10) # signal with immediate error of 10

`fromPromise` makes a signal from a promise, e.g., ajax.

    Signal.fromPromise $.ajax params

`fromDom` makes a signal from DOM events:

    Signal.fromDOM $("#input"), "keyup"

Simple transforms
-----------------

`map` transforms values. For example, the following will return a list of
true-false values.

    priceValue.map (x)-> x > 0

`filter` keeps in signal only values that match the predicate. For
example the following will return a signal of only positive values in
that signal.

    priceValue.filter (x)-> x > 0

`take` returns a signal proxying values from the base signal,
ending after `n` values.

    voteClick.take 10

`takeWhile` returns a signal proxying values from the base signal,
ending when a predicate on a value returns `false`.

    healthPoints.takeWhile (hp)-> hp > 0

`skipDuplicates` returns a signal proxying values from the base
signal, skipping the consequtive duplicates.

    username.skipDuplicates()

`recover` returns a signal, keeping values intact, but turning
errors from the base signal to values, using the transform
function.

    ajaxResponse.recover (e)-> e.responseText

Advanced transforms
-------------------

`merge` merges signals into just one signal. When event appears on
any of them, it appears in resulting signal. Signal ends when all
merged signals end.

    plusClicks.map(-> 1).merge(minusClicks.map(-> -1))

`zip` merges signal into one in a totally different way. It holds
till all of the zipped signals has a value, then it pops in a
resulting signal a touple with the latest values of each signal.

    usernameOk = username.map (x)-> x.length > 0
    username.zip(usernameOk)

`zipWith` applies a function to the resulting tuple afterwards.

    password.zipWith passwordConfirmation, (l, r)-> l == r

`and`, `or` and `not` are obvious:

    usernameOk.and passwordOk
    drivingLicensePresent.or hasCar.not()

`takeUntil` takes values from base signal until a value pops on
another signal, then ends.

    ajaxInProcess.takeUntil ajaxResponse

`debounce` only passes events after a quiet period.

    username.debounce 500

Hardcode: the flatMap
---------------------

`flatMap` is a serious businees. It takes a function that
transforms values in original signal to signals. Then it collects
all of them to the resulting signal, as `merge` does. It ends when
root signal ends and all of the children ends.

    listenTo.flatMap ([source, object])->
      if source == "dom"
        Signal.fromDOM($(object), "click")
      else if source == "ajax"
        Signal.fromPromise($.ajax(object))
      else
        Signal.unit()

`flatMapLatest` is mostly the same, but instead of including
events from latest spawned signal it includes events only from
latest spawned signal. It can be thought as a switch from one
signal to another.

    requests = usernames.map((u)-> { url: "/check-username/" + u })
    requests.flatMapLatest($.ajax)

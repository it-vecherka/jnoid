// # Signals
//
// The whole idea of event signals in three paragraphs.
//
// 1) We usually do:
$("#login").on("click", function (event) {
  value = $(event.target).val();
  if (value.length > 0) {
    $("#notice").text();
  }
});

// 2) Let's do a proxy:
var clickSignal = $("#login").signal("click");
clickSignal.onValue(function (event) {
  value = $(event.target).val();
  if (value.length > 0) {
    $("#notice").text();
  }
});

// 3) Looks like we haven't got anything new.
// But now when we have the signal abstraction,
// we can:
var clickSignal = $("#login").signal("click");
var valueSignal = clickSignal.map(function (event) {
  return $(event.target).val();
});
var nonEmptyValueSignal = valueSignal.filter(function (value) {
  return value.length > 0;
});
nonEmptyValueSignal.onValue(function (value) {
  $("#notice").text(value);
});


// # Streams
//
// The whole idea of event steams in three paragraphs.
//
// 1) We usually do:
$("#login").on("click", function (event) {
  value = $(event.target).val();
  if (value.length > 0) {
    $("#notice").text();
  }
});

// 2) Let's do a proxy:
var clickStream = $("#login").stream("click");
clickStream.onValue(function (event) {
  value = $(event.target).val();
  if (value.length > 0) {
    $("#notice").text();
  }
});

// 3) Looks like we haven't got anything new.
// But now when we have the stream abstraction,
// we can:
var clickStream = $("#login").stream("click");
var valueStream = clickStream.map(function (event) {
  return $(event.target).val();
});
var nonEmptyValueStream = valueStream.filter(function (value) {
  return value.length > 0;
});
nonEmptyValueStream.onValue(function (value) {
  $("#notice").text(value);
});


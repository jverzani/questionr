
// show first tabs for any tabs
var tmp = $(".nav-tabs")
$.each(tmp, function(key, value) {
  $("#" + value.id + " a:first").tab("show")
});
 
// scroll spy
$("#navbar").scrollspy();
$("body").attr("data-spy", "scroll");
$("[data-spy=\'scroll\']").each(function () {
  var $spy = $(this).scrollspy("refresh")
});


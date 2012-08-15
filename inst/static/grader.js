// grading functions by type
function grade_radio(ans, value) {console.log(ans + ":" + value);return( ans == value ? 100 : 0) };
function grade_checkboxgroup(ans, value) {
  var out=[];
  $.each(ans, function(key, value) { if(value != null) { out.push(value) }});
  if(out.length != value.length) { return(0) };
  out = out.sort();
  var value = value.sort()
  for(var i=0; i < out.length; i++) {
    if(out[i] != value[i]) { return(0) }
  }
  return(100)
};
function grade_typeahead(ans, value) { return( (ans == value) ? 100 : 0 )};
function grade_combo(ans, value) { return( (ans == value) ? 100 : 0) };
function grade_numeric(ans, value) {var ans = parseFloat(ans); return( (ans >= value[0] && ans <= value[1]) ? 100 : 0) };



// submit function
function submit_work(status) {
    $.ajax({
	url:"{{{base_url}}}/set_answers",
	type:"POST",
	data: {
	    answers:JSON.stringify(student_answers),
	    status:status,
	    project_id:page_id
	},
	success:function(data) {
	    // redirect to base url
	    window.location.replace("{{{base_url}}}");
	}
    });
};

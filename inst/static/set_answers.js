// functions to set answers

function set_radio(id, value) {
  $("#" + id + " [value=" + value + "]").attr("checked", true);
};

function set_checkboxgroup(id, value) {
  // clear out then set
  $("#" + id + " [type=checkbox]").attr("checked", false);
  $.each(value, function(idx, val) {
    $("#" + id + " [value=" + val + "]").attr("checked", true)
  })
};


function set_typeahead(id, value) {
    $("#" + id).val(value)
};

function set_combo(id, value) {
    if(value.length > 0) {
	$("#" + id + " [value=" + value + "]").attr("selected", true)
    } else {
	$("#" + id)[0].selectedIndex=0;
    }

};

function set_numeric(id, value) {
    $("#" + id).val(value)
};

function set_free(id, value) {
    $("#" + id).val(value);
};

function set_answer(o) {
    // o is object with id=problem, type, value=answer
    var id = o.problem; 
    var value = o.answer;
    var type = o.type
    if(type == "radio") {
	set_radio(id, value)
    } else if(type == "checkbox") {
	set_checkboxgroup(id, value)
    } else if(type == "typeahead") {
	set_typeahead(id, value)
    } else if(type == "combo") {
	set_combo(id, value)
    } else if(type == "numeric") {
	set_numeric(id, value)
    } else if(type == "free") {
	set_free(id, value)
    }
};

// set all answers and comments from answers
// Careful!!! only want _comment set if status=graded!
function set_answers(status, stud_ans) {
    $.each(stud_ans, function(key, value) {
	set_answer(value);
	if(typeof(value.comment) != "undefined") {
	    var cmt = '<div class="alert"><a class="close" data-dismiss="alert" href="#">×</a>' + value.comment + '</div>'
	    // _help
	    var x =  $("#" + value.problem + "_help");
	    if(x.length > 0) {
		x[0].innerHTML = cmt;
	    }
	    if(status == "graded") {
		var x =  $("#" + value.problem + "_comment");
		if(x.length > 0) {
		    x[0].innerHTML = cmt;
		}
	    }
	}
    });
};


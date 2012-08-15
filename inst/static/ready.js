$(document).ready(function() {
    // set button
    $(".btn").button()

    var cmt_defaults={correct:comments.correct, 
		      incorrect:comments.incorrect,
		      missing:comments.missing
		     };	
    var fix_badge = function(key, tries, answer, comment) {
	$('#' + key + "_badge").each(function() {this.innerHTML = tries + (tries == 1 ? " try" : " tries")});
	$.each(['badge-info', 'badge-warning', 'badge-success'], function(idx, value) {
	    $('#' + key + "_badge").removeClass(value)
	});
	if(answer == true) {
	    $('#' + key + "_badge").addClass("badge-success");
	} else {
	    $('#' + key + "_badge").addClass("badge-warning");
	};
	// comments
	$('#' + key + "_help").each(function() {
	    this.innerHTML=
		"<div class='alert alert-info'><a class='close' data-dismiss='alert' href='#'>×</a>" + comment + "</div>";
	});
	
    }
    // close up comment for grading
    var close_comment = function(key) {
	$("#" + key + "_comment > .alert").alert("close");
    };
    // set radio buttons
    $("[type=\'radio\']").each(function() {
	student_answers[this.name]={problem:this.name, type:'radio', tries:0};
	this.onchange = function() {
	    var key = this.name;
	    var sans = this.value;
	    var answer = grade_radio(sans, actual_answers[key].value);
	    var comment = comment_default(answer, sans, comments[key], cmt_defaults); 
	    var tries = student_answers[key].tries + 1;
	    student_answers[key] = {
		problem:key,
		type:'radio',
		tries:tries,
		answer:sans,
		grade:answer,
		comment:comment
	    };
	    fix_badge(key, tries, answer, comment);
	}
    }
			      );
    // set checkbox -- doesn't work well here with tries
    $("[type=\'checkbox\']").each(function() {
	// populate answers
	var n = $("#" + this.name + "> .checkbox").length
	var ans = {};
	for(i=1; i <= n; i++) {ans[this.name + "_" + i] = null;}
	student_answers[this.name] = {
	    problem: this.name,
	    type:'checkbox',
	    tries:0,
	    answer:ans
	};
	this.onchange = function() {
	    var key = this.name;
	    var sans = student_answers[key].answer;
	    if(this.checked) {
		sans[this.id] = this.value;
	    } else {
		sans[this.id] = null;
	    }
	    var answer = grade_checkboxgroup(sans, actual_answers[key].value);
	    var comment = comment_checkgroup(answer, sans, comments[key], cmt_defaults); 
	    var tries = student_answers[key].tries + 1;

	    student_answers[key] = {
		problem:key,
		type:'checkbox',
		tries:tries,
		answer:sans,
		grade:answer,
		comment:comment
	    };
	    fix_badge(key, tries, answer, comment)
	}
    });
    // typeahead
    $(".typeahead").each(function() {
	if(this.id.length > 0) {
	    student_answers[this.id]={problem:this.id, type:'typeahead',  tries:0};
	}
	this.onchange = function() {
	    var key = this.id;
	    var sans = this.value;
	    var answer = grade_typeahead(sans, actual_answers[key].value);
	    var comment = comment_default(answer, sans, comments[key], cmt_defaults); 
	    var tries = student_answers[key].tries + 1;

	    student_answers[key] = {
		problem:key,
		type:"typeahead",
		tries:student_answers[key].tries + 1,
		answer:sans,
		grade:answer,
		comment:comment
	    };
	    fix_badge(key, tries, answer, comment)
	}
    });
    
    // combobox
    $(".combobox").each(function() { 
	student_answers[this.id]={problem:this.id, type:'combo', tries:0};
	this.onchange = function() {
	    var key = this.id;
	    var sans = this.value;
	    var answer = grade_combo(sans, actual_answers[key].value);
	    var comment = comment_default(answer, sans, comments[key], cmt_defaults); 
	    var tries = student_answers[key].tries + 1;

	    student_answers[key] = {
		problem:key,
		type:"combo",
		tries:tries,
		answer:sans,
		grade:answer,
		comment:comment
	    };
	    fix_badge(key, tries, answer, comment)
	}
    });
    // numeric
    $(".numeric_answer").each(function() {
	student_answers[this.id]={problem:this.id, type:'numeric', tries:0};
	this.onchange = function() {
	    var key = this.id;
	    var sans = this.value;
	    var answer = grade_numeric(sans, actual_answers[key].value);
	    var comment = comment_numeric(answer, sans, 
					  actual_answers[key].value,
					  comments[key],
					  cmt_defaults); 
	    var tries = student_answers[key].tries + 1;

	    student_answers[key] = {
		problem:key,
		type:"numeric",
		tries:tries,
		answer:sans,
		grade:answer,
		comment:comment
	    };
	    fix_badge(key, tries, answer, comment)
	}
    });
    // free
    $(".free").each(function() {
	student_answers[this.id]={problem:this.id, type:'free', tries:0};
	this.onchange = function() {
	    var key = this.id;
	    var sans = this.value;
	    student_answers[key].answer = sans;
	};
    });

    {{{GET_ANSWERS}}}
});


<script type="text/javascript"> 
var student_answers = {};
var comments = {missing:"Missing answer", correct:"Correct", incorrect:"Incorrect"};
var student_id = "{{{STUDENT_ID}}}";
var page_id = "{{{PAGE_ID}}}";
</script>

<link href="http://twitter.github.com/bootstrap/assets/css/bootstrap.css" rel="stylesheet">
<link href="http://twitter.github.com/bootstrap/assets/css/bootstrap-responsive.css" rel="stylesheet">
<script src="https://ajax.googleapis.com/ajax/libs/jquery/1.7.2/jquery.min.js" type="text/javascript"></script>
<script type="text/javascript" src="http://platform.twitter.com/widgets.js"></script> 
<script src="http://cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/2.0.3/bootstrap.min.js"></script>
<script src="http://twitter.github.com/bootstrap/assets/js/bootstrap-tooltip.js"></script>
<script src="http://twitter.github.com/bootstrap/assets/js/bootstrap-popover.js"></script>
<script src="http://twitter.github.com/bootstrap/assets/js/bootstrap-modal.js"></script>
<script src="http://twitter.github.com/bootstrap/assets/js/bootstrap-button.js"></script>
<script src="http://twitter.github.com/bootstrap/assets/js/bootstrap-typeahead.js"></script>
<script src="http://twitter.github.com/bootstrap/assets/js/bootstrap-tab.js"></script>
<script src="http://twitter.github.com/bootstrap/assets/js/bootstrap-scrollspy.js"></script>
<div id='main_message'></div>

<header class="jumbotron subhead"><h1>Using the questionr package</h1><p class='lead'>Basic explanations</p></header>

<span><div id="navbar" class="navbar  navbar-fixed-top"><div class="navbar-inner"><ul id="navbar-header" class="nav"></ul></div></div></span><span id="subnav"></span>



<script>$('#navbar-header').append("<li><a href='#nav1' target='_self'>About</a></li>");</script>
<span><div id="nav1"></div></span>
<span><div class='page-header'><h2>About</h2></div></span>

The `questionr` package has two purposes:

* to make a simple to use template to make self-contained quizzes to put on the web

* to create a basic web content management system to allow teachers and students to form sections of classes.

The writing of quizzes, called "projects" below is discussed elsewhere. For the rest of this document we will discuss the basic web framework presented for holding a section.




<script>$('#navbar-header').append("<li><a href='#nav2' target='_self'>Logging on</a></li>");</script>
<span><div id="nav2"></div></span>
<span><div class='page-header'><h2>Logging on</h2></div></span>


One goal of the project was to avoid having to deal with different
user logins and passwords. Students already have too many. The concept
of `openID` allows multiple websites to share login credentials. This
package uses `janrain.com` to provide a service that allows users to
login with several different account identities include `google` and
`yahoo` accounts. It is possible to link up with FaceBook accounts, but this hasn't been done.

Users should close the browser when finished if they wish to logout or
use the logout feature.

When a user first logs in, they are enrolled as a student in the
system. By default, a student is not part of any sections. They need to
enroll. A student has the option of enrolling in a public section or a
private one, if they know the section ID. The basic idea is a student
will be given a section ID by an instructor and they will then enroll.

A teacher must be given additional roles within the system. To make a request to be a teacher, requires someone to 

* open an account as a student go to the page at
 
*  `request_teacher_status` and make a request. This is not a link
   available to the student and must be typed in. A system
   adminstrator must authorize this new role.



<script>$('#navbar-header').append("<li><a href='#nav3' target='_self'>The student view</a></li>");</script>
<span><div id="nav3"></div></span>
<span><div class='page-header'><h2>The student view</h2></div></span>

Students have very limited options:

* They can enroll in a section if they know the id 

* They can view their work in each enrolled section

* They can work on a project

Working on a project is the only confusing aspect. Projects are one
long web page. Navigation is aided by a top-level navigation bar if
provided. A project can have several questions embedded in it. These
questions can be written to be self grading or may need to be graded
by the teacher of the section. Questions can have a badge to keep
track of the number of attempts, comments on a particular attempt, and
hints to aid in the question. Whether these features is present
depends on the project as written.

The basic flow is that student answer the questions as indicated. When
done they can "save" the work for their return or they can submit the
work to be graded. Once submitted, no more changes are possible.

The main student view shows the graded work and gives links to work on
projects. In addition messages left for the student are displayed
here.



<script>$('#navbar-header').append("<li><a href='#nav4' target='_self'>The teacher view</a></li>");</script>
<span><div id="nav4"></div></span>
<span><div class='page-header'><h2>The teacher view</h2></div></span>

Teachers have many possibilities

* They can admit students into a section. The basic idea is a student
  is given an ID to allow them to request enrollment. You can veto
  this enrollment, if desired.

* They can create a class. A class is a collection of projects with some order. The form to edit a class allows you to created a new class or modify an existing one.

* They can create a section. Students enroll in sections. Sections
  have a list of projects and a list of students. The projects can be
  cloned from an existing class allowing one to create sections for
  different semesters or time periods. Projects can be
  added/deleted/edited or viewed. It is important to be careful when
  modifying a project if students have already started doing that
  work.

* They can leave a student a message. Sections or students can have a
  message left for them using this form.

<!--- Finish this off -->


<script>
$('body').css('margin', '40px 10px');
//$('body').attr('data-offset','40');
//$('body').attr('data-target','#subnav');
$('body').attr('data-spy','scroll');
//$('[data-spy="scroll"]').each(function () {
//   var $spy = $(this).scrollspy('refresh')
//});
</script>



<div id='grade_alert'></div>
<script>

var tmp = $(".nav-tabs")
$.each(tmp, function(key, value) {
  $("#" + value.id + " a:first").tab("show")
});
 
$("#navbar").scrollspy();
$("body").attr("data-spy", "scroll");
$("[data-spy=\'scroll\']").each(function () {
  var $spy = $(this).scrollspy("refresh")
});

function comment_default(grade, stud_ans, comment, def) {
    var cmt = "";
    if(grade == 100) {
	cmt = def.correct;
    } else if(typeof(comment) != "undefined") {
	if(typeof(comment[stud_ans]) != "undefined") {
	    cmt = comment[stud_ans];
	} else {
	    cmt = def.incorrect;
	}
    } else {
	cmt = def.incorrect;
    }
    return cmt;
};

function comment_checkgroup(grade, stud_ans, comment, def) {
    var tmp = []; 
    $.each(stud_ans, function(key, value) {tmp.push(value)});
    return comment_default(grade, tmp.sort().join("::"), comment, def);
};

function comment_numeric(grade, stud_ans, value, comment, def) {
    var cmt = "";
    if(grade == 100) {
	cmt = def.correct;
    } else if(typeof(comment) != "undefined") {
	if(stud_ans < value[0]) {
	    if(typeof(comment.less) != "undefined") {
		cmt = comment.less
	    } else {
		cmt = def.incorrect
	    }
	} else if(stud_ans > value[1]) {
	    if(typeof(comment.more) != "undefined") {
		cmt = comment.more
	    } else {
		cmt = def.incorrect
	    }
	}
    } else {
	cmt = def.incorrect;
    }
    return cmt;
}
function grade_radio(ans, value) {return( ans == value ? 100 : 0) };
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
function grade_numeric(ans, value) { return( (ans >= value[0] && ans <= value[1]) ? 100 : 0) };



function submit_work(status) {
    $.ajax({
	url:"/set_answers",
	type:"POST",
	data: {
	    answers:JSON.stringify(student_answers),
	    status:status,
	    project_id:page_id
	},
	success:function(data) {
	    window.location.replace("");
	}
    });
};

function set_radio(id, value) {
  $("#" + id + " [value=" + value + "]").attr("checked", true);
};

function set_checkboxgroup(id, value) {
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

function set_answers(status, stud_ans) {
    $.each(stud_ans, function(key, value) {
	set_answer(value);
	if(typeof(value.comment) != "undefined") {
	    var cmt = '<div class="alert"><a class="close" data-dismiss="alert" href="#">×</a>' + value.comment + '</div>'
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

var is_open=false;

function write_grade_table() {
    var a = student_answers;
    if(is_open) {
	$("#gradealert").alert('close');
    } else {
	$("#grade_alert").append('<div id = "fillmein"></div>');

	$("#fillmein").append('<div id="gradealert" class="alert alert-block fade in"><button class="close" data-dismiss="alert">×</button>');
	$("#gradealert").append('<h2>Congratulations, your scores so far are:</h2>');  
	$("#gradealert").append('<table id="grade_alert_table" class="table table-bordered table-striped">');
	$("#gradealert").append("</table></div>");
	
	$("#grade_alert_table").append('<thead><tr><th>Problem</th><th>Score</th><th>Comment</th></tr></thead><tbody>');

	var icon_lookup = {true:"icon-thumbs-up", false:"icon-thumbs-down", missing:"icon-warning-sign"};
	var msg_lookup = {true:"Correct", false: "Incorrect", missing:"Missing"};

	$.each(a, function() {
	    $("#grade_alert_table").append("<tr>" +
					   "<td>" + 
					   "<a class='grade_clicker' href='#" + this.problem + "' target='_self'>" +
					   "Problem " + this.problem.replace("prob_", "") + "</a></td>" +
					   " <td>" + 
					   "<i class='" + icon_lookup[this.grade] + "'></i>&nbsp;" +
					   msg_lookup[this.grade] + "</td>" +
					   "<td>" + this.comment + "</td>" +
					   "</tr>");
	})
	    $("#grade_alert_table").append('</tbody>');
	$(".grade_clicker").each(function() { this.onclick = function() {$("#gradealert").alert('close')}})
	    $("#gradealert").alert();
	is_open = true;
	$("#gradealert").bind("closed", function() {is_open=false});
    }
};
$(document).ready(function() {
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
	$('#' + key + "_help").each(function() {
	    this.innerHTML=
		"<div class='alert alert-info'><a class='close' data-dismiss='alert' href='#'>×</a>" + comment + "</div>";
	});
	
    }
    var close_comment = function(key) {
	$("#" + key + "_comment > .alert").alert("close");
    };
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
    $("[type=\'checkbox\']").each(function() {
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
    $(".free").each(function() {
	student_answers[this.id]={problem:this.id, type:'free', tries:0};
	this.onchange = function() {
	    var key = this.id;
	    var sans = this.value;
	    student_answers[key].answer = sans;
	};
    });

    var restore_badges = function(x) {
    $.each(x, function(key, value) {
	var badge = $("#" + key + "_badge");
	if(badge.length > 0) {
	    var tries = x[key].tries;
	    badge[0].innerHTML = tries + " tries"
	}
    })
}
    // get answers from server, restore
    $.ajax({
	url:"http://localhost:9000/custom/quizr/get_answers", 
	type:'POST',
	data:{ project_id:page_id}, 
	success:function(data, status, jqxhr) {
	   
	    if(data.status == "error") {
		return null;
	    }
	    
	    student_answers = data.answers;
	    set_answers(data.status, data.answers);
	    restore_badges(student_answers);

	    if(data.status == "graded") {
		// no more changes!
		$("button").addClass("disabled");
		$("button").each(function() {this.onclick=null});
		    
		$.each($('[id*="prob"]'), function() {this.onchange = null});
		$("input").attr("disabled", "disabled");
		$("select").attr("disabled", "disabled");
		
		$(".badge").each(function() {this.innerHTML = "graded"});

		$("#main_message").append('<div class="alert alert-block alert-info"><a class="close" data-dismiss="alert" href="#">×</a><b>This was already graded</b>, no more changes are possible.</div>');
	    }
	}
    });
});
</script>
<script>var actual_answers=[];</script>

<script>comments={ "missing": "Missing answer","correct": "Correct answer","incorrect": "Incorrect answer" };</script>

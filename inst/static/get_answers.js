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
	url:"{{{base_url}}}/get_answers", 
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

		$("#main_message").append('<div class="alert alert-block alert-info"><a class="close" data-dismiss="alert" href="#">×</a>{{{msg}}}</div>');
	    }
	}
    });

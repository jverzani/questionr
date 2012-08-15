$(document).ready(function() {
    // set button
    $(".btn").button()
    // set radio buttons
    $("[type=\'radio\']").each(function() {this.onchange = function() {student_answers[this.name] = this.value}})
	// set checkbox
	$("[type=\'checkbox\']").each(function() {
	    this.onchange = function() {
		if(student_answers[this.name] == undefined) {student_answers[this.name] = {} }
		if(this.checked) {
		    student_answers[this.name][this.id] = this.value;
		} else {
		    student_answers[this.name][this.id] = null;
		}
	    }
	});
    // typeahead
    $(".typeahead").each(function() {this.onchange = function() {student_answers[this.id] = this.value}})
	// combobox
	$(".combobox").each(function() { this.onchange = function() {student_answers[this.id] = this.value}})
	    //
	    $(".numeric_answer").each(function() {this.onchange = function() {student_answers[this.id] = this.value}})
		});

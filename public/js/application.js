var current_file;

$(function() {
  setup_drag_n_drop("dropzone");
});

function setup_drag_n_drop(id) {
  id = document.getElementById(id);
  id.addEventListener("dragenter", dragEnter, false);
  id.addEventListener("dragleave", dragLeave, false);
  id.addEventListener("dragover", dragOver, false);
  id.addEventListener("drop", drop, false);
}

function dragEnter(evt) {
  evt.stopPropagation();
  evt.preventDefault();
  $(evt.target).removeClass("drag-inactive").addClass("drag-active");
}

function dragLeave(evt) {
  evt.stopPropagation();
  evt.preventDefault();
  $(evt.target).removeClass("drag-active").addClass("drag-inactive");
}

function dragOver(evt) {
  evt.stopPropagation();
  evt.preventDefault();
}

function drop(evt) {
  evt.preventDefault();
  $(evt.target).removeClass("drag-active").addClass("drag-inactive");

  var files = evt.dataTransfer.files;
  var count = files.length;
  var file = files[0];
  current_file = file;

  var reader = new FileReader(), filter = /^(text\/plain)$/i;
  reader.onload = handle_data;

  // Abort, when the user hasn't uploaded anything
  if (count <= 0) {return; }
  // Check if the file is a valid mp3
  if (!filter.test(file.type)) { show_error("Please only upload plain text"); return; }
  // Otherwise hide the error
  hide_error();

  reader.readAsText(file);
}

function show_error(msg) {
  $("#search-form.control-group").addClass("error");
  $(".help-inline").html(msg);
  $(".help-inline").show(DURATION);
}

function hide_error() {
  $("#search-form.control-group").removeClass("error");
  $(".help-inline").hide(DURATION);
  $(".help-inline").html("");
}

function handle_data(evt) {
  var text_data = evt.target.result;

  $.ajax({
    url: "/text",
    data: {
      text: text_data
    },
    type: 'POST'
  }).done(function() {
    // $(this).addClass("done");
    console.log("ajax worked");
  }).fail(function() {
    console.log("ajax failed");
  }).always(function() {
    console.log("ajax completed");
  });
}
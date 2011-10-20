# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/
$(document).ready ->
  options =
    lineNumbers: true
    enterMode: "indent"
    mode: "yaml"
  editor = CodeMirror.fromTextArea(document.getElementById("line_yaml"), options);

  $("#add_html").click ->
    count = $("div#textareas").children("textarea").length
    $(this).before("<li>form#{count}.html</li>")


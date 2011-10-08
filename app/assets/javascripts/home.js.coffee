# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/
$(document).ready ->
  line_yaml = $("textarea#line_yaml")
  yaml_line_numbers = $("textarea#yaml_line_numbers")
  line_yaml.bind "scroll", ->
    yaml_line_numbers.scrollTop $(this).scrollTop()

  line_yaml.bind "keypress", (event) ->
    self = $(this)
    previous_line_break = (text, current_index) ->
      current_char = text[current_index]
      if current_char is "\n" or current_index is 0
        current_index
      else
        previous_line_break(text, current_index - 1)

    previous_line = (text, current_index) ->
      line_end = previous_line_break(text, current_index)
      line_start = previous_line_break(text, line_end - 1)
      text[line_start..line_end]
    console.log self.getSelection()
    switch event.which
      when 13
        event.trigger
        current_position = self.getSelection()
        console.log current_position
        prev_line = previous_line(self.val(), current_position.start)
        self.setCaretPos(current_position.start + 2)
        console.log("enter")
        event.preventDefault
      else
        console.log(event.which)


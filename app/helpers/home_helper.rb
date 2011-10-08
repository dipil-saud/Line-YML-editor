module HomeHelper

  def line_numbers_text
    (1..999).map(&:to_s).join("\n")
  end
end


class LinesController < ApplicationController
  respond_to :html

  def new
    @line = Line.new
  end

  def create
    @line = Line.new(params)
    if @line.errors.empty? && @line.valid_yaml? && @line.create_in_cf
      render :text => "valid"
    else
      # else there are any errors
      render "new"
    end
  end

  # TODO validate the yaml through a js request
  def validate_yaml
  end

end


require 'spec_helper'

describe LinesController do

  describe "GET 'new'" do
    it "should be successful" do
      get 'new'
      response.should be_success
    end
  end

  describe "GET 'create'" do
    it "should be successful" do
      get 'create'
      response.should be_success
    end
  end

  describe "GET 'validate'" do
    it "should be successful" do
      get 'validate'
      response.should be_success
    end
  end

end

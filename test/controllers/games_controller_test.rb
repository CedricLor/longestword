require 'test_helper'

class GamesControllerTest < ActionController::TestCase
  test "should get display_grid" do
    get :display_grid
    assert_response :success
  end

  test "should get get_user_attempt" do
    get :get_user_attempt
    assert_response :success
  end

  test "should get display_user_results" do
    get :display_user_results
    assert_response :success
  end

end

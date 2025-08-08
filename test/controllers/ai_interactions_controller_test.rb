require 'test_helper'

class AiInteractionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @project = projects(:one) # Assuming you have a fixture for projects
    @user = users(:one)       # Assuming you have a fixture for users
    sign_in @user             # Sign in the user if using Devise
  end

  test "should get chat" do
    post chat_ai_interactions_url, params: { message: "Hello" }, headers: { 'HTTP_REFERER' => project_url(@project) }
    assert_response :success
  end

  test "should return error if user not found" do
    sign_out @user
    post chat_ai_interactions_url, params: { message: "Hello" }
    assert_response :unauthorized
  end

  test "should return error if project not found" do
    post chat_ai_interactions_url, params: { message: "Hello", project_name: "Nonexistent Project" }
    assert_response :unauthorized
  end

  test "should get chat history" do
    get chat_history_ai_interactions_url, headers: { 'HTTP_REFERER' => project_url(@project) }
    assert_response :success
  end
end

class DiscoverController < ApplicationController
  before_action :authenticate_user!

  def index
    unless APP_CONFIG.dig(:features, :discover, :enabled) || current_user.mod?
      return redirect_to root_path
    end

    top_x = 10  # only display the top X items
    id_time_since = (Time.now.ago(1.week).to_f * 1000).to_i << 16

    @popular_answers = Answer.where("id > ?", id_time_since).order(:smile_count).reverse_order.limit(top_x).includes(:user, question: [:user], comments: [:user, smiles: [:user]], smiles: [:user])
    @most_discussed = Answer.where("id > ?", id_time_since).order(:comment_count).reverse_order.limit(top_x).includes(:user, question: [:user], comments: [:user, smiles: [:user]], smiles: [:user])
    @popular_questions = Question.where("id > ?", id_time_since).order(:answer_count).reverse_order.limit(top_x).includes(:user, answers: [:user, comments: [:user, smiles: [:user]], smiles: [:user]])
    @new_users = User.where("asked_count > 0").order(:id).reverse_order.limit(top_x)

    # .user = the user
    # .question_count = how many questions did the user ask
    @users_with_most_questions = Question.select('user_id, COUNT(*) AS question_count').
        where("id > ?", id_time_since).
        where(author_is_anonymous: false).
        group(:user_id).
        order('question_count').
        reverse_order.limit(top_x)

    # .user = the user
    # .answer_count = how many questions did the user answer
    @users_with_most_answers = Answer.select('user_id, COUNT(*) AS answer_count').
        where("id > ?", id_time_since).
        group(:user_id).
        order('answer_count').
        reverse_order.limit(top_x)
  end
end

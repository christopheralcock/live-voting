require 'rails_helper'

describe 'Questions Features' do
  let(:event){ create :event, user: create(:user) }
  let(:user_two){create :user_two}

  before :each do
    sign_in_as(event.user)
  end

  it 'can be created on an event' do
    visit event_path(event)
    click_on 'Add Question'
    fill_in 'question_content', with: 'test question'
    fill_in "question[choices_attributes][0][content]", with: "choice 1"
    fill_in "question[choices_attributes][1][content]", with: "choice 2"
    click_on "Save"
    expect(page).to have_content 'Question successfully created'
    expect(page).to have_content 'test question'
  end

  it 'allows extra choices to be added', js: :true do
    visit event_path(event)
    click_on 'Add Question'
    fill_in 'question_content', with: 'test question'
    fill_in "question[choices_attributes][0][content]", with: "choice 1"
    fill_in "question[choices_attributes][1][content]", with: "choice 2"
    click_on "Add Another Answer Box"
    fill_in "question[choices_attributes][2][content]", with: "choice 3"
    click_on "Save"
    expect(page).to have_content 'Question successfully created'
    expect(page).to have_content 'test question'
    expect(page).to have_content 'choice 1'
    expect(page).to have_content 'choice 2'
    expect(page).to have_content 'choice 3'
  end

  it 'adds choices which do not have duplicate text', js: :true do
    visit event_path(event)
    click_on 'Add Question'
    fill_in 'question_content', with: 'test question'
    fill_in "question[choices_attributes][0][content]", with: "Some unique text"
    click_on "Add Another Answer Box"
    fill_in "question[choices_attributes][0][content]", with: "Sometext"
    expect(page).not_to have_content("Some unique text")
  end

  it "can't be created with a blank content field" do
    visit event_path(event)
    click_on 'Add Question'
    fill_in "question[choices_attributes][0][content]", with: "choice 1"
    fill_in "question[choices_attributes][1][content]", with: "choice 2"
    click_on 'Save'
    expect(page).to have_content "1 error prohibited this question from being saved:"
  end

  it 'disallows non owners to make event questions' do
    click_on "Sign out"
    sign_in_as(user_two)
    visit new_event_question_path(event)
    expect(current_path).to eq root_path
    expect(page).to have_content('Sorry, but we were unable to serve your request.')
  end

  it 'allows extra choices to be deleted', js: :true do
    visit event_path(event)
    click_on 'Add Question'
    fill_in 'question_content', with: 'test question'
    fill_in "question[choices_attributes][0][content]", with: "choice 1"
    fill_in "question[choices_attributes][1][content]", with: "choice 2"
    click_on "Add Another Answer Box"
    fill_in "question[choices_attributes][2][content]", with: "choice 3"
    click_on "Delete Last Answer"
    click_on "Save"
    expect(page).to have_content 'Question successfully created'
    expect(page).to have_content 'test question'
    expect(page).to have_content 'choice 1'
    expect(page).to have_content 'choice 2'
    expect(page).not_to have_content 'choice 3'
  end

  it 'can be deleted' do
    question = create :question, event: event
    visit event_path event
    expect(page).to have_content "#{question.content}"
    click_on 'Delete Question'
    expect(page).not_to have_content "#{question.content}"
    expect(page).to have_content "Question successfully deleted"
  end

  context 'after a question has been created' do
    before(:each){ @question = create :question, event: event }

    it "the question show page has a link back to its event" do
      visit question_path(@question)
      expect(page).to have_selector(:link_or_button, "Back")
    end

    it 'cannot be accessed except by event author' do
      click_on "Sign out"
      sign_in_as(user_two)
      visit question_path(@question)
      expect(current_path).to eq root_path
      expect(page).to have_content "Sorry, but we were unable to serve your request."
    end


    it 'it can be pushed to the audience from the question show view' do
      expect_any_instance_of(Pusher::Client).to receive(:trigger)
      visit question_path(@question)
      expect(page).to have_selector(:link_or_button, "Push Question to Audience")
      click_on "Push Question to Audience"
      expect(page).to have_content "Question has been pushed to the audience"
    end

    it "event show page has a button to 'Push Question to Audience'" do
      visit event_path(event)
      expect(page).to have_selector(:link_or_button, 'Push Question to Audience')
    end

    it "user can publish the question" do
      expect_any_instance_of(Pusher::Client).to receive(:trigger)
      visit event_path(event)
      click_on 'Push Question to Audience'
      expect(current_path).to eq  question_path(@question)
      expect(page).to have_content 'Question has been pushed to the audience'
    end

    it "alerts user to issue publishing question" do
      expect_any_instance_of(Pusher::Client).to receive(:trigger).and_raise("ERROR")
      visit event_path(event)
      click_on 'Push Question to Audience'
      expect(current_path).to eq  event_path(event)
      expect(page).to have_content 'Error: Question could not be published'
    end

    context "when a question's choices do not have any votes" do
      before :each do
        @choice1 = create :choice, question: @question
        @choice2 = create :choice, question: @question
        visit question_path @question
      end

      it "questions starts with zero votes" do
        expect(page).to have_content "Votes: 0"
      end
    end

    context "when a question's choices has some votes" do
      before :each do
        @choice1 = create :choice, question: @question
        @choice2 = create :choice, question: @question
        @choice1.votes.create
        @choice2.votes.create
      end

      it '(with a page refresh) votes and chart are shown on the question show page' do
        visit question_path @question
        expect(page).to have_content "#{@choice1.content}"
        expect(page).to have_content "#{@choice2.content}"
        expect(page).to have_content "Votes: #{@choice1.votes.count}"
        expect(page).to have_content "Votes: #{@choice2.votes.count}"
        expect(page).to have_css(".progress", count: 2)
        expect(page).to have_css("#choice_#{@choice1.id}[data-votecount='1']")
        expect(page).to have_css("#choice_#{@choice2.id}[data-votecount='1']")
        expect(page).to have_css("#choice_#{@choice1.id} .progress .progress-bar")
        expect(page).to have_css("#choice_#{@choice2.id} .progress .progress-bar")
      end

      it "a question's votes can be cleared with the press of a button on its show page" do
        visit question_path @question
        click_on "Clear Votes"
        expect(page).not_to have_content "Votes: 1"
        expect(page).to have_content "Votes successfully cleared"
      end

      it 'builds vote graph from live voters votes', js: :true do
        visit question_path @question
        expect(page).to have_content "#{@choice1.content}"
        expect(page).to have_css("#choice_#{@choice1.id}[data-votecount='1']")
        @choice1.votes.create
        page.execute_script("$(document).ready(function() { choiceVotebuilder(#{vote_creator(@choice1.id, "2")}) });")
        expect(page).to have_css("#choice_#{@choice1.id}[data-votecount='2']")
        page.execute_script("$(document).ready(function() { choiceVotebuilder(#{vote_creator(@choice1.id, "3")}) });")
        expect(page).to have_css("#choice_#{@choice1.id}[data-votecount='3']")
      end
    end
  end
end

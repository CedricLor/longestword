require 'open-uri'
require 'json'

class GamesController < ApplicationController
  def display_grid
    @grid = generate_grid(9)
    @start_time = Time.now
  end

  def get_user_attempt
  end

  # score method
  def display_user_results
    @user_attempt = params.fetch(:user_attempt)
    @grid = params.fetch(:grid)
    @start_time = Time.parse(params.fetch(:start_time))
    @end_time = Time.now
    @result_hash = run_game(@user_attempt, @grid, @start_time, @end_time)
  end

  private

  def generate_grid(grid_size)
    # generate random grid of letters
    # Initialize an array of size = grid_size parameter
    # Sample letters from a recursive array of A to Z
    Array.new(grid_size) { [*"A".."Z"].sample }
  end

  def slicer(char, grid_string_clean, attempt_clean)
    # slices off grid and attempt of matching characters
    grid_string_clean.slice!(char)
    attempt_clean.slice!(char)
    # return reduced grid and attempt strings
    return grid_string_clean, attempt_clean
  end

  def wg_cond_test(char, grid_string_clean, controller, attempt_clean)
    # tries to match the character in the grid using a regex
    if /#{char}/ =~ grid_string_clean
      # if character matched, switch controller to true
      controller = true
      # slice the matched character off the grid and the attempt and return reduced grid and attempt strings
      grid_string_clean, attempt_clean = slicer(char, grid_string_clean, attempt_clean)
    else
      controller = false
    end
    return grid_string_clean, controller, attempt_clean
  end

  def is_word_in_grid?(attempt, grid_string_clean)
    # stop the checker if the input is empty and return false
    return false if attempt == ""
    # process inputs for simpler comparison (upcase the attempt, transform the grid from an enum into a string)
    attempt_clean = attempt.upcase
    # set a boolean controller to true
    controller = true
    # loop on each character of the attempt and check whether it is in the grid
    attempt_clean.each_char do |char|
      # look for the character in the grid and switches the controller to true or false
      grid_string_clean, controller, attempt_clean = wg_cond_test(char, grid_string_clean, controller, attempt_clean)
    end
    # The function may not be true if attempt clean is not an empty string
    # at this stage of the function (because this would mean that some characters
    # would not have been matched against the grid)
    controller = false unless attempt_clean == ""
    return controller
  end

  def if_not_translated_build_result_hash(result_hash, start_time, end_time)
    result_hash[:message] = "The word is not an english word!"
    result_hash[:time] = end_time - start_time
    result_hash[:score] = 0
    result_hash
  end

  def if_translated_build_result_hash(attempt, result_hash, words, start_time, end_time)
    result_hash[:translation] = words['term0']['PrincipalTranslations']['0']['FirstTranslation']['term']
    result_hash[:time] = end_time - start_time
    result_hash[:score] = ((attempt.size / result_hash[:time]) * 100).round
    result_hash[:message] = "Well done!"
    result_hash
  end

  def if_in_grid_build_result_hash(attempt, result_hash, start_time, end_time)
    # if in the grid, connect to the Wordreference API
    # Initialize url variable
    url = "http://api.wordreference.com/0.8/80143/json/enfr/#{attempt}"
    # get the data from the URL
    words = JSON.parse(open(url).read)
    # check the word against the result of the Wordreference API
    if words["Error"] == "NoTranslation"
      # if word not found in the Wordreference API, return error message to the user
      if_not_translated_build_result_hash(result_hash, start_time, end_time)
    else
      # else calculate score based on time and use of letters
      if_translated_build_result_hash(attempt, result_hash, words, start_time, end_time)
    end
    result_hash
  end

  def run_game(attempt, grid, start_time, end_time)
  # runs the game and return detailed hash of result
  # initialize a result hash with default values
  result_hash = {}
  result_hash[:time] = end_time - start_time
  # Check if the user input is using the letters provided in the grid
    if !is_word_in_grid?(attempt, grid)
      result_hash[:message] = "The word is not in the grid."
      result_hash[:score] = 0
    else
      if_in_grid_build_result_hash(attempt, result_hash, start_time, end_time)
    end
    result_hash
  end

end

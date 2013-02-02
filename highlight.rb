require 'rest-client'
require 'json'
require File.dirname(__FILE__) + "/app"

class Highlight
  attr_accessor :book, :author, :clip, :date

  def self.test
    self.parse_file(File.open("Meine Clippings.txt").read)
  end

  def self.parse(clippings_txt)
    all_clippings = clippings_txt.split("==========")
    all_clippings.each{|c| self.parse_clip(c)}
  end

  def self.parse_clip(single_clip)
    lines = single_clip.split("\r\n").reject(&:empty?)

    hl = Highlight.new
    hl.book = lines[0].match(/([\w,\s]*)\ \((.*)\)/)[1]
    hl.author = lines[0].match(/([\w,\s]*)\ \((.*)\)/)[2]
    hl.date = lines[1]
    hl.clip = lines[2]
    hl.save
  end

  def save
    books = JSON.parse(RestClient.get("https://api.readmill.com/v2/books/search", self.search_params).to_s)
    reading = JSON.parse(RestClient.get("https://api.readmill.com/v2/users/mklappstuhl/readings/match", self.match_params).to_s)
    require 'pry'
    binding.pry
    # retrieve book
    # check if user reads book
    # add highlight for user/book
  end

  def search_params
    {params: {query: "#{self.book} #{self.author}"}.merge(Ktr.readmill_client_id)}
  end

  def match_params
    {params: {author: self.author, title: self.book}.merge(Ktr.readmill_client_id)}
  end
end

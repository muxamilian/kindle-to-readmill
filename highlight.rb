require 'rest-client'
require 'json'
require File.dirname(__FILE__) + "/app"

class Highlight
  WHITESPACE_CHARS = ' \f\n\r\t\u00a0\u0020\u1680\u180e\u2028\u2029\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u202f\u205f\u3000'

  attr_accessor :book, :author, :clip, :meta, :uid, :token

  def self.test
    self.parse(File.open("Meine Clippings.txt").read)
  end

  def self.parse(session)
    results = {sucess: 0, failure: 0}
    all_clippings = Ktr.get_text(session).split("==========")
    uid = Ktr.get_uid(session)
    token = Ktr.get_token(session)
    all_clippings.each{|clip|
      self.parse_clip(clip, uid, token) ? results[:success] += 1 : results[:failure] += 1
    }
    return results
  end

  def self.parse_clip(single_clip, uid, token)
    lines = single_clip.split("\r\n").reject(&:empty?)

    if lines[2].nil? || lines[2].empty? || (lines[2].length > 1000)
      return false
    else
      hl = Highlight.new
      hl.book = lines[0].match(/([\w,\s]*)\ \((.*)\)/)[1]
      hl.author = lines[0].match(/([\w,\s]*)\ \((.*)\)/)[2]
      hl.meta = lines[1]
      hl.clip = normalize_text(lines[2])
      hl.uid = uid
      hl.token = token
      hl.save ? true : false
    end
  end

  def save
    begin
      reading = JSON.parse(RestClient.get("https://api.readmill.com/v2/users/#{uid}/readings/match", self.match_params).to_s)

      unless reading["reading"]["state"] == 'interesting'
        JSON.parse(RestClient.post("https://api.readmill.com/v2/readings/#{reading["reading"]["id"]}/highlights", self.create_highlight_params).to_s)
      end
      return true
    rescue
      return false
    end

  end

  def search_params
    {params: {query: "#{self.book} #{self.author}", client_id: Ktr.readmill_client_id}}
  end

  def match_params
    {params: {author: self.author, title: self.book, client_id: Ktr.readmill_client_id}}
  end

  def create_highlight_params
      {highlight:
        {content: clip,
          locators: {
            mid: clip
          }
        },
      access_token: token,
      client_id: Ktr.readmill_client_id}
  end

  def self.normalize_text(text)

    text.gsub /[#{WHITESPACE_CHARS}]+/, ' '
  end
end

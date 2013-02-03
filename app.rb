require 'sinatra'
require 'json'
require 'rest-client'
require 'redis'
require File.dirname(__FILE__) + "/highlight"

class Ktr < Sinatra::Base
  set :sessions, true

  def redirect_uri host
    "http://#{host}:#{request.port}/callback/readmill"
  end

  get '/' do
    haml :index
  end

  post '/text' do
    Ktr.save_text session, params[:text]
  end

  get '/auth/readmill' do
    redirect "http://readmill.com/oauth/authorize?response_type=code&client_id=#{Ktr.readmill_client_id}&redirect_uri=#{redirect_uri request.host}&scope=non-expiring"
  end

  get '/kthxbai' do
    haml :success
  end

  get '/callback/readmill' do
    token_params = {
      :grant_type => 'authorization_code',
      :redirect_uri => redirect_uri(request.host),
      :code => params[:code],
      :scope => 'non-expiring',
      :client_id => Ktr.readmill_client_id,
      :client_secret => Ktr.readmill_client_secret
    }

    token = Ktr.get_token session
    if token.nil? || token.empty?
      token = JSON.parse(RestClient.post("http://readmill.com/oauth/token.json", token_params).to_str)['access_token']
    end
    session[:token] = token
    Ktr.save_token session, token

    me_res = JSON.parse(RestClient.get("https://api.readmill.com/v2/me", me_params).to_str)
    Ktr.save_uid session, me_res["user"]["id"]
    stats = Highlight.parse(session)
    redirect "/kthxbai?success=#{stats[:success]}&failure=#{stats[:failure]}"
  end

  def me_params
    {params: {access_token: session[:token], client_id: Ktr.readmill_client_id}}
  end

  def self.readmill_client_id
    "a42e275a33084de0eafae2c9a9036f9b"
  end

  def self.readmill_client_secret
    "5c0284332666555c5419d00d9e27c4e3"
  end


  def self.save_uid(session, uid)
    Ktr.redis.set "#{session[:session_id]}-uid", uid
  end

  def self.get_uid(session)
    Ktr.redis.get "#{session[:session_id]}-uid"
  end

  def self.save_text(session, text)
    Ktr.redis.set "#{session[:session_id]}-clipping", text
  end

  def self.get_text(session)
    Ktr.redis.get "#{session[:session_id]}-clipping"
  end

  def self.save_token(session, token)
    Ktr.redis.set "#{session[:session_id]}-token", token
  end

  def self.get_token(session)
    Ktr.redis.get "#{session[:session_id]}-token"
  end

  # REDIS CONNECTOR
  # mostly stolen from resque haha
  def self.redis
    return @redis if @redis
    if ENV["REDIS_URI"]
      self.redis = ENV["REDIS_URI"]
    else
      self.redis = "localhost:6379"
    end
    self.redis
  end

  # Accepts:
  #   1. A 'hostname:port' String
  #   2. A 'hostname:port:db' String (to select the Redis db)
  #   3. A 'hostname:port/namespace' String (to set the Redis namespace)
  #   4. A Redis URL String 'redis://host:port'
  #   5. An instance of `Redis`, `Redis::Client`, `Redis::DistRedis`,
  #      or `Redis::Namespace`.
  def self.redis=(server)
    case server
    when String
      if server['redis://']
        redis = Redis.connect(:url => server, :thread_safe => true)
      else
    #     server, namespace = server.split('/', 2)
    #     host, port, db = server.split(':')
    #     redis = Redis.new(:host => host, :port => port,
    #       :thread_safe => true, :db => db)
    #   end

    #   require 'pry'
    #   binding.pry
      server, namespace = server.split('/', 2)
      host, port, db = server.split(':')
      @redis = Redis.new(:host => host, :port => port,
                         :thread_safe => true, :db => db)
    else
      # else
      @redis = server
    end
        server, namespace = server.split('/', 2)
        host, port, db = server.split(':')
    # end
  end
end

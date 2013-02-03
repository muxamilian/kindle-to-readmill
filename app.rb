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

    auth_res = JSON.parse(RestClient.post("http://readmill.com/oauth/token.json", token_params).to_str)
    session[:token] = auth_res['access_token']
    Ktr.save_token session, auth_res['access_token']

    me_res = JSON.parse(RestClient.get("https://api.readmill.com/v2/me", me_params).to_str)
    Ktr.save_uid session, me_res["user"]["id"]
    Highlight.parse(session)
    redirect '/success'
  end

  def me_params
    {params: {access_token: session[:token], client_id: Ktr.readmill_client_id}}
  end

  def self.readmill_client_id
    "18230e3569ee936122b22a8563c61ee8"
  end

  def self.readmill_client_secret
    "d9f22a5e3767ffccdfa3f3108281dd7a"
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
    self.redis = "localhost:6379"
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
    #   if server['redis://']
    #     redis = Redis.connect(:url => server, :thread_safe => true)
    #   else
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

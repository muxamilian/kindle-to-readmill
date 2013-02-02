require 'sinatra'
require 'json'
require 'rest-client'

$client_id = "18230e3569ee936122b22a8563c61ee8"
$client_secret = "d9f22a5e3767ffccdfa3f3108281dd7a"

class Ktr < Sinatra::Base
  enable :sessions

  def redirect_uri host
    "http://#{host}:#{request.port}/callback/readmill"
  end

  get '/' do
    haml :index
  end

  post '/text' do
    session[:text] = params[:text]
  end

  get '/auth/readmill' do
    redirect "http://readmill.com/oauth/authorize?response_type=code&client_id=#{$client_id}&redirect_uri=#{redirect_uri request.host}&scope=non-expiring"
  end

  get '/success' do
    haml :success
  end

  get '/callback/readmill' do
    token_params = {
      :grant_type => 'authorization_code',
      :client_id => $client_id,
      :client_secret => $client_secret,
      :redirect_uri => redirect_uri(request.host),
      :code => params[:code],
      :scope => 'non-expiring'
    }
    resp = JSON.parse(RestClient.post("http://readmill.com/oauth/token.json", token_params).to_str)# rescue nil

    @access_token = resp['access_token']
    puts "\n\n\n\n\n" + $access_token.inspect + "\n\n\n\n\n"
    redirect '/success'
  end
end

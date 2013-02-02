require 'sinatra'
require 'sinatra/assetpack'
require 'json'
require 'rest-client'

$client_id = "18230e3569ee936122b22a8563c61ee8"
$client_secret = "d9f22a5e3767ffccdfa3f3108281dd7a"
$access_token = nil

class Ktr < Sinatra::Base
  register Sinatra::AssetPack
  assets {
    # The second parameter defines where the compressed version will be served.
    # (Note: that parameter is optional, AssetPack will figure it out.)
    js :app, '/js/app.js', [
      '/js/vendor/**/*.js',
      '/js/app/**/*.js'
    ]

    css :application, '/css/application.scss', [ 'css/application.css' ]

    js_compression  :jsmin      # Optional
    css_compression :sass       # Optional
  }

  def redirect_uri host
    "http://#{host}:#{request.port}/callback/readmill"
  end

  get '/' do
    haml :index
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
    # data = {
    #   :user => fetch_and_parse("http://api.readmill.com/me.json", resp['access_token'])
    # }
    # user = User.first_or_create({ :readmill_id => data[:user]['id'] })
    # user.name = data[:user]['username']
    # user.access_token = resp['access_token']
    # user.save!
    $access_token = resp['access_token']
    puts "\n\n\n\n\n" + $access_token.inspect + "\n\n\n\n\n"
    redirect '/success'
  end
end

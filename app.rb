require 'sinatra'
require 'sinatra/assetpack'

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


  get '/' do
    haml :index
  end

  get '/auth/readmill' do
    redirect "http://readmill.com/oauth/authorize?response_type=code&client_id=#{settings.readmill_client_id}&redirect_uri=#{settings.readmill_redirect}&scope=non-expiring"
  end

  get '/callback/readmill' do
    token_params = {
      :grant_type => 'authorization_code',
      :client_id => settings.readmill_client_id,
      :client_secret => settings.readmill_client_secret,
      :redirect_uri => settings.readmill_redirect,
      :code => params[:code],
      :scope => 'non-expiring'
    }
    resp = JSON.parse(RestClient.post("http://readmill.com/oauth/token.json", token_params).to_str) rescue nil
    data = {
      :user => fetch_and_parse("http://api.readmill.com/me.json", resp['access_token'])
    }
    user = User.first_or_create({ :readmill_id => data[:user]['id'] })
    user.name = data[:user]['username']
    user.access_token = resp['access_token']
    @access_token = resp['access_token']
    user.save!
    erb :twitter
  end
end

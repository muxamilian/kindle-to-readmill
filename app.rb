require 'sinatra'

class Ktr < Sinatra::Application
get '/' do
  haml :index
end
end

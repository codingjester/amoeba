require 'sinatra'
require 'redis'
require 'json'
require 'securerandom'

$db = Redis.new

# Generate a new url
post '/gen' do
  url = params[:url]
  
  #It probably will be unique enough for us.
  hash = SecureRandom.urlsafe_base64(8)
  while ($db.exists(hash))
    hash = SecureRandom.urlsafe_base64(8)
  end

  $db.set hash, url

  content_type :json
  { :url => "http://#{request.host}/#{hash}" }

end

get '/:hash' do
  url = $db.get params[:hash]
  if url
    #$db.zincrby "counts", 1, params[:hash] #Keep track of the number of times someone uses the url
    redirect url
  end
  status 404 #Create your own 404
end

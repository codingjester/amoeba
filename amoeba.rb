require 'sinatra'
require 'redis'
require 'json'
require 'securerandom'
require 'uri'

$db = Redis.new

# Generate a new url
post '/gen' do
  url = params[:url]
  
  # We only allow urls
  u = URI.parse(url)
  if (!u.kind_of?(URI::HTTP) && !u.kind_of(URI::HTTPS))
    halt 400
  end
  
  #It probably will be unique enough for us.
  hash = SecureRandom.urlsafe_base64(8)
  while ($db.exists(hash))
    hash = SecureRandom.urlsafe_base64(8)
  end

  $db.set hash, url

  content_type :json
  { :url => "http://#{request.host}/#{hash}" }.to_json

end

get '/stats' do
  offset = params[:offset] ||= 0
  limit = params[:limit] ||= 10
  scores = !!params[:with_scores] #Not quite right. should accept false and not return scores
  
  # used for pagination
  stop = offset.to_i + (limit.to_i - 1)

  keys = $db.zrange "stats", offset, stop, {:with_scores => scores}
  content_type :json
  keys.to_json
end

get '/:hash' do
  hash = params[:hash]
  url = $db.get hash
  if url
    $db.zincrby "stats", 1, hash #Keep track of the number of times someone uses the url
    redirect url
  end
  status 404 #Create your own 404
end

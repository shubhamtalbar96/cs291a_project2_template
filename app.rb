require 'sinatra'
require 'google/cloud/storage'

storage = Google::Cloud::Storage.new(project_id: 'cs291a')
bucket = storage.bucket 'cs291project2', skip_lookup: true

get '/' do
  
end

get '/files/' do
  all_files = bucket.files
  files.all do |file|
    puts file.name
  end
end

get '/files/{DIGEST}' do
  all_files = bucket.files
  
end

post '/files/' do
  require 'pp'
  PP.pp request
  "POST\n"
end

delete '/files/{DIGEST}' do

end

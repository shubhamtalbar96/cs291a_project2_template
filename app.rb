require 'sinatra'

get '/' do
end

get '/files/' do
end 


# create a new file
post '/files/' do

  require 'digest'
  # for getting buckets
  require 'google/cloud/storage'

  # check if file is provided or not
  if !params['file']
    status 422
    headers['Content-Type'] = "application/json"
    return {:message => "File not provided"}.to_json
  end

  # the file is stored in tempfile
  file = params['file']["tempfile"]

  # if the file is not provided
  if !file
    status 422
    headers["Content-Type"] = "application/json"
    return {:message => "File not provided"}.to_json
  end

  # to get the file size
  # read content of the file
  content = file.read

  if content.length > 1048576
    status 422
    headers["Content-Type"] = "application/json"
    return {:message => "File size greather than 1 MB"}.to_json
  end

  # hashing the content of the file in hex
  content_hash = Digest::SHA256.hexdigest content

  # create a new file name as per GCS specs
  file_name = content_hash.insert 2,"/"
  file_name = content_hash.insert 5,"/"

  # getting storage and bucket
  storage = Google::Cloud::Storage.new(project_id: 'cs291a')
  bucket = storage.bucket 'cs291project2', skip_lookup: true

  # check if GCS already has the file
  server_file = bucket.file file_name, skip_lookup: true

  if server_file.exists?
    status 409 
    headers["Content-Type"] = "application/json"
    return {:message => "File already present"}.to_json
  end

  bucket.create_file file, file_name, content_type: params["file"]["type"].to_s
  status 201
  header["Content-Type"] = "application/json"
  return {:uploaded => "#{content_hash.split("/").join}"}.to_json
end


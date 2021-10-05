require 'sinatra'

# redirect to /files/
get '/' do
  status 302
  new_path = request.base_url.to_s + "/files/"
  redirect new_path
  return {:message => "redirected to #{new_path}"}.to_json
end

# get names for all the valid files
get '/files/' do
  # for getting buckets
  require 'google/cloud/storage'

  begin
    # getting storage and bucket
    storage = Google::Cloud::Storage.new(project_id: 'cs291a')
    bucket = storage.bucket 'cs291project2', skip_lookup: true

    # get all files
    all_files = bucket.files

    # get the name of all valid ones
    all_file_names = Array.new
    all_files.all { |file|
      file_name = file.name

      # check validity before pushing
      file_name_split = file_name.split('/')

      if file_name_split.length == 3 && 
            file_name_split[0].length == 2 &&
            file_name_split[1].length == 2 &&
            file_name_split.join.length == 64  

        all_file_names.push file_name_split.join
      end
    }

    status 200
    headers["Content-Type"] = "application/json" 
    return all_file_names.sort.to_s
    
  rescue Google::Cloud::PermissionDeniedError => e
    status 403
    headers["Content-Type"] = "application/json"
    {:message => e.message}.to_json
  end

end 

get '/files/:digest' do
  # for getting buckets
  require 'google/cloud/storage'

  # check if digest provided has hexadecimal characters 
  if params['digest'][/\h/] && params['digest'].length == 64
    # getting storage and bucket
    storage = Google::Cloud::Storage.new(project_id: 'cs291a')
    bucket = storage.bucket 'cs291project2', skip_lookup: true

    # creating a file name as per GCS specs
    file_name = params['digest'].insert(2, '/')
    file_name = file_name.insert(5, '/')
    file_name.downcase!

    # get file if it exists 
    file = bucket.file file_name, skip_lookup: true

    if !file.exists?
      status 404
      headers["Content-Type"] = "application/json"
      {:message => "Invalid file name passed"}.to_json
    end

    if file
      begin
        status 200
        headers["Content-Type"] = file.content_type.to_s
        downloaded = file.download
        downloaded.rewind
        downloaded.read
        content = downloaded.read
        {:message => "successfully retrieved hex digest #{file_name.downcase!}"}.to_json
      rescue Google::Cloud::NotFoundError => e
        status 404
        headers["Content-Type"] = "application/json"
        {:message => "File not found"}.to_json
      end
    end
  else
    status 422
    headers["Content-Type"] = "application/json"
    {:message => "Invalid hex digest #{params['digest']} passed"}.to_json
  end

end

delete '/files/:digest' do
  # for getting buckets
  require 'google/cloud/storage'

  # check if digest provided has hexadecimal characters 
  if params['digest'][/\h/] && params['digest'].length == 64
    # getting storage and bucket
    storage = Google::Cloud::Storage.new(project_id: 'cs291a')
    bucket = storage.bucket 'cs291project2', skip_lookup: true

    # creating a file name as per GCS specs
    file_name = params['digest'].insert(2, '/')
    file_name = file_name.insert(5, '/')
    file_name.downcase!

    # get file if it exists 
    file = bucket.file file_name, skip_lookup: true

    if file
      begin
        status 200
        headers["Content-Type"] = "application/json"
        file.delete
        {:message => "Delted hex digest #{params['digest']}"}.to_json
      rescue Google::Cloud::NotFoundError => e
        status 200
        headers["Content-Type"] = "application/json"
        {:message => "File could not be deleted"}.to_json
      end
    else
      status 404
      headers["Content-Type"] = "application/json"
      {:message => "File not found"}.to_json
    end
  end
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
  headers["Content-Type"] = "application/json"
  return {:uploaded => "#{content_hash.split("/").join}"}.to_json
end


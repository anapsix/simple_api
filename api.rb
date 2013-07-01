require "rubygems"
require "sinatra/base"

class MyAPI < Sinatra::Base

  configure :production, :development do
    enable :logging
  end

  get '/' do 
    redirect do('/hello')
  end

  get '/hello' do
    params = request.env['rack.request.query_hash']
    msg = ""
    msg << "Hello, this is running on pure unicorn!<br>"
    msg << "this is an output of directory listing<br>#{%x[ls -la]}<br>"
    msg << "request params: #{params["user"]}"
    msg << "<br><br>"
    msg << "request params: #{params}"
    msg
  end

  get '/ls' do
    msg == ""
    list = %x[ls #{$bigbro_home}/output].split("\n")
    msg << list.to_s
    msg
  end

end

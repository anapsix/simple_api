require "rubygems"
require "sinatra/base"
require "json"

class MyAPI < Sinatra::Base

  configure :production, :development do
    enable :logging
    set :public_folder, File.dirname(__FILE__) + '/static'
  end

  get '/' do 
    redirect '/welcome?arg1=value1&arg2=value2&arg3'
  end

  get '/welcome' do
    params = request.env['rack.request.query_hash']
    msg = ""
    msg << "<p><left><img src='/sinatra_unicorn.png'><left>"
    msg << "<p><b>Welcome, this is an example API server running by the power of Ruby using <a href='http://www.sinatrarb.com'>Sinatra</a> / "
    msg << "<a href='https://github.com/blog/517-unicorn'>Unicorn</a>!</b>"
    msg << "<br><br><p>System load (output of 'uptime') is..<br>#{%x[uptime]}<br>"
    $o = Array.new
    output = %x[ls -l / | tail -n3].gsub(/total.*\n/,"")
    output.each_line { |l|
      l.strip!
      a=l.split("\s")
      h = Hash.new
      h["perms"] = a[0]
      h["type"]  = a[1]
      h["owner"] = a[2]
      h["group"] = a[3]
      h["size"]  = a[4]
      h["name"]  = a.last
      $o.push h
    }
    msg << "<p>Last 3 lines of output of directory listing for / in JSON<pre>#{JSON.pretty_generate($o)}</pre>"
    msg << "<br>"
    msg << "<p>Request params array: <pre>#{JSON.pretty_generate(params)}</pre>"
    msg << "<p>Sinatra Documentation can be found here: <a href='http://www.sinatrarb.com/faq.html'>http://www.sinatrarb.com/faq.html</a>"
    msg
  end

end

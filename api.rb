begin
  require "googlecharts"
rescue LoadError
  puts 'googlecharts gem is not installed, moving on..'
end

class MyAPI < Sinatra::Base
  helpers Sinatra::JSON
  use Rack::Cache

  configure :production, :development do
    enable :logging
    set :public_folder, File.dirname(__FILE__) + '/static'
    set :json_encoder, :to_json
  end

  before do
    cache_control :public, :must_revalidate, :max_age => 3600
    # connect to DB
    # recalulate splines 
  end

  after do
    # disconnect from DB
    # do other stuff
  end

  # pre-defined messages
  nu   = {"code" => "400", "message" => "not understood"}
  nf   = {"code" => "404", "message" => "not found"}
  ni   = {"code" => "405", "message" => "not implemented"}
  boom = {"code" => "500", "message" => "boom!"}

  # custom error handling
  error 400 do
    json nu
  end

  error 404 do
    json nf
  end

  error 405 do
    json ni
  end

  error 500..599 do
    json boom
  end

  get '/' do 
    redirect '/welcome?arg1=value1&arg2=value2&arg3'
  end

  get '/favicon.ico' do
    halt 404
  end

  get '/tryme' do
    halt 405
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
    chart = Gchart.bar( :data => [[1,2,4,67,100,41,234],[45,23,67,12,67,300, 250]],
            :title => 'Ruby Fu level',
            :legend => ['matt','patrick'],
            :bg => {:color => 'CCCCCC', :type => 'gradient'},
            :bar_colors => 'cc0000,00cc00') if defined?(Gchart)
    msg << "<p>Google Chart example using \"googlechart\" gem:<br><img src=#{chart}>" if defined?(Gchart)
    msg << "<p>Sinatra Documentation can be found here: <a href='http://www.sinatrarb.com/faq.html'>http://www.sinatrarb.com/faq.html</a>"
    msg
  end

end

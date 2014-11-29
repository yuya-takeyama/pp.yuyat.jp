require 'sinatra'
require 'sinatra/multi_route'
require 'sinatra/streaming'
require 'slim'
require 'tempfile'
require 'yajl'

enable :inline_templates

get '/' do
  redirect '/json'
end

route :get, :post, '/json' do
  locals = {json: request_json}
  locals[:out], locals[:err] = prettify_json(request_json) if request_json

  status 400 if locals[:err]

  slim :json, locals: locals
end

route :get, :post, '/json.json' do
  if request_json
    out, err = prettify_json(request_json)

    status 400 if err

    stream do |res|
      out.each do |buf|
        res.write buf
      end
      res.write err.message.force_encoding("UTF-8") if err
    end
  end
end

def request_json
  if request.post?
    request.body
  else
    params['json']
  end
end

def prettify_json(json)
  out = Tempfile.open(['out_', '.json'])
  err    = nil

  begin
    Yajl::Parser.new.parse(json) do |d|
      out.puts Yajl::Encoder.encode(d, pretty: true)
    end
  rescue => e
    err = e
  end

  out.rewind

  [out, err]
end

__END__

@@ layout
doctype html
html
  head
    title pp
    css:
      textarea {
        font-family: Osaka-mono, "Osaka-等幅", "ＭＳ ゴシック", monospace;
        font-size: 14px;
      }
  body
    h1 pp
    #content
      == yield

@@ json
h2 JSON
form action="/json"
  textarea name="json" cols="80" rows="20"
    = json
  input type="submit" value="pp"

  - if defined? out
    h2 Prettified
    textarea cols="80" rows="20"
      - out.each do |buf|
        = buf
  - if defined? err and err
    h2 Error!
    textarea cols="80" rows="20"
      = err.message.force_encoding("UTF-8")

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
  begin
    locals = {json: request_json}
    locals[:prettified_jsons] = prettify_json(request_json) if request_json

    slim :json, locals: locals
  rescue => e
    status 400
    locals[:e] = e

    slim :json_error, locals: locals
  end
end

route :get, :post, '/json.json' do
  if request_json
    tempfile = Tempfile.open(['tmp', '.json'])

    error_occured = false

    begin
      prettify_json(request_json).each do |json|
        tempfile.puts json
      end
    rescue => e
      tempfile.puts e.message
      error_occured = true
    end

    status 400 if error_occured

    tempfile.rewind
    response.write tempfile.read
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
  Enumerator.new do |yielder|
    Yajl::Parser.new.parse(json) do |d|
      yielder.yield Yajl::Encoder.encode(d, pretty: true)
    end
  end
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

  - if defined? prettified_jsons
    h2 Prettified
    textarea cols="80" rows="20"
      - prettified_jsons.each do |json|
        = json + "\n"

@@ json_error
h2 JSON
form action="/json"
  textarea name="json" cols="80" rows="20"
    = json
  input type="submit" value="pp"

  h2 Error!
  textarea cols="80" rows="20"
    = e.message

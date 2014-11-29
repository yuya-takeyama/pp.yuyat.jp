require 'sinatra'
require 'sinatra/multi_route'
require 'sinatra/streaming'
require 'slim'
require 'yajl'

enable :inline_templates

get '/' do
  redirect '/json'
end

route :get, :post, '/json' do
  locals = {json: request_json}
  locals[:prettified_jsons] = prettify_json(request_json) if request_json

  slim :json, locals: locals
end

route :get, :post, '/json.json' do
  if request_json
    stream do |out|
      prettify_json(request_json).each do |json|
        out.puts json
        out.flush
      end
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

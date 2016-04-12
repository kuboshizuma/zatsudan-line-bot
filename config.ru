require 'bundler/setup'
require 'sinatra'
require 'json'
require 'rest-client'
require 'docomoru'

class App < Sinatra::Base
  get '/' do
    'test'
  end

  post '/linebot/callback' do
    params = JSON.parse(request.body.read)

    params['result'].each do |msg|
      client = Docomoru::Client.new(api_key: ENV["DOCOMO_API_KEY"])
      response = client.create_dialogue(msg['content']['text'])
      msg['content']['text'] = response.body['utt']

      request_content = {
        to: [msg['content']['from']],
        toChannel: 1383378250, # Fixed  value
        eventType: "138311608800106203", # Fixed value
        content: msg['content']
      }

      endpoint_uri = 'https://trialbot-api.line.me/v1/events'
      content_json = request_content.to_json

      RestClient.proxy = ENV["FIXIE_URL"]
      RestClient.post(endpoint_uri, content_json, {
          'Content-Type' => 'application/json; charset=UTF-8',
          'X-Line-ChannelID' => ENV["LINE_CHANNEL_ID"],
          'X-Line-ChannelSecret' => ENV["LINE_CHANNEL_SECRET"],
          'X-Line-Trusted-User-With-ACL' => ENV["LINE_CHANNEL_MID"]
      })
    end

    "OK"
  end
end

run App

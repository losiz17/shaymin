# test.rb
require 'http'
require 'json'
require 'eventmachine'
require 'faye/websocket'

response = HTTP.post("https://slack.com/api/rtm.start", params: {
    token: ENV['SLACK_API_TOKEN']
  })

rc = JSON.parse(response.body)

url = rc['url']

EM.run do
  # Web Socketインスタンスの立ち上げ
  ws = Faye::WebSocket::Client.new(url)

  #  接続が確立した時の処理
  ws.on :open do
    p [:open]
  end

  ws.on :message do |event|
    data = JSON.parse(event.data)
    p [:message, data]

    if data['text'] == 'hello'
      ws.send({
        type: 'message',
        text: "こんにちは <@#{data['user']}> さん",
        channel: data['channel']
        }.to_json)
    end

    if data['text'] == 'day'
      t = Time.now
      ws.send({
        type: 'message',
        text: "きょうは#{t.year}ねん#{t.month}がつ#{t.day}にち",
        channel: data['channel']
        }.to_json)
    end
  end

  ws.on :close do
    p [:close, event.code]
    ws = nil
    EM.stop
  end

end
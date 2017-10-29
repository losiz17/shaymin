# test.rb
require 'http'
require 'json'
require 'eventmachine'
require 'faye/websocket'
require 'uri'
require 'openssl'
require 'net/http'

puts "APIKEY =>"
APIKEY = gets.chomp
uri = URI.parse("https://api.apigw.smt.docomo.ne.jp/dialogue/v1/dialogue?APIKEY=#{APIKEY}")
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true
body = {}

response = HTTP.post("https://slack.com/api/rtm.start", params: {
    token: ENV['SLACK_API_TOKEN']
  })

rc = JSON.parse(response.body)
count = 0
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


=begin
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
=end
    body['utt'] = data['text']
    if body['utt'] != nil
      request = Net::HTTP::Post.new(uri.request_uri, {'Content-Type' =>'application/json'})
      request.body = body.to_json
      res = nil
      http.start do |h|
        resp = h.request(request)
        res = JSON.parse(resp.body)
      end
      # body['utt'] = data['text']
      body['context'] = res['context']
      text = "#{res['utt']}"
      count += 1
      puts text 
      puts count

      ws.send({
          type: 'message',
          text: text,
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
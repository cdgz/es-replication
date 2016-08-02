require 'fluent/input'
require 'json'
require 'websocket-eventmachine-client'

module Fluent
  class WebsocketInput < Input
    Plugin.register_input('emwebsocket', self)

    config_param :url, :string
    config_param :tag, :string

    def configure(conf)
      super
    end

    def shutdown
      super
    end

    def start
      EM.run do
        ws = WebSocket::EventMachine::Client.connect(:uri => @url)

        ws.onopen do
          log.info "Connected to #{@url}"
        end

        ws.onmessage do |msg, type|
          router.emit(@tag, Engine.now, JSON.parse(msg))
        end

        ws.onclose do |code, reason|
          log.info "Websocket closed"
        end
      end
    end
  end
end

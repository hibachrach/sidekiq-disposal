# frozen_string_literal: true

require "pathname"
require "uri"

module Sidekiq
  module Disposal
    class TestRedisServer
      DIR = Pathname("./tmp/test_redis/")
      PID_FILE = DIR.join("redis.pid")
      URL = ENV.fetch("SIDEKIQ_REDIS_URL", "redis://localhost:6380/")
      PORT = URI(URL).port
      HOST = URI(URL).host

      @server_pid = nil

      class << self
        def kill
          return unless server_pid

          actually_killed_something =
            begin
              ::Process.kill(:KILL, server_pid)
              true
            rescue Errno::ESRCH, Errno::ECHILD
              false
            end

          @server_pid = nil
          DIR.rmtree

          actually_killed_something
        end

        def kill_zombies
          @server_pid ||=
            begin
              Integer(PID_FILE.read)
            rescue Errno::ENOENT, ArgumentError
              # file does not exist or contents are corrupted
              nil
            end

          kill
        end

        def start_if_not_running
          return if server_pid
          DIR.mkpath
          # --dir #{DIR} => Place all generated files in that dir
          # --port #{PORT} => Bind to that port
          # --save '' => Do not attempt to save state to disk on shutdown
          @server_pid = ::Process.spawn("redis-server --dir '#{DIR}' --port #{PORT} --save ''", {[:out, :err] => "/dev/null"})
          attempts = 0
          is_ready = false
          loop do
            is_ready =
              begin
                TCPSocket.new(HOST, PORT)
                true
              rescue Errno::ECONNREFUSED
                false
              end
            break if is_ready
            if attempts > 10
              raise "could not connect to TCP socket #{HOST}:#{PORT} after #{attempts} attempts"
            end
            attempts += 1
            sleep 0.01
          end
          PID_FILE.write(server_pid)
        end

        def url(db: 0)
          "#{URL}#{db}"
        end

        attr_reader :server_pid
      end
    end
  end
end

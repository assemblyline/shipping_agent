RSpec.configure do |c|
  c.before :each, etcd: true do
    EtcdHelper.start
  end
end

require 'etcd'
module EtcdHelper
  extend self

  def start
    if @pid
      cleanup
    else
      download
      server
    end
  end

  private

  def cleanup
    puts 'cleanup etcd'
    Etcd.new.delete('/', recursive: true)
  end

  def server
    puts 'starting etcd server'
    @pid = fork { exec etcd }

    wait_for_server

    at_exit do
      puts 'killing etcd'
      Process.kill('TERM', @pid)
      Process.wait
      `rm -rf default.etcd`
    end
  end

  def wait_for_server
    TCPSocket.new 'localhost', 4001
  rescue Errno::ECONNREFUSED
    retry
  end

  def download
    return if File.exist?(etcd)
    puts "downloading the etcd binary for your system: #{platform}"
    system "curl -L #{download_url} | tar -zxvf- -C #{etcd_dir} #{etcd_bin}"
  end

  def etcd
    etcd_dir + etcd_bin
  end

  def etcd_dir
    'spec/support/.etcd/'
  end

  def etcd_bin
    "etcd-v2.0.4-#{platform}-amd64/etcd"
  end

  def platform
    @_platform ||= `uname`.strip.downcase
  end

  def download_url
    "https://github.com/coreos/etcd/releases/download/v2.0.4/etcd-v2.0.4-#{platform}-amd64.#{extension}"
  end

  def extension
    return 'zip' if platform == 'darwin'
    'tar.gz'
  end
end

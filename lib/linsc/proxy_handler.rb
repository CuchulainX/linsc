require_relative 'proxy'

class ProxyHandler

  def initialize(cooldown_time = 5)
    @cooldown_time = cooldown_time
    proxy_file = Pathname.new(File.dirname __dir__).realdirpath + '../data/proxies.txt'
    agents_file = Pathname.new(File.dirname __dir__).realdirpath + '../data/agents.txt'

    @proxy_list = File.read(proxy_file.to_s).split("\n")
    .collect{|proxy| proxy.split(':')}
    @proxies = []
    @ua_list = File.read(agents_file.to_s).split("\n")

    @proxy_list.each do |proxy_details|
      proxy = Proxy.new(ip: proxy_details[0], port: proxy_details[1],
      username: proxy_details[2], password: proxy_details[3], status: 'good',
      last_used: Time.now - @cooldown_time, user_agent: @ua_list.shift)
      @proxies << proxy
    end
    if @proxies.length == 0
      puts "proxies.txt is empty! if you don't want to use any proxies, use the -n flag. see docs for more."
      exit
    end

  end

  def get_proxy
    @good_proxies = @proxies.select { |proxy| proxy.good? }
    if @good_proxies.length > 0
      @good_proxies.sort!{|a, b| a.last_used <=> b.last_used}
      best_proxy = @good_proxies.first
      duration = Time.now - best_proxy.last_used
      sleep(@cooldown_time - duration) if duration < @cooldown_time
      best_proxy
    else
      puts "All proxies are dead. Wait a few hours before resuming."
      exit
    end
  end

  def length
    @proxies.length
  end
end

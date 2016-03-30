require_relative 'proxy'

class ProxyHandler

  def initialize(cooldown_time = 5)
    @cooldown_time = cooldown_time
    @proxy_list = File.read('./../data/proxies.txt').split("\n")
    .collect{|proxy| proxy.split(':')}
    @proxies = []
    @ua_list = File.read('./../data/agents.txt').split("\n")

    @proxy_list.each do |proxy_details|
      proxy = Proxy.new(ip: proxy_details[0], port: proxy_details[1],
      username: proxy_details[2], password: proxy_details[3], status: 'good',
      last_used: Time.now - @cooldown_time, user_agent: @ua_list.shift)
      @proxies << proxy
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
      false
    end
  end

  def length
    @proxies.length
  end
end

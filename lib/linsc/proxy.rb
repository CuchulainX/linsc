class Proxy
  attr_accessor :ip, :port, :username, :password, :status, :last_used

  def initialize(ip:, port: 80, username: nil, password: nil, status: nil, last_used: nil)
    @ip, @port, @username, @password, @status, @last_used =
                  ip, port, username, password, status, last_used
  end

  def dead
    @status = 'dead'
    @last_used = Time.now
  end

  def good
    @status = 'good'
    @last_used = Time.now
  end

  def good?
    @status == 'good' ? true : false
  end

  def dead?
    @status == 'dead' ? true : false
  end
end

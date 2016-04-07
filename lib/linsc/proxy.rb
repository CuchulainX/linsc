class Proxy
  attr_accessor :ip, :port, :username, :password, :status, :last_used, :user_agent, :burnout_time, :pages_before_burnout

  def initialize(ip:, port: 80, username: nil, password: nil, status: nil, last_used: nil, user_agent: nil, burnout_time: nil, pages_before_burnout: 0)
    @ip, @port, @username, @password, @status, @last_used, @user_agent, @burnout_time, @pages_before_burnout =
                  ip, port, username, password, status, last_used, user_agent, burnout_time, pages_before_burnout
  end

  def dead
    @status = 'dead'
    @last_used = Time.now
    @burnout_time = Time.now
  end

  def good
    @status = 'good'
    @last_used = Time.now
    @pages_before_burnout += 1
  end

  def good?
    @status == 'good' ? true : false
  end

  def dead?
    @status == 'dead' ? true : false
  end

  def used
    @last_used = Time.now
  end
end

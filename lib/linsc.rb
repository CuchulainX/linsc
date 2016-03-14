require "linsc/version"

require 'mechanize'
require 'fileutils'
require 'csv'
require 'i18n'

module Linsc

  #take cmdline args for initialization
  #generate necessary files
  #initialize proxy handler
  #steps: 1) merge lin export csvs into one, ensuring correct encoding
  # =>        and priority ordering recruiters
  # =>    2) cross reference lin data with salesforce report to check which
  # =>        contact are new vs old, and get support data for old
  # =>    3) run data through ddg to get candidate profiles
  # =>    4) visit each candidate profile and validate
  # =>    5) if profile is correct, parse and create new csv row
  # =>        (no need to save profile page locally)

  #likely classes: Linsc - responsible for initializing other classes
  # =>             Proxy - individual proxy
  # =>             ProxyHandler - this is what other classes call when they
  # =>                            need a proxy returned, manage burnout
  # =>             ddgscraper/linscraper?
  # =>             LinRow,SFRow,DDGRow etc, basically as wrappers around
  # =>              the CSV::Row objects used in each case, easier field access



end

def bootstrap
  merger = Merger.new('../input/sample/')
  merger.merge

end

bootstrap
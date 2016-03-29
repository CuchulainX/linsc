#require "linsc/version"

require 'mechanize'
require 'fileutils'
require 'csv'
require 'i18n'
require 'optparse'
require_relative './linsc/merger'
require_relative './linsc/cross_ref'
require_relative './linsc/csv_handlers'
require_relative './linsc/duck'
require_relative './linsc/lin'


module Linsc
  # options = {:name => nil, :age => nil}
  #
  # parser = OptionParser.new do|opts|
  # 	opts.banner = "Usage: years.rb [options]"
  # 	opts.on('-n', '--name name', 'Name') do |name|
  # 		options[:name] = name;
  # 	end
  #
  # 	opts.on('-a', '--age age', 'Age') do |age|
  # 		options[:age] = age;
  # 	end
  #
  # 	opts.on('-h', '--help', 'Displays Help') do
  # 		puts opts
  # 		exit
  # 	end
  # end
  #
  # parser.parse!

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
 #  merge_map = {'First Name' => 'First Name', 'Last Name' => 'Last Name', 'E-mail Address' => 'Email',
 #               'Company' => 'Employer Organization Name 1', 'Job Title' => 'Employer 1 Title',
 #               'Recruiter' => 'LIN 1st Degree'}
 #
 working_dir = '../input/full/'
 #  merger = Merger.new(working_dir, 'merged_utf4.csv', merge_map)
 #  merged = merger.merge
 #  crossref = CrossRef.new(input_dir: working_dir, child_path: "#{working_dir}merged_utf4.csv",
 #  master_path: "#{working_dir}sf_ref2.csv", output_name: 'crossref_generic2')
  # DuckScraper.new(working_dir, 'crossref_generic2', 'ddg_results2').find_profiles
  LinScraper.new(working_dir, 'ddg_results2').start


end

bootstrap

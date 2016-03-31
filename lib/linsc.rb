#require "linsc/version"

require 'mechanize'
require 'i18n'
require 'fileutils'
require 'csv'
require 'optparse'
require 'pathname'
require_relative './linsc/merger'
require_relative './linsc/cross_ref'
require_relative './linsc/csv_handlers'
require_relative './linsc/duck'
require_relative './linsc/lin'


class Linsc
  include CSVHandlers

  def merge
    merge_map = {'First Name' => 'First Name', 'Last Name' => 'Last Name', 'E-mail Address' => 'Email',
                  'Company' => 'Employer Organization Name 1', 'Job Title' => 'Employer 1 Title',
                  'Recruiter' => 'LIN 1st Degree'}
    Merger.new(@working_dir, @merge_path, merge_map).merge
  end

  def crossref
     CrossRef.new(input_dir: @working_dir, child_path: @merge_path,
     master_path: @sf_path, output_path: @crossref_path, options: @options)
  end

  def duck
    DuckScraper.new(@working_dir, @crossref_path, @ddg_path, @options).find_profiles
  end

  def lin
    LinScraper.new(@working_dir, @ddg_path, @options).start
  end

  def map_history_ids
    puts "Mapping ids to history"
    CrossRef.new(input_dir: @working_dir, child_path: "#{@working_dir}contact_employment_insert.csv",
    master_path: "#{@working_dir}history_ref.csv", output_path: "#{@working_dir}contact_employment_insert_with_ids.csv",
    options: {:noproxy => false, :update => true, :insert => false},
    master_lookup_field: 'LIN ID', child_lookup_field: 'LIN ID',
    master_secondary_lookups: nil, static_values: nil)
    CrossRef.new(input_dir: @working_dir, child_path: "#{@working_dir}contact_education_insert.csv",
    master_path: "#{@working_dir}history_ref.csv", output_path: "#{@working_dir}contact_education_insert_with_ids.csv",
    options: {:noproxy => false, :update => true, :insert => false},
    master_lookup_field: 'LIN ID', child_lookup_field: 'LIN ID',
    master_secondary_lookups: nil, static_values: nil)
    exit
  end

  def initialize
    @options = {:noproxy => false, :update => false, :insert => false}
    @working_dir = '../input/sample/'
    @merge_path = "#{@working_dir}merged.csv"
    @sf_path = "#{@working_dir}sf_ref.csv"
    @crossref_path = "#{@working_dir}crossref.csv"
    @ddg_path = "#{@working_dir}ddg.csv"

    parser = OptionParser.new do|opts|
      opts.banner = "Must specify update or insert (or both)"
      opts.on('-u', '--update', 'Tell scraper to fetch fresh data for existing Salesforce records') do
        @options[:update] = true;
      end

      opts.on('-i', '--insert', 'Tell scraper to fetch data for new connections not yet in Salesforce') do
        @options[:insert] = true;
      end

      opts.on('-n', '--noproxy', 'Do not use any proxies') do
        @options[:noproxy] = true;
      end

      opts.on('-e', '--history', 'Map Contact IDs to education/employment histories for new connections') do
        map_history_ids
      end

      opts.on('-h', '--help', 'Displays Help') do
        puts opts
        exit
      end
    end.parse!

    required_sf_fields = ['LIN ID', 'Email', 'Contact ID']
    sf_headers = get_headers("#{@working_dir}sf_ref.csv")
    required_sf_fields.each do |field|
      unless sf_headers.include?(field)
        puts "The SF reference sheet must include the #{field} field."
        exit
      end
    end

    if File.exist?(@ddg_path)
      ids = []
      CSV.foreach(@crossref_path, headers: true) do |row|
        ids << row['Contact ID']
      end
      if ids.include?(nil) || ids.include?("")
        @options[:insert] = true
      else
        @options[:insert] = false
      end
      if ids.any?{|id| id && id&.length > 0}
        @options[:update] = true
      else
        @options[:update] = false
      end
      puts "\nResuming previous scraping. insert: #{@options[:insert]}, update: #{@options[:update]}, using proxies? #{!@options[:noproxy]}"
    else
      unless @options[:update] || @options[:insert]
        puts "Must specify insert or update. See help for details with -h"
        exit
      end
      puts "\nStarting new project. insert: #{@options[:insert]}, update: #{@options[:update]}, using proxies? #{!@options[:noproxy]}"
    end

    merge unless File.exist?(@ddg_path)
    crossref unless File.exist?(@ddg_path)
    duck
    lin



  end

end

Linsc.new

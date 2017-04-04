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
Encoding.default_external = 'utf-8'


class Linsc
  include CSVHandlers

  def merge
    merge_map = {'FirstName' => 'First Name', 'LastName' => 'Last Name', 'EmailAddress' => 'Email',
                  'Company' => 'Employer Organization Name 1', 'Position' => 'Employer 1 Title',
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
    CrossRef.new(input_dir: @working_dir, child_path: @working_dir + "contact_employment_insert.csv",
    master_path: @working_dir + "history_ref.csv", output_path: @working_dir + "contact_employment_insert_with_ids.csv",
    options: {:noproxy => false, :update => true, :insert => false},
    master_lookup_field: 'LIN ID', child_lookup_field: 'LIN ID',
    master_secondary_lookups: nil, static_values: nil)
    CrossRef.new(input_dir: @working_dir, child_path: @working_dir + "contact_education_insert.csv",
    master_path: @working_dir + "history_ref.csv", output_path: @working_dir + "contact_education_insert_with_ids.csv",
    options: {:noproxy => false, :update => true, :insert => false},
    master_lookup_field: 'LIN ID', child_lookup_field: 'LIN ID',
    master_secondary_lookups: nil, static_values: nil)
    exit
  end

  def confirm_restart(first=true)
    if first
      puts "Are you sure you want to restart the project? This will delete all data except the original inputs.\n(y/n)"
    else
      puts "Unknown input. Please enter (y/n)"
    end
    input = gets.chomp
    if input.downcase == 'y'
      return true
    elsif input.downcase == 'n'
      return false
    else
      confirm_restart(false)
    end
  end
  def restart_project
    files = [@merge_path, @crossref_path, @ddg_path, @working_dir + "contact_update.csv",
       @working_dir + "contact_insert.csv", @working_dir + "contact_employment_update.csv",
        @working_dir + "contact_employment_insert.csv", @working_dir + "contact_education_update.csv",
         @working_dir + "contact_education_insert.csv"]
    files.each do |f|
      File.delete(f) if File.exist?(f)
    end
  end

  def initialize
    @options = {:noproxy => false, :update => false, :insert => false}
    @working_dir = Pathname.pwd
    @merge_path = @working_dir + 'merged.csv'
    @sf_path = @working_dir + 'sf_ref.csv'
    @crossref_path = @working_dir + 'crossref.csv'
    @ddg_path = @working_dir + 'ddg.csv'

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

      opts.on('-r', '--restart', 'Restart the project from beginning with the same inputs. WARNING: This will delete all scraped data.') do
        if confirm_restart(true)
          restart_project
          puts "project files deleted"
        else
          puts "exiting"
          exit
        end
      end

      opts.on('-h', '--help', 'Displays Help') do
        puts opts
        exit
      end
    end.parse!

    required_sf_fields = ['LIN ID', 'Email', 'Contact ID']
    sf_headers = get_headers(@sf_path)
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
      if ids.any?{|id| id && id.length > 0}
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

require 'fileutils'
require 'csv'
require 'i18n'
require './linsc/merger'
require './linsc/cross_ref'
require './linsc/csv_handlers'

# lin = contact_import2
# sf = crossref_fresh

class CrossRef
  include CSVHandlers

  def initialize(input_dir, lin, sf)
    @input_dir = input_dir
    @lin_input = lin
    @sf_input = sf
    @output_file = "#{@input_dir}run3_salvaged.csv"
    @headers = get_headers(sf)
    create_file(@output_file)
    cross_ref
  end

  def cross_ref
    sf_data = CSV.read(@sf_input, headers: true, encoding: 'windows-1252')
    sf_data = sf_data.sort do |x, y|
      a = x['Email']
      b = y['Email']
      puts "{#{a} <=> #{b}}"
      puts "{#{a.class} <=> #{b.class}}"
      puts "#{a <=> b}"
      a && b ? a <=> b : a ? -1 : 1
    end
    sf_emails = sf_data.collect {|row| row['Email']&.downcase}
    i = 0

    CSV.foreach(@lin_input, headers: true) do |lin_row|
      i += 1
      puts "lin row: #{i}"
      lin_email = lin_row['Email']&.downcase
      if lin_email&.include?('@')
        sf_match = sf_emails.bsearch_index do |sf_email|
           lin_email && sf_email ? lin_email <=> sf_email : lin_email ? -1 : 1
        end
        if !sf_match
          sf_match = sf_data.find_index do |sf_row|
            sf_row_emails = [sf_row['Email 2']&.downcase, sf_row['Email 3']&.downcase]
            sf_row_emails.include?(lin_email)
          end
        end
        if sf_match
          lin_row['Contact ID'] = sf_data[sf_match]['Contact ID']
          append_to_csv(@output_file, lin_row)
        else
          lin_row['Contact ID'] = ''
          append_to_csv(@output_file, lin_row)
        end
      else
        puts "missing email"
      end
    end
  end

  def collect_emails(file)
    emails = []
    CSV.foreach(file, headers: true) do |row|
      emails << row['E-mail Address']
    end
    emails
  end

  def get_headers(file)
    CSV.open(file, headers: true, return_headers: true).shift.headers
  end

end

working_dir = '/home/dan/Documents/scraping/run3/'

crossref = CrossRef.new(working_dir, "#{working_dir}contact_import2.csv", "#{working_dir}crossref_fresh.csv")

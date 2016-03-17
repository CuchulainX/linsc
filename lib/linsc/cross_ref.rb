require './linsc/csv_handlers'

# refactoring notes:
# this class should provide general functionality, and not rely on specifics of
# what exact field names or data is present in either sheet
# the lookup fields, as well as field mappings for the merged output,
# should be provided by the function using this class
# values that should be provided to this class:
# => master lookup field name
# => child lookup field name
# => optional secondary master lookup fields
# => a mappings hash in the form {master_field: child_field}
# => the master headers will be used, and any child values present in the row and mapping will
# => overwrite the master values, other master valeus will remain intact
# => optional downcase_lookup arg for email lookups
# => arg to specify what the output encoding will be, default utf-8
# => possibly just return the CSV, and let the caller handle writing it
# something similar can be done for the merge class
# do these even qualify as seperate class by this point, or should the be incorporated
# into the CSVHandlers module?

class CrossRef
  include CSVHandlers

  def initialize(input_dir, child_path, master_path)
    @input_dir = input_dir
    @child_path = child_path
    @master_path = master_path
    @output_file = "#{@input_dir}crossref_test3.csv"
    @headers = get_headers(@master_path)
    create_file(@output_file)
    cross_ref
  end

  def cross_ref
    master_data = CSV.read(@master_path, headers: true)
    puts "sorting lookup values"
    master_data = master_data.sort do |x, y|
      # turns out the debugging I/O was by far the most costly part of this sort
      a = x['Email']
      b = y['Email']
      a && b ? a <=> b : a ? -1 : 1
    end
    master_lookup_values = master_data.collect {|row| row['Email']&.downcase}
    i = 0
    CSV.foreach(@child_path, headers: true, encoding: 'windows-1252') do |child_row|
      i += 1
      puts "child row: #{i}"
      child_lookup_value = child_row['E-mail Address']&.downcase
      if child_lookup_value&.include?('@')
        match_index = master_lookup_values.bsearch_index do |master_lookup_value|
           child_lookup_value && master_lookup_value ?
                child_lookup_value <=> master_lookup_value : child_lookup_value ? -1 : 1
        end
        if !match_index
          match_index = master_data.find_index do |master_row|
            master_secondary_lookups = [master_row['Email 2']&.downcase, master_row['Email 3']&.downcase]
            master_secondary_lookups.include?(child_lookup_value)
          end
        end
        if match_index
          append_to_csv(@output_file, splice_rows(master_data[match_index], child_row))
        else
          append_to_csv(@output_file, convert_row(child_row))
        end
      else
        puts "missing email"
      end
    end
  end

  def splice_rows(master_row, child_row)
    master_row['Candidate Source'] = child_row['Recruiter']
    master_row['First Name'] = child_row['First Name'] if child_row['First Name']
    master_row['Last Name'] = child_row['Last Name'] if child_row['Last Name']
    master_row['Employer Organization Name 1'] = child_row['Company'] if child_row['Company']
    master_row['Employer 1 Title'] = child_row['Job Title'] if child_row['Job Title']
    master_row_new = CSV::Row.new(@headers, [])
    master_row.each do |key, value|
      master_row_new[key] = value&.encode('utf-8', invalid: :replace, undef: :replace, replace: '#')
    end
    master_row_new

  end

  def convert_row(child_row)
    master_row = CSV::Row.new(@headers, [])
    master_row['Candidate Source'] = child_row['Recruiter']
    master_row['First Name'] = child_row['First Name']
    master_row['Last Name'] = child_row['Last Name']
    master_row['Email'] = child_row['E-mail Address']
    master_row['Employer Organization Name 1'] = child_row['Company']
    master_row['Employer 1 Title'] = child_row['Job Title']
    master_row['Account Name'] = 'Candidates'#.encode('windows-1252')
    master_row
  end

  def collect_emails(file)
    emails = []
    CSV.foreach(file, headers: true) do |row|
      emails << row['E-mail Address']
    end
    emails
  end
end

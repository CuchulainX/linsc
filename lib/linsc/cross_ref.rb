require './linsc/csv_handlers'

class CrossRef
  include CSVHandlers

  def initialize(input_dir, lin, sf)
    @input_dir = input_dir
    @lin_input = lin
    @sf_input = sf
    @output_file = "#{@input_dir}crossref3.csv"
    @headers = get_headers(sf)
    create_file(@output_file)
    cross_ref
  end

  def cross_ref
    sf_data = CSV.read(@sf_input, headers: true)
    sf_data = sf_data.sort do |x, y|
      a = x['Email']
      b = y['Email']
      puts "{#{a} <=> #{b}}"
      puts "{#{a.class} <=> #{b.class}}"
      puts "#{a <=> b}"
      a && b ? a <=> b : a ? -1 : 1
    end
    sf_data.first(10).each do |x| puts x['Email'] end
    sf_emails = sf_data.collect {|row| row['Email']&.downcase}
    i = 0
    q = 0
    g = 0
    CSV.foreach(@lin_input, headers: true, encoding: 'windows-1252') do |lin_row|
      i += 1
      puts "lin row: #{i}"
      lin_email = lin_row['E-mail Address']&.downcase
      if lin_email&.include?('@')
        sf_match = sf_emails.bsearch_index do |sf_email|
           lin_email && sf_email ? lin_email <=> sf_email : lin_email ? -1 : 1
        end
        if !sf_match
          sf_match = sf_data.find_index do |sf_row|
            sf_row_emails = [sf_row['Email 2']&.downcase, sf_row['Email 3']&.downcase]
            sf_row_emails.include?(lin_email)
          end
          q += 1 if sf_match
        else
          g += 1
        end
        if sf_match
          append_to_csv(@output_file, splice_rows(sf_data[sf_match], lin_row))
        else
          append_to_csv(@output_file, convert_row(lin_row))
        end
      else
        puts "missing email"
      end
    end
    puts "#{g} emails in field 1, #{q} in 2 or 3"
  end

  def splice_rows(sf_row, lin_row)
    sf_row['Candidate Source'] = lin_row['Recruiter']
    sf_row['First Name'] = lin_row['First Name'] if lin_row['First Name']
    sf_row['Last Name'] = lin_row['Last Name'] if lin_row['Last Name']
    sf_row['Employer Organization Name 1'] = lin_row['Company'] if lin_row['Company']
    sf_row['Employer 1 Title'] = lin_row['Job Title'] if lin_row['Job Title']
    sf_row_ansi = CSV::Row.new(@headers, [])
    sf_row.each do |key, value|
      sf_row_ansi[key] = value&.encode('windows-1252', invalid: :replace, undef: :replace, replace: '#')
    end
    sf_row_ansi

  end

  def convert_row(lin_row)
    sf_row = CSV::Row.new(@headers, [])
    sf_row['Candidate Source'] = lin_row['Recruiter']
    sf_row['First Name'] = lin_row['First Name']
    sf_row['Last Name'] = lin_row['Last Name']
    sf_row['Email'] = lin_row['E-mail Address']
    sf_row['Employer Organization Name 1'] = lin_row['Company']
    sf_row['Employer 1 Title'] = lin_row['Job Title']
    sf_row['Account Name'] = 'Candidates'.encode('windows-1252')
    sf_row
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

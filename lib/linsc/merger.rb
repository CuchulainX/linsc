require_relative 'csv_handlers'


class Merger
  include CSVHandlers

  def initialize(input_dir, output_path, mapping = nil)
    @input_dir, @output_path, @mapping = input_dir, output_path, mapping
    recruiter_file = Pathname.new(File.dirname __dir__).realdirpath + '../data/recruiters.txt'
    @recruiters = recruiter_file.read.split(",").collect{|r| r.strip}
    unless @recruiters && @recruiters.length > 0
      puts "recruiters.txt is empty! refer to the docs for instructions on filling it"
      exit
    end
    @lin_files = @input_dir.children.select{|fn| fn.basename.to_s.match(/^LIN.+\.csv/)}
    if mapping
      @headers = mapping.values
    else
      @headers = get_headers(@lin_files.first)
    end
    if File.exist?(@output_path)
      File.delete(@output_path)
    end
    create_file(@output_path)
  end

  def construct_emails_hash
    emails = {}
    @lin_files.each do |pn|
      lin_file = pn.to_s
      recruiter_name = pn.basename.to_s.match(/LIN[^.]+/)[0]
      puts "merging #{recruiter_name}"
      clean_file = File.read(lin_file, encoding: 'windows-1252').strip
      CSV.parse(clean_file, headers: true, encoding: 'windows-1252') do |row|
        row["Recruiter"] = recruiter_name
        email = row['E-mail Address'].downcase if row['E-mail Address']
        if emails.has_key?(email)
          emails[email] << row
        else
          emails[email] = [row]
        end
      end
    end
    emails
  end

  def merge
    emails = construct_emails_hash
    i = 0
    j = emails.length
    emails.each do |ek, ev|
      i += 1
      puts "merging - row #{i}/#{j}"
      correct_row = ev.find do |row|
        row['Recruiter'] == @recruiters.find do |rec|
           ev.collect {|row| row['Recruiter']}.include?(rec)
        end
      end
      if @mapping
        output_row = CSV::Row.new(@headers, [])
        correct_row.each do |key, value|
          if @mapping[key]
            output_row[@mapping[key]] = value.encode('utf-8', invalid: :replace, undef: :replace, replace: '?') if value
          end
        end
        output_row['Email'] = output_row['Email'].downcase if output_row['Email']
      else
        output_row = create_row(correct_row, @headers, 'utf-8')
      end
      append_to_csv(@output_path, output_row)
    end
    @output_path
  end
end

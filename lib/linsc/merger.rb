require './linsc/csv_handlers'


class Merger
  include CSVHandlers

  def initialize(input_dir)
    @input_dir = input_dir
    @output_file = "#{@input_dir}merged.csv"
    @recruiters = File.read('./../data/recruiters.txt').split(",").collect{|r| r.strip}
    @headers = ["First Name", "Last Name", "E-mail Address", "Recruiter", "Company", "Job Title"]
  end

  def construct_emails_hash
    emails = {}
    Dir.glob("#{@input_dir}LIN*.csv") do |lin_file|
      recruiter_name = lin_file.match(/LIN[^.]+/)[0]
      puts "parsing #{recruiter_name}"
      clean_file = File.read(lin_file, encoding: 'windows-1252').strip
      CSV.parse(clean_file, headers: true, encoding: 'windows-1252') do |row|
        row["Recruiter"] = recruiter_name
        email = row['E-mail Address']&.downcase
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
    create_file(@output_file)
    i = 0
    j = emails.length
    emails.each do |ek, ev|
      i += 1
      puts "row #{i}/#{j}"
      correct_row = ev.find do |row|
        row['Recruiter'] == @recruiters.find do |rec|
           ev.collect {|row| row['Recruiter']}.include?(rec)
        end
      end
      output = create_row(correct_row, @headers)
      append_to_csv(@output_file, output)
    end
    @output_file
  end
end

class Merger

  def initialize(input_dir)
    @input_dir = input_dir
    @recruiters = File.read('./../data/recruiters.txt').split(",").collect{|r| r.strip}
    @headers = ["First Name",	"Last Name",	"Company",
      "Job Title",	"E-mail Address",	"Recruiter"]
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
    create_file("#{@input_dir}merged.csv")
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
      append_to_csv("#{@input_dir}merged.csv", output)
    end
  end

  def create_row(row, headers)
    values = []
    headers.each do |header|
      values << row[header]
    end
    CSV::Row.new(headers, values)
  end

  def append_to_csv(file, row)
    f = CSV.open(file, "a+", headers: row.headers)
    f << row
    f.close
  end

  def create_file(f)
    unless File.exist?(f)
      FileUtils.touch(f)
      csv = CSV.open(f, "w+")
      csv << @headers
      csv.close
    end
  end
end

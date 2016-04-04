module CSVHandlers
  def create_row(row, headers, encoding = nil)
    values = []
    headers.each do |header|
      if encoding
        values << row[header]&.encode(encoding)
      else
        values << row[header]
      end
    end
    CSV::Row.new(headers, values)
  end

  def append_to_csv(file, row)
    tries = 3
    begin
      f = CSV.open(file, "a+", headers: row.headers, force_quotes: true)
      f << row
      f.close
    rescue
      tries -= 1
      if tries > 0
        retry
      else
        puts "Unable to write to file #{file}"
        puts "Make sure the file exists and is not open in any other programs and try again. If that does not work try restarting your computer, or restarting the project with the -r flag."
        exit
      end
    end
  end

  def create_file(f)
    unless File.exist?(f)
      FileUtils.touch(f)
      csv = CSV.open(f, "w+")
      csv << @headers.collect {|x| x&.encode('utf-8')}
      csv.close
    end
  end

  def create_file_with_headers(f, headers)
    unless File.exist?(f)
      FileUtils.touch(f)
      csv = CSV.open(f, "w+")
      csv << headers.collect {|x| x&.encode('utf-8')}
      csv.close
    end
  end

  def get_headers(file)
    CSV.open(file, headers: true, return_headers: true).shift.headers
  end
end

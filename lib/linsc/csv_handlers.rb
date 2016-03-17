module CSVHandlers
  def create_row(row, headers)
    values = []
    headers.each do |header|
      values << row[header]
    end
    CSV::Row.new(headers, values)
  end

  def append_to_csv(file, row)
    f = CSV.open(file, "a+", headers: row.headers, force_quotes: true)
    f << row
    f.close
  end

  def create_file(f)
    unless File.exist?(f)
      FileUtils.touch(f)
      csv = CSV.open(f, "w+")
      csv << @headers.collect {|x| x&.encode('utf-8')}
      csv.close
    end
  end

  def get_headers(file)
    CSV.open(file, headers: true, return_headers: true).shift.headers
  end
end

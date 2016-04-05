require_relative 'csv_handlers'
require 'securerandom'

class CrossRef
  include CSVHandlers
  include SecureRandom

  def initialize(input_dir:, child_path:, master_path:, output_path:,
                 master_lookup_field: 'Email', child_lookup_field: 'Email',
                 master_secondary_lookups: ['Email 2', 'Email 3'],
                 static_values: {'Account Name' => 'Candidates'}, options:)
    @input_dir, @child_path, @master_path, @output_path, @options =
      input_dir, child_path, master_path, output_path, options
    @master_lookup_field, @child_lookup_field, @master_secondary_lookups, @static_values =
      master_lookup_field, child_lookup_field, master_secondary_lookups, static_values
    @headers = get_headers(@master_path)
    child_lookup_field == 'Email' ? @email_key = true : @email_key = false
    @child_headers = get_headers(@child_path)
    @child_headers.each do |child_header|
      unless @headers.include?(child_header)
        @headers << child_header
      end
    end
    @static_values.each do |static_key, static_value|
      unless @headers.include?(static_key)
        @headers << static_key
      end
    end if @static_values
    @child_length = CSV.read(@child_path).length - 1
    if File.exist?(@output_path)
      File.delete(@output_path)
    end
    create_file(@output_path)
    cross_ref
  end

  def cross_ref
    master_data = CSV.read(@master_path, headers: true)
    puts "sorting lookup values"
    master_data = master_data.sort do |x, y|
      a = x[@master_lookup_field]
      b = y[@master_lookup_field]
      a && b ? a <=> b : a ? -1 : 1
    end
    master_lookup_values = master_data.collect {|row| row[@master_lookup_field] && row[@master_lookup_field].downcase}
    i = 0
    CSV.foreach(@child_path, headers: true, encoding: 'utf-8') do |child_row|
      i += 1
      puts "email lookup - row: #{i}/#{@child_length}"
      child_lookup_value = child_row[@child_lookup_field].downcase if child_row[@child_lookup_field]
      if (child_lookup_value && child_lookup_value.include?('@')) || !@email_key ## generalize this
        match_index = master_lookup_values.bsearch_index do |master_lookup_value|
           child_lookup_value && master_lookup_value ?
                child_lookup_value <=> master_lookup_value : child_lookup_value ? -1 : 1
        end
        if !match_index
          match_index = master_data.find_index do |master_row|
            master_secondary_lookups = @master_secondary_lookups.collect{|x| x && x.downcase}
            master_secondary_lookups.include?(child_lookup_value)
          end
        end
        if match_index
          if @options[:update]
            append_to_csv(@output_path, splice_rows(master_data[match_index], child_row))
          end
        else
          if @options[:insert]
            append_to_csv(@output_path, convert_row(child_row))
          end
        end
      else
        puts "missing lookup value"
      end
    end
  end

  def splice_rows(master_row, child_row)
    unless master_row['LIN ID'] && master_row['LIN ID'].strip.length > 20
      master_row['LIN ID'] = SecureRandom.hex(16)
    end

    child_row.each do |child_key, child_value|
      if child_value && child_value.strip.length > 0
        if master_row.has_key?(child_key)
          master_row[child_key] = child_value
        else
          master_row << [child_key, child_value]
        end
      else
        unless master_row.has_key?(child_key)
          master_row << [child_key, child_value]
        end
      end
    end
    master_row_new = CSV::Row.new(@headers, [])
    master_row.each do |key, value|
      master_row_new[key] = value.encode('utf-8', invalid: :replace, undef: :replace, replace: '#') if value
    end
    master_row_new
  end

  def convert_row(child_row)
    master_row = CSV::Row.new(@headers, [])
    master_row['LIN ID'] = SecureRandom.hex(16)
    child_row.each do |child_key, child_value|
      master_row[child_key] = child_value if master_row.has_key?(child_key)
    end
    @static_values.each do |static_key, static_value|
      master_row[static_key] = static_value if master_row.has_key?(static_key)
    end
    master_row
  end
end

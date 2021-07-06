require 'ofx_reader'
require 'ofxparser'
require 'csv'

ofx_text = File.open('./file.ofx').read

def parse_datetime(date)
  if /\A\s*
      (\d{4})(\d{2})(\d{2})           # YYYYMMDD            1,2,3
      (?:(\d{2})(\d{2})(\d{2}))?      # HHMMSS  - optional  4,5,6
      (?:\.(\d{3}))?                  # .XXX    - optional  7
      (?:\[([-+]?[.\d]+):\w{3}\])?  # [-n:TZ] - optional  8,9
      \s*\z/ix =~ date
    year = Regexp.last_match(1).to_i
    mon = Regexp.last_match(2).to_i
    day = Regexp.last_match(3).to_i
    hour = Regexp.last_match(4).to_i
    min = Regexp.last_match(5).to_i
    sec = Regexp.last_match(6).to_i
    # DateTime does not support usecs.
    # usec = 0
    # usec = $7.to_f * 1000000 if $7
    off = Rational(Regexp.last_match(8).to_i, 24) # offset as a fraction of day. :|
    DateTime.civil(year, mon, day, hour, min, sec, off)
  end
end

ofx = OFXReader.call(ofx_text)

first_line = ofx.transactions.first.keys.map { |k| k.to_s }
transactions = ofx.transactions

csv_string = CSV.generate do |csv|
  #   csv << ofx.account.keys
  #   csv << ofx.account.values
  csv << first_line
  transactions.each do |t|
    date = parse_datetime(t[:dtposted])

    csv << [t[:trntype], date, t[:trnamt], t[:fitid], t[:refnum], t[:memo]]
  end
end

File.write('ofx_converted.csv', csv_string)

print csv_string

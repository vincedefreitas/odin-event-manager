require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'


def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    legislators = civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')
  
  filename = "output/thanks_#{id}.html"
  
  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def clean_phone_numbers(number)
  new_number = number.gsub(/[^0-9A-Za-z]/, '')
  if new_number.length < 10
    "Bad Number"
  elsif new_number.length > 10 && new_number[0] == '1'
    "#{new_number[1..3]}-#{new_number[4..6]}-#{new_number[7..10]}"
  else
    "#{new_number[0..2]}-#{new_number[3..5]}-#{new_number[6..9]}"
  end
end

def frequency_count(arr)
  hash = Hash.new(0)
  arr.each { |a| hash[a] += 1 }
  hash.max_by { |k, v| v }
end


puts 'Event Manager Initialized!'

contents = CSV.open(
  'event_attendees.csv', 
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
hours = []
days_of_week = []
num_to_day = {
  0 => "Sunday",
  1 => "Monday",
  2 => "Tuesday",
  3 => "Wednesday",
  4 => "Thursday",
  5 => "Friday",
  6 => "Saturday",
}

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  phone_numbers = clean_phone_numbers(row[:homephone])
  legislators = legislators_by_zipcode(zipcode)
  date = row[:regdate]
  formatted_date = DateTime.strptime(date, "%m/%d/%y %H:%M")
  hours.push(formatted_date.hour)
  days_of_week.push(formatted_date.wday)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)
  puts phone_numbers
  
end

puts "Most frequent hour of the day is: #{frequency_count(hours)[0]}"
puts "Most frequent day of the week is: #{num_to_day[frequency_count(days_of_week)[0]]}"

